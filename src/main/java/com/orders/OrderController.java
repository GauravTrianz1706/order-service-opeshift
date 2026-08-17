package com.example.orders.controller;

import com.example.orders.model.Order;
import com.example.orders.service.OrderFileStorageService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/orders")
public class OrderController {

    private final OrderFileStorageService storageService;

    public OrderController(OrderFileStorageService storageService) {
        this.storageService = storageService;
    }

    @PostMapping
    public ResponseEntity<?> createOrder(@RequestBody Order order) {
        try {
            Order created = storageService.saveOrder(order);
            return ResponseEntity.status(HttpStatus.CREATED).body(created);
        } catch (IOException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR)
                    .body(Map.of("error", "PVC file write error: " + e.getMessage()));
        }
    }

    @GetMapping("/{orderId}")
    public ResponseEntity<?> getOrder(@PathVariable String orderId) {
        return storageService.getOrderById(orderId)
                .<ResponseEntity<?>>map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.status(HttpStatus.NOT_FOUND)
                        .body(Map.of("message", "Order not found with ID: " + orderId)));
    }

    @GetMapping
    public ResponseEntity<List<Order>> listAllOrders() {
        return ResponseEntity.ok(storageService.getAllOrders());
    }
}
