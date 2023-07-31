package com.gaozhiqiang03.float_stock.longport;

import android.content.Context;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.longbridge.ConfigBuilder;
import com.longbridge.quote.PushQuote;
import com.longbridge.quote.QuoteHandler;

import org.apache.commons.lang3.exception.ExceptionUtils;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/**
 * LongportPlugin
 */
@RequiresApi(api = Build.VERSION_CODES.N)
public class LongportPlugin implements FlutterPlugin, MethodCallHandler, QuoteHandler {
    private final LongPortService ls = new LongPortService(this::onQuote);
    private static final String CHANNEL = "com.gaozhiqiang03.float_stock/longport";
    private MethodChannel methodChannel;
    private final Map<String, MethodConfig> handlers = new HashMap<>();

    {
        handlers.put("init", new MethodConfig<>(ls::init, ConfigBuilder.class));
        handlers.put("getQuote", new MethodConfig<>(ls::getQuote, String.class));
        handlers.put("getQuotes", new MethodConfig<>(ls::getQuotes, new TypeToken<List<String>>() {
        }.getType()));
        handlers.put("subscribe", new MethodConfig<>(ls::subscribe, String.class));
        handlers.put("subscribes", new MethodConfig<>(ls::subscribes, new TypeToken<List<String>>() {
        }.getType()));
        handlers.put("getWatchList", new MethodConfig<>(ls::getWatchList));
        handlers.put("getStockPositions", new MethodConfig<>(ls::getStockPositions));
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        System.out.println("onAttachedToEngine begin");
        methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.gaozhiqiang03.float_stock/longport");
        methodChannel.setMethodCallHandler(this);
        System.out.println("onAttachedToEngine end");
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
    }


    public void onQuote(String symbol, PushQuote event) {
        Map<String, Object> args = new HashMap<>();
        args.put("symbol", symbol);
        args.put("event", event);
        System.out.println("onQuote: " + new Gson().toJson(args));
        new Handler(Looper.getMainLooper()).post(() -> {
            methodChannel.invokeMethod("onQuote", new Gson().toJson(args));
        });
    }

    /**
     * @noinspection rawtypes
     */
    @SuppressWarnings("unchecked")
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        MethodConfig method = handlers.get(call.method);
        System.out.println("1 method = " + call.method);
        System.out.println("2 arguments = " + call.arguments);
        if (method == null) {
            return;
        }

        try {
            String argStr = call.arguments.toString();
            Object arg = null;
            if (method.argumentClass != null) {
                arg = new Gson().fromJson(argStr, method.argumentClass);
            } else if (method.argumentType != null) {
                arg = new Gson().fromJson(argStr, method.argumentType);
            }
            System.out.println("arg = " + arg);

            Object response = null;
            if (method.supplier != null) {
                response = method.supplier.get();
            } else if (method.consumer != null) {
                method.consumer.accept(arg);
            } else if (method.function != null) {
                response = method.function.apply(arg);
            }
            System.out.println("response:" + new Gson().toJson(response));
            result.success(new Gson().toJson(response));
            if ("init".equals(call.method)) {
                ls.onQuote(this::onQuote);
            }
        } catch (Exception e) {
            System.out.println(ExceptionUtils.getStackTrace(e));
            result.error("-1", e.getMessage(), ExceptionUtils.getStackTrace(e));
        }
    }
}
