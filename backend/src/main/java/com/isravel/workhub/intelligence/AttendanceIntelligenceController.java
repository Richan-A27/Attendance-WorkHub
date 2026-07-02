package com.isravel.workhub.intelligence;

import com.isravel.workhub.auth.RequireRole;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/intelligence")
@RequiredArgsConstructor
public class AttendanceIntelligenceController {

    private final AttendanceSessionEngine sessionEngine;
    private final DailyAttendanceProcessor dailyAttendanceProcessor;
    private final AttendanceSessionRepository sessionRepository;
    private final DailyAttendanceRepository dailyAttendanceRepository;

    @PostMapping("/sessions/process/{employeeId}/{date}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AttendanceSession>> processAttendanceSessions(
            @PathVariable Long employeeId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        List<AttendanceSession> sessions = sessionEngine.processAttendanceSessions(employeeId, date);
        return ResponseEntity.ok(sessions);
    }

    @PostMapping("/sessions/process-all/{date}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<String> processAllAttendanceSessions(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        sessionEngine.processAllAttendanceForDate(date);
        return ResponseEntity.ok("Attendance sessions processed for date: " + date);
    }

    @PostMapping("/daily/process/{employeeId}/{date}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<DailyAttendance> processDailyAttendance(
            @PathVariable Long employeeId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        DailyAttendance dailyAttendance = dailyAttendanceProcessor.processDailyAttendance(employeeId, date);
        return ResponseEntity.ok(dailyAttendance);
    }

    @PostMapping("/daily/process-all/{date}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<String> processAllDailyAttendance(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        dailyAttendanceProcessor.processAllAttendanceForDate(date);
        return ResponseEntity.ok("Daily attendance processed for date: " + date);
    }

    @PostMapping("/daily/process-range")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<String> processDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        dailyAttendanceProcessor.processDateRange(startDate, endDate);
        return ResponseEntity.ok("Daily attendance processed for range: " + startDate + " to " + endDate);
    }

    @GetMapping("/daily/{employeeId}/{date}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<DailyAttendance> getDailyAttendance(
            @PathVariable Long employeeId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return dailyAttendanceRepository.findByEmployeeIdAndAttendanceDate(employeeId, date)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/daily/{employeeId}/range")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<DailyAttendance>> getDailyAttendanceRange(
            @PathVariable Long employeeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<DailyAttendance> attendance = dailyAttendanceRepository
                .findByEmployeeIdAndAttendanceDateBetweenOrderByAttendanceDateDesc(
                        employeeId, startDate, endDate);
        return ResponseEntity.ok(attendance);
    }

    @GetMapping("/sessions/{employeeId}/{date}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AttendanceSession>> getAttendanceSessions(
            @PathVariable Long employeeId,
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        List<AttendanceSession> sessions = sessionRepository.findByEmployeeIdAndSessionDate(employeeId, date);
        return ResponseEntity.ok(sessions);
    }
}
