package com.example.orders.model;

import java.io.Serializable;
import java.time.Instant;

public class Order implements Serializable {
    private String orderId;
    private String customerName;
    private String item;
    private double amount;
    private Instant createdAt;

    public Order() {}

    public Order(String orderId, String customerName, String item, double amount) {
        this.orderId = orderId;
        this.customerName = customerName;
        this.item = item;
        this.amount = amount;
        this.createdAt = Instant.now();
    }

    public String getOrderId() { return orderId; }
    public void setOrderId(String orderId) { this.orderId = orderId; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String customerName) { this.customerName = customerName; }

    public String getItem() { return item; }
    public void setItem(String item) { this.item = item; }

    public double getAmount() { return amount; }
    public void setAmount(double amount) { this.amount = amount; }

    public Instant getCreatedAt() { return createdAt; }
    public void setCreatedAt(Instant createdAt) { this.createdAt = createdAt; }
}