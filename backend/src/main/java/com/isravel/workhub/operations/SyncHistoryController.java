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
        SyncHistoryEntity syncHistory = syncHistoryService.startSync();
        
        final Long historyId = syncHistory.getId();
        new Thread(() -> {
            try {
                ProcessBuilder pb = new ProcessBuilder(
                    "/Users/richan_27/Desktop/Isravel-WorkHub/attendance-sync/.venv/bin/python",
                    "/Users/richan_27/Desktop/Isravel-WorkHub/attendance-sync/attendance_sync.py",
                    "--once",
                    "--history-id",
                    String.valueOf(historyId)
                );
                pb.directory(new java.io.File("/Users/richan_27/Desktop/Isravel-WorkHub/attendance-sync"));
                pb.environment().putAll(System.getenv());
                
                Process p = pb.start();
                int exitCode = p.waitFor();
                if (exitCode != 0) {
                    System.err.println("Manual sync python process failed with exit code: " + exitCode);
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }).start();
        
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
