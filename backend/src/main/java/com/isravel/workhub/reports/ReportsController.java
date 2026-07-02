package com.isravel.workhub.reports;

import com.isravel.workhub.auth.RequireRole;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/reports")
@RequiredArgsConstructor
public class ReportsController {

    private final WeeklyReportService weeklyReportService;
    private final MonthlyReportService monthlyReportService;

    // Weekly Reports
    @GetMapping("/weekly/{date}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<WeeklyReportService.WeeklyReport> getWeeklyReport(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        LocalDate weekStart = date.with(java.time.temporal.TemporalAdjusters.previousOrSame(java.time.DayOfWeek.MONDAY));
        WeeklyReportService.WeeklyReport report = weeklyReportService.generateWeeklyReport(weekStart);
        return ResponseEntity.ok(report);
    }

    @GetMapping("/weekly/current")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<WeeklyReportService.WeeklyReport> getCurrentWeekReport() {
        WeeklyReportService.WeeklyReport report = weeklyReportService.generateCurrentWeekReport();
        return ResponseEntity.ok(report);
    }

    // Monthly Reports
    @GetMapping("/monthly/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<MonthlyReportService.MonthlyReport> getMonthlyReport(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        MonthlyReportService.MonthlyReport report = monthlyReportService.generateMonthlyReport(month, year);
        return ResponseEntity.ok(report);
    }

    @GetMapping("/monthly/current")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<MonthlyReportService.MonthlyReport> getCurrentMonthReport() {
        MonthlyReportService.MonthlyReport report = monthlyReportService.generateCurrentMonthReport();
        return ResponseEntity.ok(report);
    }
}
