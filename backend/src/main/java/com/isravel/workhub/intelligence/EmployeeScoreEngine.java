package com.isravel.workhub.intelligence;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.YearMonth;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmployeeScoreEngine {

    private final DailyAttendanceRepository dailyAttendanceRepository;

    public EmployeeScore calculateEmployeeScore(Long employeeId, Integer month, Integer year) {
        log.info("Calculating employee score for employee {} for month {} year {}", employeeId, month, year);
        
        YearMonth yearMonth = YearMonth.of(year, month);
        LocalDate startDate = yearMonth.atDay(1);
        LocalDate endDate = yearMonth.atEndOfMonth();
        
        // Get total working days in month (excluding weekends)
        int totalWorkingDays = calculateWorkingDays(startDate, endDate);
        
        // Get attendance statistics
        Long presentDays = dailyAttendanceRepository.countPresentDays(employeeId, startDate, endDate);
        Long absentDays = dailyAttendanceRepository.countAbsentDays(employeeId, startDate, endDate);
        Long lateDays = dailyAttendanceRepository.countLateDays(employeeId, startDate, endDate);
        
        // Get working and overtime minutes
        Integer totalWorkingMinutes = dailyAttendanceRepository.sumWorkingMinutes(employeeId, startDate, endDate);
        Integer totalOvertimeMinutes = dailyAttendanceRepository.sumOvertimeMinutes(employeeId, startDate, endDate);
        
        // Calculate percentages
        double attendancePercentage = totalWorkingDays > 0 
                ? (presentDays != null ? presentDays.doubleValue() : 0) / totalWorkingDays * 100 
                : 0;
        
        double punctualityPercentage = (presentDays != null && presentDays > 0) 
                ? ((presentDays - (lateDays != null ? lateDays : 0)) / (double) presentDays) * 100 
                : 0;
        
        // Calculate consistency (based on regular attendance pattern)
        double consistencyPercentage = calculateConsistency(employeeId, startDate, endDate);
        
        // Calculate overtime contribution (normalized score)
        double overtimeContribution = calculateOvertimeContribution(totalOvertimeMinutes);
        
        // Calculate overall score (weighted average)
        double overallScore = (attendancePercentage * 0.4) 
                            + (punctualityPercentage * 0.25) 
                            + (consistencyPercentage * 0.25) 
                            + (overtimeContribution * 0.1);
        
        EmployeeScore score = new EmployeeScore();
        score.setEmployeeId(employeeId);
        score.setMonth(month);
        score.setYear(year);
        score.setAttendancePercentage(Math.round(attendancePercentage * 100.0) / 100.0);
        score.setPunctualityPercentage(Math.round(punctualityPercentage * 100.0) / 100.0);
        score.setConsistencyPercentage(Math.round(consistencyPercentage * 100.0) / 100.0);
        score.setOvertimeContribution(Math.round(overtimeContribution * 100.0) / 100.0);
        score.setOverallScore(Math.round(overallScore * 100.0) / 100.0);
        score.setPresentDays(presentDays != null ? presentDays.intValue() : 0);
        score.setAbsentDays(absentDays != null ? absentDays.intValue() : 0);
        score.setLateDays(lateDays != null ? lateDays.intValue() : 0);
        score.setTotalWorkingHours(totalWorkingMinutes != null ? totalWorkingMinutes / 60.0 : 0);
        score.setTotalOvertimeHours(totalOvertimeMinutes != null ? totalOvertimeMinutes / 60.0 : 0);
        
        log.info("Employee score calculated: attendance={}, punctuality={}, consistency={}, overall={}",
                score.getAttendancePercentage(), score.getPunctualityPercentage(), 
                score.getConsistencyPercentage(), score.getOverallScore());
        
        return score;
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

    private double calculateConsistency(Long employeeId, LocalDate startDate, LocalDate endDate) {
        // Consistency is based on consecutive attendance and regular patterns
        // For simplicity, we'll use a basic calculation based on attendance ratio
        
        Long presentDays = dailyAttendanceRepository.countPresentDays(employeeId, startDate, endDate);
        int totalWorkingDays = calculateWorkingDays(startDate, endDate);
        
        if (totalWorkingDays == 0) return 0;
        
        double baseConsistency = (presentDays != null ? presentDays.doubleValue() : 0) / totalWorkingDays;
        
        // Bonus for high attendance
        if (baseConsistency >= 0.95) return 100;
        if (baseConsistency >= 0.90) return 95;
        if (baseConsistency >= 0.85) return 90;
        if (baseConsistency >= 0.80) return 85;
        if (baseConsistency >= 0.75) return 80;
        if (baseConsistency >= 0.70) return 75;
        
        return baseConsistency * 100;
    }

    private double calculateOvertimeContribution(Integer totalOvertimeMinutes) {
        if (totalOvertimeMinutes == null || totalOvertimeMinutes == 0) return 50; // Neutral score
        
        double overtimeHours = totalOvertimeMinutes / 60.0;
        
        // Score based on overtime contribution (capped at 100)
        // Up to 10 hours overtime = 100 points
        // 0 hours = 50 points (neutral)
        // More than 10 hours = diminishing returns
        
        if (overtimeHours <= 10) {
            return 50 + (overtimeHours * 5); // 50-100 range
        } else {
            return 100; // Cap at 100
        }
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EmployeeScore {
        private Long employeeId;
        private Integer month;
        private Integer year;
        private Double attendancePercentage;
        private Double punctualityPercentage;
        private Double consistencyPercentage;
        private Double overtimeContribution;
        private Double overallScore;
        private Integer presentDays;
        private Integer absentDays;
        private Integer lateDays;
        private Double totalWorkingHours;
        private Double totalOvertimeHours;
    }
}
