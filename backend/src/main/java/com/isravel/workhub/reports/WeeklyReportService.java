package com.isravel.workhub.reports;

import com.isravel.workhub.employee.Employee;
import com.isravel.workhub.employee.EmployeeRepository;
import com.isravel.workhub.intelligence.DailyAttendanceRepository;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.ArrayList;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class WeeklyReportService {

    private final DailyAttendanceRepository dailyAttendanceRepository;
    private final EmployeeRepository employeeRepository;

    public WeeklyReport generateWeeklyReport(LocalDate weekStart) {
        log.info("Generating weekly report for week starting {}", weekStart);
        
        LocalDate weekEnd = weekStart.plusDays(6);
        
        WeeklyReport report = new WeeklyReport();
        report.setWeekStart(weekStart);
        report.setWeekEnd(weekEnd);
        
        List<EmployeeWeeklyStats> employeeStats = new ArrayList<>();
        
        List<Employee> activeEmployees = employeeRepository.findAll().stream()
                .filter(Employee::getActive)
                .toList();
        
        for (Employee employee : activeEmployees) {
            try {
                EmployeeWeeklyStats stats = calculateEmployeeWeeklyStats(
                        employee.getId(), weekStart, weekEnd);
                stats.setEmployeeId(employee.getId());
                stats.setEmployeeName(employee.getName());
                employeeStats.add(stats);
            } catch (Exception e) {
                log.error("Error calculating weekly stats for employee {}", employee.getId(), e);
            }
        }
        
        report.setEmployeeStats(employeeStats);
        
        // Calculate aggregate statistics
        calculateAggregateStats(report);
        
        log.info("Weekly report generated for week {} to {}", weekStart, weekEnd);
        return report;
    }

    private EmployeeWeeklyStats calculateEmployeeWeeklyStats(Long employeeId, LocalDate weekStart, LocalDate weekEnd) {
        EmployeeWeeklyStats stats = new EmployeeWeeklyStats();
        
        Long presentDays = dailyAttendanceRepository.countPresentDays(employeeId, weekStart, weekEnd);
        Long absentDays = dailyAttendanceRepository.countAbsentDays(employeeId, weekStart, weekEnd);
        Long lateDays = dailyAttendanceRepository.countLateDays(employeeId, weekStart, weekEnd);
        
        Integer totalWorkingMinutes = dailyAttendanceRepository.sumWorkingMinutes(employeeId, weekStart, weekEnd);
        Integer totalOvertimeMinutes = dailyAttendanceRepository.sumOvertimeMinutes(employeeId, weekStart, weekEnd);
        
        stats.setPresentDays(presentDays != null ? presentDays.intValue() : 0);
        stats.setAbsentDays(absentDays != null ? absentDays.intValue() : 0);
        stats.setLateDays(lateDays != null ? lateDays.intValue() : 0);
        stats.setTotalWorkingHours(totalWorkingMinutes != null ? totalWorkingMinutes / 60.0 : 0);
        stats.setTotalOvertimeHours(totalOvertimeMinutes != null ? totalOvertimeMinutes / 60.0 : 0);
        
        // Calculate attendance percentage
        int totalWorkingDays = 5; // Standard work week
        stats.setAttendancePercentage(totalWorkingDays > 0 
                ? (stats.getPresentDays() / (double) totalWorkingDays) * 100 
                : 0);
        
        return stats;
    }

    private void calculateAggregateStats(WeeklyReport report) {
        int totalEmployees = report.getEmployeeStats().size();
        int totalPresentDays = report.getEmployeeStats().stream()
                .mapToInt(EmployeeWeeklyStats::getPresentDays)
                .sum();
        int totalAbsentDays = report.getEmployeeStats().stream()
                .mapToInt(EmployeeWeeklyStats::getAbsentDays)
                .sum();
        int totalLateDays = report.getEmployeeStats().stream()
                .mapToInt(EmployeeWeeklyStats::getLateDays)
                .sum();
        double totalWorkingHours = report.getEmployeeStats().stream()
                .mapToDouble(EmployeeWeeklyStats::getTotalWorkingHours)
                .sum();
        double totalOvertimeHours = report.getEmployeeStats().stream()
                .mapToDouble(EmployeeWeeklyStats::getTotalOvertimeHours)
                .sum();
        
        report.setTotalEmployees(totalEmployees);
        report.setTotalPresentDays(totalPresentDays);
        report.setTotalAbsentDays(totalAbsentDays);
        report.setTotalLateDays(totalLateDays);
        report.setTotalWorkingHours(totalWorkingHours);
        report.setTotalOvertimeHours(totalOvertimeHours);
        
        // Calculate average attendance percentage
        double avgAttendance = report.getEmployeeStats().stream()
                .mapToDouble(EmployeeWeeklyStats::getAttendancePercentage)
                .average()
                .orElse(0.0);
        report.setAverageAttendancePercentage(avgAttendance);
    }

    public WeeklyReport generateCurrentWeekReport() {
        LocalDate today = LocalDate.now();
        LocalDate weekStart = today.with(TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
        return generateWeeklyReport(weekStart);
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class WeeklyReport {
        private LocalDate weekStart;
        private LocalDate weekEnd;
        private List<EmployeeWeeklyStats> employeeStats;
        private Integer totalEmployees;
        private Integer totalPresentDays;
        private Integer totalAbsentDays;
        private Integer totalLateDays;
        private Double totalWorkingHours;
        private Double totalOvertimeHours;
        private Double averageAttendancePercentage;
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EmployeeWeeklyStats {
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
