package com.isravel.workhub.device;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "sync_history")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SyncHistory {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "started_at", nullable = false)
    private LocalDateTime startedAt;

    @Column(name = "finished_at")
    private LocalDateTime finishedAt;

    @Column(name = "employees_processed")
    private Integer employeesProcessed;

    @Column(name = "attendance_processed")
    private Integer attendanceProcessed;

    @Column(name = "duplicates_skipped")
    private Integer duplicatesSkipped;

    @Column(name = "success")
    private Boolean success;

    @Column(name = "error_message")
    private String errorMessage;
}
