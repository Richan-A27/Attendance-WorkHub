package com.isravel.workhub.sync;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.List;
import java.util.Map;

@Service
public class SupabaseSyncService {

    @Autowired
    private SyncQueueRepository syncQueueRepository;

    @Autowired
    private JdbcTemplate jdbcTemplate;

    @Value("${supabase.url:}")
    private String supabaseUrl;

    @Value("${supabase.service-role-key:}")
    private String supabaseKey;

    private final RestTemplate restTemplate = new RestTemplate();

    @Scheduled(fixedDelay = 5000)
    public void processSyncQueue() {
        if (supabaseUrl == null || supabaseUrl.isEmpty() || supabaseKey == null || supabaseKey.isEmpty()) {
            return; // Not configured yet
        }

        List<SyncQueue> pendingTasks = syncQueueRepository.findByStatus("PENDING");
        if (pendingTasks.isEmpty()) {
            return;
        }

        for (SyncQueue task : pendingTasks) {
            try {
                task.setStatus("PROCESSING");
                syncQueueRepository.save(task);

                boolean success = syncRecordToSupabase(task);
                
                if (success) {
                    task.setStatus("SYNCED");
                } else {
                    task.setStatus("FAILED");
                    task.setErrorMessage("Unknown failure from Supabase");
                }
            } catch (Exception e) {
                task.setStatus("FAILED");
                task.setErrorMessage(e.getMessage());
            } finally {
                syncQueueRepository.save(task);
            }
        }
    }

    private boolean syncRecordToSupabase(SyncQueue task) {
        String url = supabaseUrl + "/rest/v1/" + task.getTableName();
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        headers.set("apikey", supabaseKey);
        headers.set("Authorization", "Bearer " + supabaseKey);

        if ("DELETE".equals(task.getAction())) {
            url += "?id=eq." + task.getRecordId();
            HttpEntity<String> entity = new HttpEntity<>(headers);
            restTemplate.exchange(url, HttpMethod.DELETE, entity, String.class);
            return true;
        }

        // For INSERT and UPDATE, fetch the latest row state
        String sql = "SELECT * FROM " + task.getTableName() + " WHERE id = ?";
        List<Map<String, Object>> rows = jdbcTemplate.queryForList(sql, Long.parseLong(task.getRecordId()));
        
        if (rows.isEmpty()) {
            // Record was deleted locally before it could be synced, ignore or handle?
            return true;
        }
        
        Map<String, Object> payload = rows.get(0);
        HttpEntity<Map<String, Object>> entity = new HttpEntity<>(payload, headers);

        if ("INSERT".equals(task.getAction())) {
            // Supabase uses POST for inserts. Prefer=resolution=merge-duplicates is good for upsert.
            headers.set("Prefer", "resolution=merge-duplicates");
            restTemplate.exchange(url, HttpMethod.POST, entity, String.class);
        } else if ("UPDATE".equals(task.getAction())) {
            url += "?id=eq." + task.getRecordId();
            restTemplate.exchange(url, HttpMethod.PATCH, entity, String.class);
        }
        
        return true;
    }
}
