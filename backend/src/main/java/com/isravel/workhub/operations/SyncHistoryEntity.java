package com.isravel.workhub.operations;

import jakarta.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sync_history")
public class SyncHistoryEntity {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(name = "sync_start_time", nullable = false)
    private LocalDateTime syncStartTime;
    
    @Column(name = "sync_end_time")
    private LocalDateTime syncEndTime;
    
    @Column(name = "status", nullable = false)
    private String status; // SUCCESS, FAILURE, IN_PROGRESS
    
    @Column(name = "records_processed")
    private Integer recordsProcessed = 0;
    
    @Column(name = "error_message")
    private String errorMessage;
    
    @Column(name = "created_at")
    private LocalDateTime createdAt;
    
    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public LocalDateTime getSyncStartTime() {
        return syncStartTime;
    }

    public void setSyncStartTime(LocalDateTime syncStartTime) {
        this.syncStartTime = syncStartTime;
    }

    public LocalDateTime getSyncEndTime() {
        return syncEndTime;
    }

    public void setSyncEndTime(LocalDateTime syncEndTime) {
        this.syncEndTime = syncEndTime;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public Integer getRecordsProcessed() {
        return recordsProcessed;
    }

    public void setRecordsProcessed(Integer recordsProcessed) {
        this.recordsProcessed = recordsProcessed;
    }

    public String getErrorMessage() {
        return errorMessage;
    }

    public void setErrorMessage(String errorMessage) {
        this.errorMessage = errorMessage;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
