package com.example.orders.service;

import com.example.orders.model.Order;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class OrderFileStorageService {

    @Value("${app.storage.path:/var/data}")
    private String storagePath;

    private final ObjectMapper objectMapper = new ObjectMapper();
    private Path rootStorageDir;

    @PostConstruct
    public void init() {
        this.rootStorageDir = Paths.get(storagePath);
        try {
            if (!Files.exists(rootStorageDir)) {
                Files.createDirectories(rootStorageDir);
            }
        } catch (IOException e) {
            throw new RuntimeException("Could not create PVC data folder at " + storagePath, e);
        }
    }

    public Order saveOrder(Order order) throws IOException {
        if (order.getOrderId() == null || order.getOrderId().isBlank()) {
            order.setOrderId("ORD-" + UUID.randomUUID().toString().substring(0, 8));
        }
        order.setCreatedAt(java.time.Instant.now());

        Path filePath = rootStorageDir.resolve(order.getOrderId() + ".json");
        objectMapper.writeValue(filePath.toFile(), order);
        return order;
    }

    public Optional<Order> getOrderById(String orderId) {
        Path filePath = rootStorageDir.resolve(orderId + ".json");
        if (!Files.exists(filePath)) {
            return Optional.empty();
        }
        try {
            Order order = objectMapper.readValue(filePath.toFile(), Order.class);
            return Optional.of(order);
        } catch (IOException e) {
            return Optional.empty();
        }
    }

    public List<Order> getAllOrders() {
        List<Order> orders = new ArrayList<>();
        File folder = rootStorageDir.toFile();
        File[] files = folder.listFiles((dir, name) -> name.endsWith(".json"));

        if (files != null) {
            for (File file : files) {
                try {
                    orders.add(objectMapper.readValue(file, Order.class));
                } catch (IOException ignored) {}
            }
        }
        return orders;
    }
}