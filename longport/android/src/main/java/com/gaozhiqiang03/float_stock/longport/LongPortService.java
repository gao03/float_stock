package com.gaozhiqiang03.float_stock.longport;

import android.os.Build;

import androidx.annotation.RequiresApi;

import com.longbridge.ConfigBuilder;
import com.longbridge.OpenApiException;
import com.longbridge.quote.PushQuote;
import com.longbridge.quote.QuoteContext;
import com.longbridge.quote.QuoteHandler;
import com.longbridge.quote.SecurityQuote;
import com.longbridge.quote.SecurityStaticInfo;
import com.longbridge.quote.WatchListGroup;
import com.longbridge.trade.OrderChangedHandler;
import com.longbridge.trade.PushOrderChanged;
import com.longbridge.trade.StockPositionsResponse;
import com.longbridge.trade.TradeContext;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.function.BiConsumer;
import java.util.function.Consumer;

@RequiresApi(api = Build.VERSION_CODES.N)
public class LongPortService {
    private QuoteContext quoteContext;
    private TradeContext tradeContext;

    private final QuoteHandler onQuote;
    private final OrderChangedHandler onTrade;

    public LongPortService(QuoteHandler onQuote, OrderChangedHandler onTrade) {
        this.onQuote = onQuote;
        this.onTrade = onTrade;
    }

    public void init(ConfigBuilder cfg) throws Exception {
        quoteContext = get(QuoteContext.create(cfg.build()));
        tradeContext = get(TradeContext.create(cfg.build()));
        if (onQuote != null) {
            quoteContext.setOnQuote(onQuote);
        }
        if (onTrade != null) {
            tradeContext.setOnOrderChange(onTrade);
        }
    }

    public SecurityQuote[] getQuotes(List<String> symbols) throws OpenApiException {
        checkInit();
        return get(quoteContext.getQuote(symbols.toArray(new String[0])));
    }

    public void subscribes(List<String> symbols) throws OpenApiException {
        checkInit();
        get(quoteContext.subscribe(symbols.toArray(new String[0]), 15, true));
    }

    public WatchListGroup[] getWatchList() throws OpenApiException {
        checkInit();
        return get(quoteContext.getWatchList());
    }

    public StockPositionsResponse getStockPositions() throws OpenApiException {
        checkInit();
        return get(tradeContext.getStockPositions(null));
    }

    public SecurityStaticInfo[] getStaticInfo(List<String> symbols) throws OpenApiException {
        checkInit();
        return get(quoteContext.getStaticInfo(symbols.toArray(new String[0])));
    }

    public void close() {
        checkInit();
        try {
            quoteContext.close();
            tradeContext.close();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private <T> T get(CompletableFuture<T> future) {
        try {
            return future.get();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }


    private void checkInit() {
        if (quoteContext == null) {
            throw new RuntimeException("未初始化");
        }
    }

}
