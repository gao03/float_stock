package com.gaozhiqiang03.float_stock.longport;

import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.longbridge.ConfigBuilder;
import com.longbridge.quote.PushQuote;
import com.longbridge.quote.QuoteHandler;
import com.longbridge.trade.OrderChangedHandler;
import com.longbridge.trade.PushOrderChanged;

import org.apache.commons.lang3.exception.ExceptionUtils;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;

/**
 * LongportPlugin
 */
@RequiresApi(api = Build.VERSION_CODES.N)
public class LongportPlugin implements FlutterPlugin, MethodCallHandler, QuoteHandler, OrderChangedHandler {
    private final LongPortService ls = new LongPortService(this, this);
    private static final String CHANNEL = "com.gaozhiqiang03.float_stock/longport";
    private MethodChannel methodChannel;
    private final Map<String, MethodConfig> handlers = new HashMap<>();

    {
        handlers.put("init", new MethodConfig<>(ls::init, ConfigBuilder.class));
        handlers.put("getStaticInfo", new MethodConfig<>(ls::getStaticInfo, new TypeToken<List<String>>() {
        }.getType()));
        handlers.put("getQuotes", new MethodConfig<>(ls::getQuotes, new TypeToken<List<String>>() {
        }.getType()));
        handlers.put("subscribes", new MethodConfig<>(ls::subscribes, new TypeToken<List<String>>() {
        }.getType()));
        handlers.put("getWatchList", new MethodConfig<>(ls::getWatchList));
        handlers.put("getStockPositions", new MethodConfig<>(ls::getStockPositions));
    }

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
        methodChannel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "com.gaozhiqiang03.float_stock/longport");
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
    }


    public void onQuote(String symbol, PushQuote event) {
        Map<String, Object> args = new HashMap<>();
        args.put("symbol", symbol);
        args.put("event", event);
        new Handler(Looper.getMainLooper()).post(() -> {
            methodChannel.invokeMethod("onQuote", new Gson().toJson(args));
        });
    }

    @Override
    public void onOrderChanged(PushOrderChanged event) {
        new Handler(Looper.getMainLooper()).post(() -> {
            methodChannel.invokeMethod("onTrade", new Gson().toJson(event));
        });
    }

    /**
     * @noinspection rawtypes
     */
    @SuppressWarnings("unchecked")
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        MethodConfig method = handlers.get(call.method);
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

            Object response = null;
            if (method.supplier != null) {
                response = method.supplier.get();
            } else if (method.consumer != null) {
                method.consumer.accept(arg);
            } else if (method.function != null) {
                response = method.function.apply(arg);
            }
            result.success(new Gson().toJson(response));
        } catch (Exception e) {
            System.out.println("call.method: " + ExceptionUtils.getStackTrace(e));
            result.error("-1", e.getMessage(), ExceptionUtils.getStackTrace(e));
        } catch (Throwable t) {
            Log.d("longport", "onMethodCall: " + ExceptionUtils.getStackTrace(t));
        }
    }
}
