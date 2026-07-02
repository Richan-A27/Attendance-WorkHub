package com.isravel.workhub.dashboard;

import com.isravel.workhub.attendance.AttendanceLogRepository;
import com.isravel.workhub.employee.EmployeeRepository;
import com.isravel.workhub.intelligence.DailyAttendanceRepository;
import com.isravel.workhub.payroll.PayrollRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.YearMonth;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
@RequiredArgsConstructor
public class DashboardService {
    private final EmployeeRepository employeeRepository;
    private final AttendanceLogRepository attendanceRepo;
    private final DailyAttendanceRepository dailyAttendanceRepository;
    private final PayrollRecordRepository payrollRecordRepository;

    public Map<String, Object> summary() {
        Map<String, Object> m = new HashMap<>();
        LocalDate today = LocalDate.now();
        LocalDateTime start = LocalDateTime.now().with(LocalTime.MIN);
        LocalDateTime end = LocalDateTime.now().with(LocalTime.MAX);
        
        // Basic employee stats
        long total = employeeRepository.count();
        long active = employeeRepository.countByActiveTrue();
        m.put("totalEmployees", total);
        m.put("activeEmployees", active);
        
        // Legacy attendance stats
        long attendanceToday = attendanceRepo.findByDateRange(start, end, org.springframework.data.domain.Pageable.unpaged()).getContent().size();
        LocalDateTime latestPunch = attendanceRepo.findLatestPunchTime();
        m.put("attendanceLogsToday", attendanceToday);
        m.put("latestPunch", latestPunch);
        
        // New workforce intelligence metrics
        addWorkforceIntelligenceMetrics(m, today);
        
        return m;
    }

    private void addWorkforceIntelligenceMetrics(Map<String, Object> m, LocalDate today) {
        // Get all daily attendance records for today
        List<com.isravel.workhub.intelligence.DailyAttendance> todayAttendance = 
                dailyAttendanceRepository.findByAttendanceDate(today);
        
        // Present Today
        long presentToday = todayAttendance.stream()
                .filter(d -> "PRESENT".equals(d.getStatus()) || "LATE".equals(d.getStatus()))
                .count();
        m.put("presentToday", presentToday);
        
        // Absent Today
        long absentToday = todayAttendance.stream()
                .filter(d -> "ABSENT".equals(d.getStatus()))
                .count();
        m.put("absentToday", absentToday);
        
        // Late Today
        long lateToday = todayAttendance.stream()
                .filter(d -> d.getIsLate() != null && d.getIsLate())
                .count();
        m.put("lateToday", lateToday);
        
        // Employees On Leave (includes holidays, weekends, leave status)
        long onLeaveToday = todayAttendance.stream()
                .filter(d -> "HOLIDAY".equals(d.getStatus()) || 
                           "WEEKEND".equals(d.getStatus()) || 
                           "ON_LEAVE".equals(d.getStatus()))
                .count();
        m.put("onLeaveToday", onLeaveToday);
        
        // Total Hours Today
        int totalMinutesToday = todayAttendance.stream()
                .mapToInt(d -> d.getTotalWorkingMinutes() != null ? d.getTotalWorkingMinutes() : 0)
                .sum();
        double totalHoursToday = totalMinutesToday / 60.0;
        m.put("totalHoursToday", totalHoursToday);
        
        // Payroll This Month
        YearMonth currentMonth = YearMonth.now();
        List<com.isravel.workhub.payroll.PayrollRecord> monthlyPayroll = 
                payrollRecordRepository.findByMonthAndYear(
                        currentMonth.getMonthValue(), 
                        currentMonth.getYear());
        
        BigDecimal payrollThisMonth = monthlyPayroll.stream()
                .map(com.isravel.workhub.payroll.PayrollRecord::getNetPay)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        m.put("payrollThisMonth", payrollThisMonth);
        
        // Additional helpful metrics
        m.put("halfDayToday", todayAttendance.stream()
                .filter(d -> "HALF_DAY".equals(d.getStatus()))
                .count());
        
        int totalOvertimeMinutes = todayAttendance.stream()
                .mapToInt(d -> d.getOvertimeMinutes() != null ? d.getOvertimeMinutes() : 0)
                .sum();
        m.put("totalOvertimeHoursToday", totalOvertimeMinutes / 60.0);
    }
}
