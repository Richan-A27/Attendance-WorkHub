package com.isravel.workhub.attendance;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "attendance_logs", uniqueConstraints = @UniqueConstraint(columnNames = {"employee_id", "punch_time"}))
@Data
@NoArgsConstructor
@AllArgsConstructor
public class AttendanceLog {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "employee_id", nullable = false)
    private Long employeeId;

    @Column(name = "punch_time", nullable = false)
    private LocalDateTime punchTime;

    @Column(name = "verify_mode")
    private Integer verifyMode;

    @Column(name = "status")
    private Integer status;

    @Column(name = "created_at")
    private LocalDateTime createdAt;
}
