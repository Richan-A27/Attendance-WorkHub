package com.isravel.workhub.intelligence;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "attendance_sessions")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceSession {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "employee_id", nullable = false)
    private Long employeeId;

    @Column(name = "session_date", nullable = false)
    private LocalDate sessionDate;

    @Column(name = "session_number", nullable = false)
    private Integer sessionNumber;

    @Column(name = "punch_in", nullable = false)
    private LocalDateTime punchIn;

    @Column(name = "punch_out")
    private LocalDateTime punchOut;

    @Column(name = "duration_minutes")
    private Integer durationMinutes;

    @Column(name = "is_lunch_break")
    private Boolean isLunchBreak = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        if (punchIn != null && punchOut != null) {
            durationMinutes = (int) java.time.Duration.between(punchIn, punchOut).toMinutes();
        }
    }
}
