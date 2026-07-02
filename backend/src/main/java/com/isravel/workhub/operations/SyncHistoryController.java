package com.isravel.workhub.operations;

import com.isravel.workhub.auth.RequireRole;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/operations")
@CrossOrigin(origins = "*")
public class SyncHistoryController {
    
    @Autowired
    private SyncHistoryService syncHistoryService;
    
    @GetMapping("/device-status")
    @RequireRole("ADMIN")
    public ResponseEntity<Map<String, Object>> getDeviceStatus() {
        return ResponseEntity.ok(syncHistoryService.getDeviceStatus());
    }
    
    @GetMapping("/sync-history")
    @RequireRole("ADMIN")
    public ResponseEntity<List<SyncHistoryEntity>> getSyncHistory(
            @RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(syncHistoryService.getRecentSyncHistory(limit));
    }
    
    @GetMapping("/sync-statistics")
    @RequireRole("ADMIN")
    public ResponseEntity<Map<String, Object>> getSyncStatistics() {
        return ResponseEntity.ok(syncHistoryService.getSyncStatistics());
    }
    
    @PostMapping("/manual-sync")
    @RequireRole("ADMIN")
    public ResponseEntity<Map<String, Object>> triggerManualSync() {
        // This would trigger the Python sync service
        // For now, we'll create a sync history entry
        SyncHistoryEntity syncHistory = syncHistoryService.startSync();
        
        Map<String, Object> response = new java.util.HashMap<>();
        response.put("message", "Manual sync triggered");
        response.put("syncHistoryId", syncHistory.getId());
        response.put("status", "IN_PROGRESS");
        
        return ResponseEntity.ok(response);
    }
    
    @GetMapping("/diagnostics")
    @RequireRole("ADMIN")
    public ResponseEntity<Map<String, Object>> getDiagnostics() {
        Map<String, Object> diagnostics = new java.util.HashMap<>();
        
        // Device reachability
        Map<String, Object> deviceStatus = syncHistoryService.getDeviceStatus();
        diagnostics.put("deviceReachable", "ONLINE".equals(deviceStatus.get("connectionStatus")));
        diagnostics.put("deviceStatus", deviceStatus);
        
        // Database reachability (if we're here, it's reachable)
        diagnostics.put("databaseReachable", true);
        
        // Last sync status
        SyncHistoryEntity lastSync = syncHistoryService.getLastSync();
        diagnostics.put("lastSyncStatus", lastSync != null ? lastSync.getStatus() : "NEVER_SYNCED");
        
        // Sync duration
        if (lastSync != null && lastSync.getSyncEndTime() != null) {
            long duration = java.time.Duration.between(lastSync.getSyncStartTime(), lastSync.getSyncEndTime()).toSeconds();
            diagnostics.put("lastSyncDuration", duration + " seconds");
        } else {
            diagnostics.put("lastSyncDuration", "N/A");
        }
        
        // Error history (recent failures)
        List<SyncHistoryEntity> recentHistory = syncHistoryService.getRecentSyncHistory(5);
        long recentFailures = recentHistory.stream().filter(s -> "FAILURE".equals(s.getStatus())).count();
        diagnostics.put("recentFailures", recentFailures);
        
        return ResponseEntity.ok(diagnostics);
    }
}
