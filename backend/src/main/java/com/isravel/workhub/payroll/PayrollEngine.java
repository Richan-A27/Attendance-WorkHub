package com.isravel.workhub.payroll;

import com.isravel.workhub.employee.Employee;
import com.isravel.workhub.employee.EmployeeRepository;
import com.isravel.workhub.intelligence.DailyAttendance;
import com.isravel.workhub.intelligence.DailyAttendanceRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class PayrollEngine {

    private final PayrollRecordRepository payrollRecordRepository;
    private final DailyAttendanceRepository dailyAttendanceRepository;
    private final EmployeeRepository employeeRepository;

    @Transactional
    public PayrollRecord calculateMonthlyPayroll(Long employeeId, Integer month, Integer year) {
        log.info("Calculating payroll for employee {} for month {} year {}", employeeId, month, year);
        
        // Get employee
        Employee employee = employeeRepository.findById(employeeId)
                .orElseThrow(() -> new RuntimeException("Employee not found with id: " + employeeId));
        
        // Validate hourly rate
        BigDecimal hourlyRate = employee.getHourlyRate();
        if (hourlyRate == null || hourlyRate.compareTo(BigDecimal.ZERO) <= 0) {
            throw new RuntimeException("Invalid hourly rate for employee " + employeeId + ": must be greater than 0");
        }
        
        // Get or create payroll record
        PayrollRecord payrollRecord = payrollRecordRepository
                .findByEmployeeIdAndMonthAndYear(employeeId, month, year)
                .orElse(new PayrollRecord());
        
        payrollRecord.setEmployeeId(employeeId);
        payrollRecord.setMonth(month);
        payrollRecord.setYear(year);
        payrollRecord.setHourlyRate(hourlyRate);
        
        // Get date range for the month
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();
        
        // Get daily attendance for the month
        List<DailyAttendance> dailyAttendances = dailyAttendanceRepository
                .findByEmployeeIdAndAttendanceDateBetweenOrderByAttendanceDateDesc(
                        employeeId, startDate, endDate);
        
        // Calculate totals
        int totalWorkingMinutes = 0;
        int totalOvertimeMinutes = 0;
        
        for (DailyAttendance daily : dailyAttendances) {
            if (daily.getTotalWorkingMinutes() != null) {
                totalWorkingMinutes += daily.getTotalWorkingMinutes();
            }
            if (daily.getOvertimeMinutes() != null) {
                totalOvertimeMinutes += daily.getOvertimeMinutes();
            }
        }
        
        // Convert to hours (rounded to 2 decimal places)
        BigDecimal regularHours = new BigDecimal(totalWorkingMinutes)
                .divide(new BigDecimal(60), 2, RoundingMode.HALF_UP)
                .subtract(new BigDecimal(totalOvertimeMinutes).divide(new BigDecimal(60), 2, RoundingMode.HALF_UP));
        
        BigDecimal overtimeHours = new BigDecimal(totalOvertimeMinutes)
                .divide(new BigDecimal(60), 2, RoundingMode.HALF_UP);
        
        payrollRecord.setRegularHours(regularHours);
        payrollRecord.setOvertimeHours(overtimeHours);
        
        // Calculate gross pay
        BigDecimal regularPay = regularHours.multiply(payrollRecord.getHourlyRate());
        BigDecimal overtimePay = overtimeHours
                .multiply(payrollRecord.getHourlyRate())
                .multiply(payrollRecord.getOvertimeMultiplier());
        
        BigDecimal grossPay = regularPay.add(overtimePay).add(payrollRecord.getBonuses() != null ? payrollRecord.getBonuses() : BigDecimal.ZERO);
        payrollRecord.setGrossPay(grossPay);
        
        // Calculate net pay
        BigDecimal deductions = payrollRecord.getDeductions() != null ? payrollRecord.getDeductions() : BigDecimal.ZERO;
        BigDecimal netPay = grossPay.subtract(deductions);
        
        // Validate net pay is not negative
        if (netPay.compareTo(BigDecimal.ZERO) < 0) {
            throw new RuntimeException("Net pay cannot be negative for employee " + employeeId + ": " + netPay);
        }
        
        payrollRecord.setNetPay(netPay);
        
        // Set status to calculated
        payrollRecord.setStatus("CALCULATED");
        
        PayrollRecord saved = payrollRecordRepository.save(payrollRecord);
        log.info("Calculated payroll for employee {}: regular hours={}, overtime hours={}, gross pay={}, net pay={}",
                employeeId, regularHours, overtimeHours, grossPay, netPay);
        
        return saved;
    }

    @Transactional
    public List<PayrollRecord> calculatePayrollForAllEmployees(Integer month, Integer year) {
        log.info("Calculating payroll for all employees for month {} year {}", month, year);
        
        List<Employee> activeEmployees = employeeRepository.findAll().stream()
                .filter(Employee::getActive)
                .toList();
        
        List<PayrollRecord> results = new java.util.ArrayList<>();
        
        for (Employee employee : activeEmployees) {
            try {
                PayrollRecord record = calculateMonthlyPayroll(employee.getId(), month, year);
                results.add(record);
            } catch (Exception e) {
                log.error("Error calculating payroll for employee {}", employee.getId(), e);
            }
        }
        
        log.info("Completed payroll calculation for {} employees", results.size());
        return results;
    }

    @Transactional
    public PayrollRecord updatePayrollDeductions(Long employeeId, Integer month, Integer year, BigDecimal deductions) {
        PayrollRecord record = payrollRecordRepository
                .findByEmployeeIdAndMonthAndYear(employeeId, month, year)
                .orElseThrow(() -> new RuntimeException("Payroll record not found"));
        
        record.setDeductions(deductions);
        
        // Recalculate net pay
        BigDecimal netPay = record.getGrossPay().subtract(deductions);
        
        // Validate net pay is not negative
        if (netPay.compareTo(BigDecimal.ZERO) < 0) {
            throw new RuntimeException("Net pay cannot be negative for employee " + employeeId + ": " + netPay);
        }
        
        record.setNetPay(netPay);
        
        return payrollRecordRepository.save(record);
    }

    @Transactional
    public PayrollRecord updatePayrollBonuses(Long employeeId, Integer month, Integer year, BigDecimal bonuses) {
        PayrollRecord record = payrollRecordRepository
                .findByEmployeeIdAndMonthAndYear(employeeId, month, year)
                .orElseThrow(() -> new RuntimeException("Payroll record not found"));
        
        record.setBonuses(bonuses);
        
        // Recalculate gross pay
        BigDecimal regularPay = record.getRegularHours().multiply(record.getHourlyRate());
        BigDecimal overtimePay = record.getOvertimeHours()
                .multiply(record.getHourlyRate())
                .multiply(record.getOvertimeMultiplier());
        
        BigDecimal grossPay = regularPay.add(overtimePay).add(bonuses);
        record.setGrossPay(grossPay);
        
        // Recalculate net pay
        BigDecimal netPay = grossPay.subtract(record.getDeductions() != null ? record.getDeductions() : BigDecimal.ZERO);
        
        // Validate net pay is not negative
        if (netPay.compareTo(BigDecimal.ZERO) < 0) {
            throw new RuntimeException("Net pay cannot be negative for employee " + employeeId + ": " + netPay);
        }
        
        record.setNetPay(netPay);
        
        return payrollRecordRepository.save(record);
    }

    @Transactional
    public PayrollRecord processPayroll(Long employeeId, Integer month, Integer year) {
        PayrollRecord record = payrollRecordRepository
                .findByEmployeeIdAndMonthAndYear(employeeId, month, year)
                .orElseThrow(() -> new RuntimeException("Payroll record not found"));
        
        record.setStatus("PROCESSED");
        record.setProcessedDate(java.time.LocalDateTime.now());
        
        return payrollRecordRepository.save(record);
    }

    @Transactional
    public void processAllPayrollForMonth(Integer month, Integer year) {
        log.info("Processing payroll for all employees for month {} year {}", month, year);
        
        List<PayrollRecord> records = payrollRecordRepository.findByMonthAndYear(month, year);
        
        for (PayrollRecord record : records) {
            try {
                processPayroll(record.getEmployeeId(), month, year);
            } catch (Exception e) {
                log.error("Error processing payroll for employee {}", record.getEmployeeId(), e);
            }
        }
        
        log.info("Completed payroll processing for month {} year {}", month, year);
    }
}
