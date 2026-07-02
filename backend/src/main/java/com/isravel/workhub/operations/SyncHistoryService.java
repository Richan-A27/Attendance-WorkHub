package com.isravel.workhub.operations;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Duration;
import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class SyncHistoryService {
    
    @Autowired
    private SyncHistoryRepository syncHistoryRepository;
    
    @Value("${device.ip}")
    private String deviceIp;
    
    @Value("${device.port}")
    private String devicePort;
    
    @Transactional
    public SyncHistoryEntity startSync() {
        SyncHistoryEntity syncHistory = new SyncHistoryEntity();
        syncHistory.setSyncStartTime(LocalDateTime.now());
        syncHistory.setStatus("IN_PROGRESS");
        syncHistory.setRecordsProcessed(0);
        return syncHistoryRepository.save(syncHistory);
    }
    
    @Transactional
    public SyncHistoryEntity completeSync(Long syncHistoryId, Integer recordsProcessed, String errorMessage) {
        SyncHistoryEntity syncHistory = syncHistoryRepository.findById(syncHistoryId)
                .orElseThrow(() -> new RuntimeException("Sync history not found"));
        
        syncHistory.setSyncEndTime(LocalDateTime.now());
        syncHistory.setRecordsProcessed(recordsProcessed);
        
        if (errorMessage != null) {
            syncHistory.setStatus("FAILURE");
            syncHistory.setErrorMessage(errorMessage);
        } else {
            syncHistory.setStatus("SUCCESS");
        }
        
        return syncHistoryRepository.save(syncHistory);
    }
    
    public List<SyncHistoryEntity> getRecentSyncHistory(int limit) {
        List<SyncHistoryEntity> allHistory = syncHistoryRepository.findAllByOrderBySyncStartTimeDesc();
        return allHistory.stream().limit(limit).toList();
    }
    
    public SyncHistoryEntity getLastSync() {
        return syncHistoryRepository.findTopByOrderBySyncStartTimeDesc().orElse(null);
    }
    
    public Map<String, Object> getDeviceStatus() {
        Map<String, Object> status = new HashMap<>();
        
        SyncHistoryEntity lastSync = getLastSync();
        
        if (lastSync == null) {
            status.put("deviceName", "X2008");
            status.put("deviceIp", deviceIp);
            status.put("connectionStatus", "UNKNOWN");
            status.put("lastSyncTime", null);
            status.put("lastSyncStatus", null);
        } else {
            status.put("deviceName", "X2008");
            status.put("deviceIp", deviceIp);
            
            // Determine connection status based on last sync
            if (lastSync.getStatus().equals("SUCCESS") && 
                lastSync.getSyncEndTime() != null && 
                Duration.between(lastSync.getSyncEndTime(), LocalDateTime.now()).toMinutes() < 30) {
                status.put("connectionStatus", "ONLINE");
            } else if (lastSync.getStatus().equals("FAILURE")) {
                status.put("connectionStatus", "OFFLINE");
            } else {
                status.put("connectionStatus", "OFFLINE");
            }
            
            status.put("lastSyncTime", lastSync.getSyncEndTime());
            status.put("lastSyncStatus", lastSync.getStatus());
        }
        
        return status;
    }
    
    public Map<String, Object> getSyncStatistics() {
        Map<String, Object> stats = new HashMap<>();
        stats.put("totalSyncs", syncHistoryRepository.count());
        stats.put("successfulSyncs", syncHistoryRepository.countSuccessfulSyncs());
        stats.put("failedSyncs", syncHistoryRepository.countFailedSyncs());
        stats.put("lastSync", getLastSync());
        return stats;
    }
}
