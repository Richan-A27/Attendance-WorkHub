package com.isravel.workhub.intelligence;

import jakarta.persistence.*;
import lombok.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "daily_attendance")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailyAttendance {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "employee_id", nullable = false)
    private Long employeeId;

    @Column(name = "attendance_date", nullable = false)
    private LocalDate attendanceDate;

    @Column(name = "first_punch")
    private LocalDateTime firstPunch;

    @Column(name = "last_punch")
    private LocalDateTime lastPunch;

    @Column(name = "total_working_minutes")
    private Integer totalWorkingMinutes = 0;

    @Column(name = "break_duration_minutes")
    private Integer breakDurationMinutes = 0;

    @Column(name = "lunch_duration_minutes")
    private Integer lunchDurationMinutes = 0;

    @Column(name = "status")
    private String status = "ABSENT";

    @Column(name = "is_late")
    private Boolean isLate = false;

    @Column(name = "late_minutes")
    private Integer lateMinutes = 0;

    @Column(name = "is_early_departure")
    private Boolean isEarlyDeparture = false;

    @Column(name = "early_departure_minutes")
    private Integer earlyDepartureMinutes = 0;

    @Column(name = "overtime_minutes")
    private Integer overtimeMinutes = 0;

    @Column(name = "scheduled_work_minutes")
    private Integer scheduledWorkMinutes = 0;

    @Column(name = "work_schedule_id")
    private Integer workScheduleId;

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
