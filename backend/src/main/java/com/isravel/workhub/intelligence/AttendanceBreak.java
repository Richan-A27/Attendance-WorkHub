package com.isravel.workhub.intelligence;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "attendance_breaks")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceBreak {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "employee_id", nullable = false)
    private Long employeeId;

    @Column(name = "attendance_date", nullable = false)
    private LocalDate attendanceDate;

    @Column(name = "break_number", nullable = false)
    private Integer breakNumber;

    @Column(name = "break_start", nullable = false)
    private LocalDateTime breakStart;

    @Column(name = "break_end", nullable = false)
    private LocalDateTime breakEnd;

    @Column(name = "duration_minutes", nullable = false)
    private Integer durationMinutes;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (breakStart != null && breakEnd != null) {
            durationMinutes = (int) java.time.Duration.between(breakStart, breakEnd).toMinutes();
        }
    }
}
