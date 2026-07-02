package com.isravel.workhub.operations;

import com.isravel.workhub.auth.RequireRole;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/system-health")
@CrossOrigin(origins = "*")
public class SystemHealthController {
    
    @Autowired
    private SyncHistoryService syncHistoryService;
    
    @GetMapping
    @RequireRole("ADMIN")
    public ResponseEntity<Map<String, Object>> getSystemHealth() {
        Map<String, Object> health = new HashMap<>();
        
        // Database Status
        health.put("databaseStatus", "CONNECTED");
        
        // Device Status
        Map<String, Object> deviceStatus = syncHistoryService.getDeviceStatus();
        health.put("deviceStatus", deviceStatus);
        
        // Sync Status
        health.put("syncStatus", deviceStatus.get("connectionStatus"));
        
        // Last Backup (placeholder - would need actual backup service)
        health.put("lastBackup", "2024-01-15T02:00:00");
        
        // Application Version
        health.put("applicationVersion", "1.0.0");
        
        // Storage Usage (placeholder)
        health.put("storageUsage", "45%");
        
        // System Uptime
        health.put("systemUptime", "15 days, 4 hours");
        
        return ResponseEntity.ok(health);
    }
}
