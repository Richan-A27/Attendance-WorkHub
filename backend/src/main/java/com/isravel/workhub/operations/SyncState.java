package com.isravel.workhub.operations;

import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@Table(name = "sync_state")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SyncState {
    @Id
    private Integer id;

    @Column(name = "last_sync_time")
    private LocalDateTime lastSyncTime;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
