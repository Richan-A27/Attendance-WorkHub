package com.isravel.workhub.reports;

import com.isravel.workhub.employee.Employee;
import com.isravel.workhub.employee.EmployeeRepository;
import com.isravel.workhub.intelligence.DailyAttendanceRepository;
import com.isravel.workhub.intelligence.EmployeeRankingService;
import com.isravel.workhub.payroll.PayrollRecord;
import com.isravel.workhub.payroll.PayrollRecordRepository;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.YearMonth;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class MonthlyReportService {

    private final DailyAttendanceRepository dailyAttendanceRepository;
    private final PayrollRecordRepository payrollRecordRepository;
    private final EmployeeRepository employeeRepository;
    private final EmployeeRankingService rankingService;

    public MonthlyReport generateMonthlyReport(Integer month, Integer year) {
        log.info("Generating monthly report for month {} year {}", month, year);
        
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();
        
        MonthlyReport report = new MonthlyReport();
        report.setMonth(month);
        report.setYear(year);
        report.setStartDate(startDate);
        report.setEndDate(endDate);
        
        // Generate attendance report
        generateAttendanceSection(report, startDate, endDate);
        
        // Generate payroll report
        generatePayrollSection(report, month, year);
        
        // Generate employee rankings
        generateRankingsSection(report, month, year);
        
        // Calculate aggregate statistics
        calculateAggregateStats(report);
        
        log.info("Monthly report generated for month {} year {}", month, year);
        return report;
    }

    private void generateAttendanceSection(MonthlyReport report, LocalDate startDate, LocalDate endDate) {
        List<EmployeeMonthlyAttendanceStats> attendanceStats = new ArrayList<>();
        
        List<Employee> activeEmployees = employeeRepository.findAll().stream()
                .filter(Employee::getActive)
                .toList();
        
        for (Employee employee : activeEmployees) {
            try {
                EmployeeMonthlyAttendanceStats stats = calculateEmployeeMonthlyAttendance(
                        employee.getId(), startDate, endDate);
                stats.setEmployeeId(employee.getId());
                stats.setEmployeeName(employee.getName());
                attendanceStats.add(stats);
            } catch (Exception e) {
                log.error("Error calculating monthly attendance for employee {}", employee.getId(), e);
            }
        }
        
        report.setAttendanceStats(attendanceStats);
    }

    private EmployeeMonthlyAttendanceStats calculateEmployeeMonthlyAttendance(
            Long employeeId, LocalDate startDate, LocalDate endDate) {
        
        EmployeeMonthlyAttendanceStats stats = new EmployeeMonthlyAttendanceStats();
        
        Long presentDays = dailyAttendanceRepository.countPresentDays(employeeId, startDate, endDate);
        Long absentDays = dailyAttendanceRepository.countAbsentDays(employeeId, startDate, endDate);
        Long lateDays = dailyAttendanceRepository.countLateDays(employeeId, startDate, endDate);
        
        Integer totalWorkingMinutes = dailyAttendanceRepository.sumWorkingMinutes(employeeId, startDate, endDate);
        Integer totalOvertimeMinutes = dailyAttendanceRepository.sumOvertimeMinutes(employeeId, startDate, endDate);
        
        stats.setPresentDays(presentDays != null ? presentDays.intValue() : 0);
        stats.setAbsentDays(absentDays != null ? absentDays.intValue() : 0);
        stats.setLateDays(lateDays != null ? lateDays.intValue() : 0);
        stats.setTotalWorkingHours(totalWorkingMinutes != null ? totalWorkingMinutes / 60.0 : 0);
        stats.setTotalOvertimeHours(totalOvertimeMinutes != null ? totalOvertimeMinutes / 60.0 : 0);
        
        // Calculate attendance percentage
        int totalWorkingDays = calculateWorkingDays(startDate, endDate);
        stats.setAttendancePercentage(totalWorkingDays > 0 
                ? (stats.getPresentDays() / (double) totalWorkingDays) * 100 
                : 0);
        
        return stats;
    }

    private void generatePayrollSection(MonthlyReport report, Integer month, Integer year) {
        List<PayrollRecord> payrollRecords = payrollRecordRepository.findByMonthAndYear(month, year);
        report.setPayrollRecords(payrollRecords);
        
        // Calculate payroll totals
        BigDecimal totalGrossPay = payrollRecords.stream()
                .map(PayrollRecord::getGrossPay)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal totalNetPay = payrollRecords.stream()
                .map(PayrollRecord::getNetPay)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal totalDeductions = payrollRecords.stream()
                .map(PayrollRecord::getDeductions)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        BigDecimal totalBonuses = payrollRecords.stream()
                .map(PayrollRecord::getBonuses)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        
        report.setTotalGrossPay(totalGrossPay);
        report.setTotalNetPay(totalNetPay);
        report.setTotalDeductions(totalDeductions);
        report.setTotalBonuses(totalBonuses);
    }

    private void generateRankingsSection(MonthlyReport report, Integer month, Integer year) {
        // Get top performers
        List<EmployeeRankingService.EmployeeRanking> topPerformers = 
                rankingService.getTopPerformers(month, year, 10);
        report.setTopPerformers(topPerformers);
        
        // Get rankings by different criteria
        report.setRankingsByOverallScore(rankingService.rankEmployeesByOverallScore(month, year));
        report.setRankingsByAttendance(rankingService.rankEmployeesByAttendance(month, year));
        report.setRankingsByPunctuality(rankingService.rankEmployeesByPunctuality(month, year));
        report.setRankingsByWorkingHours(rankingService.rankEmployeesByWorkingHours(month, year));
    }

    private void calculateAggregateStats(MonthlyReport report) {
        // Attendance aggregates
        int totalPresentDays = report.getAttendanceStats().stream()
                .mapToInt(EmployeeMonthlyAttendanceStats::getPresentDays)
                .sum();
        
        int totalAbsentDays = report.getAttendanceStats().stream()
                .mapToInt(EmployeeMonthlyAttendanceStats::getAbsentDays)
                .sum();
        
        int totalLateDays = report.getAttendanceStats().stream()
                .mapToInt(EmployeeMonthlyAttendanceStats::getLateDays)
                .sum();
        
        double totalWorkingHours = report.getAttendanceStats().stream()
                .mapToDouble(EmployeeMonthlyAttendanceStats::getTotalWorkingHours)
                .sum();
        
        double totalOvertimeHours = report.getAttendanceStats().stream()
                .mapToDouble(EmployeeMonthlyAttendanceStats::getTotalOvertimeHours)
                .sum();
        
        report.setTotalPresentDays(totalPresentDays);
        report.setTotalAbsentDays(totalAbsentDays);
        report.setTotalLateDays(totalLateDays);
        report.setTotalWorkingHours(totalWorkingHours);
        report.setTotalOvertimeHours(totalOvertimeHours);
        
        // Average attendance percentage
        double avgAttendance = report.getAttendanceStats().stream()
                .mapToDouble(EmployeeMonthlyAttendanceStats::getAttendancePercentage)
                .average()
                .orElse(0.0);
        report.setAverageAttendancePercentage(avgAttendance);
    }

    private int calculateWorkingDays(LocalDate startDate, LocalDate endDate) {
        int workingDays = 0;
        LocalDate current = startDate;
        
        while (!current.isAfter(endDate)) {
            if (current.getDayOfWeek().getValue() <= 5) { // Monday-Friday
                workingDays++;
            }
            current = current.plusDays(1);
        }
        
        return workingDays;
    }

    public MonthlyReport generateCurrentMonthReport() {
        LocalDate today = LocalDate.now();
        return generateMonthlyReport(today.getMonthValue(), today.getYear());
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class MonthlyReport {
        private Integer month;
        private Integer year;
        private LocalDate startDate;
        private LocalDate endDate;
        private List<EmployeeMonthlyAttendanceStats> attendanceStats;
        private List<PayrollRecord> payrollRecords;
        private List<EmployeeRankingService.EmployeeRanking> topPerformers;
        private List<EmployeeRankingService.EmployeeRanking> rankingsByOverallScore;
        private List<EmployeeRankingService.EmployeeRanking> rankingsByAttendance;
        private List<EmployeeRankingService.EmployeeRanking> rankingsByPunctuality;
        private List<EmployeeRankingService.EmployeeRanking> rankingsByWorkingHours;
        
        // Aggregate statistics
        private Integer totalPresentDays;
        private Integer totalAbsentDays;
        private Integer totalLateDays;
        private Double totalWorkingHours;
        private Double totalOvertimeHours;
        private Double averageAttendancePercentage;
        private BigDecimal totalGrossPay;
        private BigDecimal totalNetPay;
        private BigDecimal totalDeductions;
        private BigDecimal totalBonuses;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EmployeeMonthlyAttendanceStats {
        private Long employeeId;
        private String employeeName;
        private Integer presentDays;
        private Integer absentDays;
        private Integer lateDays;
        private Double totalWorkingHours;
        private Double totalOvertimeHours;
        private Double attendancePercentage;
    }
}
