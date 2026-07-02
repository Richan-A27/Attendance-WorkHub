package com.isravel.workhub.payroll;

import jakarta.persistence.*;
import lombok.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payroll_records")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class PayrollRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "employee_id", nullable = false)
    private Long employeeId;

    @Column(name = "month", nullable = false)
    private Integer month;

    @Column(name = "year", nullable = false)
    private Integer year;

    @Column(name = "regular_hours")
    private BigDecimal regularHours = BigDecimal.ZERO;

    @Column(name = "overtime_hours")
    private BigDecimal overtimeHours = BigDecimal.ZERO;

    @Column(name = "hourly_rate", nullable = false)
    private BigDecimal hourlyRate;

    @Column(name = "overtime_multiplier")
    private BigDecimal overtimeMultiplier = new BigDecimal("1.50");

    @Column(name = "gross_pay")
    private BigDecimal grossPay = BigDecimal.ZERO;

    @Column(name = "deductions")
    private BigDecimal deductions = BigDecimal.ZERO;

    @Column(name = "bonuses")
    private BigDecimal bonuses = BigDecimal.ZERO;

    @Column(name = "net_pay")
    private BigDecimal netPay = BigDecimal.ZERO;

    @Column(name = "status")
    private String status = "PENDING";

    @Column(name = "processed_date")
    private LocalDateTime processedDate;

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
