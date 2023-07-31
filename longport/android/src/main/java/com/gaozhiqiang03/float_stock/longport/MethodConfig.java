package com.gaozhiqiang03.float_stock.longport;

import java.lang.reflect.Type;
import java.util.function.Supplier;

@FunctionalInterface
interface FullSupplier<T> {
    T get() throws Exception;
}

@FunctionalInterface
interface FullFunction<T, R> {
    R apply(T var1) throws Exception;
}

@FunctionalInterface
interface FullConsumer<T> {
    void accept(T var1) throws Exception;
}


public class MethodConfig<T, R> {
    FullFunction<T, R> function;
    FullConsumer<T> consumer;

    FullSupplier<T> supplier;

    Class<T> argumentClass;
    Type argumentType;

    public MethodConfig() {
    }

    public MethodConfig(FullSupplier<T> supplier) {
        this.supplier = supplier;
    }

    public MethodConfig(FullFunction<T, R> function, Class<T> argumentClass) {
        this.function = function;
        this.argumentClass = argumentClass;
    }

    public MethodConfig(FullFunction<T, R> function, Type argumentType) {
        this.function = function;
        this.argumentType = argumentType;
    }

    public MethodConfig(FullConsumer<T> consumer, Class<T> argumentClass) {
        this.consumer = consumer;
        this.argumentClass = argumentClass;
    }

    public MethodConfig(FullConsumer<T> consumer, Type argumentType) {
        this.consumer = consumer;
        this.argumentType = argumentType;
    }
}
