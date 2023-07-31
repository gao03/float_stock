package com.gaozhiqiang03.float_stock.longport;

import android.os.Build;

import androidx.annotation.RequiresApi;

import com.longbridge.ConfigBuilder;
import com.longbridge.OpenApiException;
import com.longbridge.quote.PushQuote;
import com.longbridge.quote.QuoteContext;
import com.longbridge.quote.QuoteHandler;
import com.longbridge.quote.SecurityQuote;
import com.longbridge.quote.WatchListGroup;
import com.longbridge.trade.StockPositionsResponse;
import com.longbridge.trade.TradeContext;

import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.function.BiConsumer;

@RequiresApi(api = Build.VERSION_CODES.N)
public class LongPortService {
    private QuoteContext quoteContext;
    private TradeContext tradeContext;

    private final QuoteHandler onQuote;

    public LongPortService(QuoteHandler onQuote) {
        this.onQuote = onQuote;
    }

    public void init(ConfigBuilder cfg) throws Exception {
        quoteContext = get(QuoteContext.create(cfg.build()));
        tradeContext = get(TradeContext.create(cfg.build()));
        quoteContext.setOnQuote(onQuote);
    }

    public void onQuote(BiConsumer<String, PushQuote> consumer) {
        quoteContext.setOnQuote(consumer::accept);
    }

    public SecurityQuote getQuote(String symbol) throws OpenApiException {
        SecurityQuote[] quotes = getQuotes(List.of(symbol));
        return quotes == null || quotes.length == 0 ? null : quotes[0];
    }

    public SecurityQuote[] getQuotes(List<String> symbols) throws OpenApiException {
        checkInit();
        return get(quoteContext.getQuote(symbols.toArray(new String[0])));
    }

    public void subscribe(String symbol) throws OpenApiException {
        subscribes(List.of(symbol));
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
