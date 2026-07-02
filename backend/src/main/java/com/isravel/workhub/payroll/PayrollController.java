package com.isravel.workhub.payroll;

import com.isravel.workhub.auth.RequireRole;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.math.BigDecimal;
import java.util.List;

@RestController
@RequestMapping("/api/payroll")
@RequiredArgsConstructor
public class PayrollController {

    private final PayrollEngine payrollEngine;
    private final PayrollRecordRepository payrollRecordRepository;

    @PostMapping("/calculate/{employeeId}/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<PayrollRecord> calculatePayroll(
            @PathVariable Long employeeId,
            @PathVariable Integer month,
            @PathVariable Integer year) {
        PayrollRecord record = payrollEngine.calculateMonthlyPayroll(employeeId, month, year);
        return ResponseEntity.ok(record);
    }

    @PostMapping("/calculate-all/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<PayrollRecord>> calculateAllPayroll(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        List<PayrollRecord> records = payrollEngine.calculatePayrollForAllEmployees(month, year);
        return ResponseEntity.ok(records);
    }

    @GetMapping("/employee/{employeeId}/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<PayrollRecord> getEmployeePayroll(
            @PathVariable Long employeeId,
            @PathVariable Integer month,
            @PathVariable Integer year) {
        return payrollRecordRepository.findByEmployeeIdAndMonthAndYear(employeeId, month, year)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/month/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<PayrollRecord>> getMonthlyPayroll(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        List<PayrollRecord> records = payrollRecordRepository.findByMonthAndYear(month, year);
        return ResponseEntity.ok(records);
    }

    @GetMapping("/employee/{employeeId}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<PayrollRecord>> getEmployeePayrollHistory(@PathVariable Long employeeId) {
        List<PayrollRecord> records = payrollRecordRepository.findEmployeePayrollHistory(employeeId);
        return ResponseEntity.ok(records);
    }

    @PutMapping("/deductions/{employeeId}/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<PayrollRecord> updateDeductions(
            @PathVariable Long employeeId,
            @PathVariable Integer month,
            @PathVariable Integer year,
            @RequestParam BigDecimal deductions) {
        PayrollRecord record = payrollEngine.updatePayrollDeductions(employeeId, month, year, deductions);
        return ResponseEntity.ok(record);
    }

    @PutMapping("/bonuses/{employeeId}/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<PayrollRecord> updateBonuses(
            @PathVariable Long employeeId,
            @PathVariable Integer month,
            @PathVariable Integer year,
            @RequestParam BigDecimal bonuses) {
        PayrollRecord record = payrollEngine.updatePayrollBonuses(employeeId, month, year, bonuses);
        return ResponseEntity.ok(record);
    }

    @PostMapping("/process/{employeeId}/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<PayrollRecord> processPayroll(
            @PathVariable Long employeeId,
            @PathVariable Integer month,
            @PathVariable Integer year) {
        PayrollRecord record = payrollEngine.processPayroll(employeeId, month, year);
        return ResponseEntity.ok(record);
    }

    @PostMapping("/process-all/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<String> processAllPayroll(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        payrollEngine.processAllPayrollForMonth(month, year);
        return ResponseEntity.ok("Payroll processed for month " + month + " year " + year);
    }

    @GetMapping("/summary/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<PayrollSummary> getPayrollSummary(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        List<PayrollRecord> records = payrollRecordRepository.findByMonthAndYear(month, year);
        
        BigDecimal totalGross = records.stream()
                .map(PayrollRecord::getGrossPay)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal totalNet = records.stream()
                .map(PayrollRecord::getNetPay)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal totalDeductions = records.stream()
                .map(PayrollRecord::getDeductions)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal totalOvertimeHours = records.stream()
                .map(PayrollRecord::getOvertimeHours)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        PayrollSummary summary = new PayrollSummary();
        summary.setMonth(month);
        summary.setYear(year);
        summary.setTotalEmployees(records.size());
        summary.setTotalGrossPay(totalGross);
        summary.setTotalNetPay(totalNet);
        summary.setTotalDeductions(totalDeductions);
        summary.setTotalOvertimeHours(totalOvertimeHours);
        
        return ResponseEntity.ok(summary);
    }

    @lombok.Data
    public static class PayrollSummary {
        private Integer month;
        private Integer year;
        private Integer totalEmployees;
        private BigDecimal totalGrossPay;
        private BigDecimal totalNetPay;
        private BigDecimal totalDeductions;
        private BigDecimal totalOvertimeHours;
    }
}
