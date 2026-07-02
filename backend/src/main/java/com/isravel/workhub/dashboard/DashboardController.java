package com.isravel.workhub.dashboard;

import com.isravel.workhub.auth.RequireRole;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/dashboard")
public class DashboardController {
    private final DashboardService service;

    public DashboardController(DashboardService service) {
        this.service = service;
    }

    @GetMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> getSummary() {
        return ResponseEntity.ok(new ApiResponse(true, "Dashboard summary", service.summary()));
    }

    record ApiResponse(boolean success, String message, Object data) {}
}
