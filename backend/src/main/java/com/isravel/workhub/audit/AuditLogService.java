package com.isravel.workhub.audit;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AuditLogService {
    
    @Autowired
    private AuditLogRepository auditLogRepository;
    
    @Transactional
    public AuditLogEntity createAuditLog(AuditLogEntity auditLog) {
        return auditLogRepository.save(auditLog);
    }
    
    public List<AuditLogEntity> getAllAuditLogs() {
        return auditLogRepository.findAllByOrderByCreatedAtDesc();
    }
    
    public List<AuditLogEntity> getUserAuditLogs(Long userId) {
        return auditLogRepository.findByUserIdOrderByCreatedAtDesc(userId);
    }
    
    public List<AuditLogEntity> getAuditLogsByAction(String action) {
        return auditLogRepository.findByActionOrderByCreatedAtDesc(action);
    }
    
    public List<AuditLogEntity> getAuditLogsByEntity(String entity) {
        return auditLogRepository.findByEntityOrderByCreatedAtDesc(entity);
    }
    
    public List<AuditLogEntity> getAuditLogsByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        return auditLogRepository.findByDateRange(startDate, endDate);
    }
    
    public List<AuditLogEntity> getUserAuditLogsByDateRange(Long userId, LocalDateTime startDate, LocalDateTime endDate) {
        return auditLogRepository.findByUserAndDateRange(userId, startDate, endDate);
    }
}
