package com.isravel.workhub.audit;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLogEntity, Long> {
    
    List<AuditLogEntity> findAllByOrderByCreatedAtDesc();
    
    List<AuditLogEntity> findByUserIdOrderByCreatedAtDesc(Long userId);
    
    List<AuditLogEntity> findByActionOrderByCreatedAtDesc(String action);
    
    List<AuditLogEntity> findByEntityOrderByCreatedAtDesc(String entity);
    
    @Query("SELECT a FROM AuditLogEntity a WHERE a.createdAt BETWEEN :startDate AND :endDate ORDER BY a.createdAt DESC")
    List<AuditLogEntity> findByDateRange(@Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
    
    @Query("SELECT a FROM AuditLogEntity a WHERE a.userId = :userId AND a.createdAt BETWEEN :startDate AND :endDate ORDER BY a.createdAt DESC")
    List<AuditLogEntity> findByUserAndDateRange(@Param("userId") Long userId, @Param("startDate") LocalDateTime startDate, @Param("endDate") LocalDateTime endDate);
}
