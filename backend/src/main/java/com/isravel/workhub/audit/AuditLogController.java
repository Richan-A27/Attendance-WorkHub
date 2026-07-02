package com.isravel.workhub.audit;

import com.isravel.workhub.auth.RequireRole;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/audit-logs")
@CrossOrigin(origins = "*")
public class AuditLogController {
    
    @Autowired
    private AuditLogService auditLogService;
    
    @PostMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<AuditLogEntity> createAuditLog(@RequestBody AuditLogEntity auditLog) {
        return ResponseEntity.ok(auditLogService.createAuditLog(auditLog));
    }
    
    @GetMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AuditLogEntity>> getAllAuditLogs() {
        return ResponseEntity.ok(auditLogService.getAllAuditLogs());
    }
    
    @GetMapping("/user/{userId}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AuditLogEntity>> getUserAuditLogs(@PathVariable Long userId) {
        return ResponseEntity.ok(auditLogService.getUserAuditLogs(userId));
    }
    
    @GetMapping("/action/{action}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AuditLogEntity>> getAuditLogsByAction(@PathVariable String action) {
        return ResponseEntity.ok(auditLogService.getAuditLogsByAction(action));
    }
    
    @GetMapping("/entity/{entity}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AuditLogEntity>> getAuditLogsByEntity(@PathVariable String entity) {
        return ResponseEntity.ok(auditLogService.getAuditLogsByEntity(entity));
    }
    
    @GetMapping("/date-range")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AuditLogEntity>> getAuditLogsByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(auditLogService.getAuditLogsByDateRange(startDate, endDate));
    }
    
    @GetMapping("/user/{userId}/date-range")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AuditLogEntity>> getUserAuditLogsByDateRange(
            @PathVariable Long userId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate) {
        return ResponseEntity.ok(auditLogService.getUserAuditLogsByDateRange(userId, startDate, endDate));
    }
}
