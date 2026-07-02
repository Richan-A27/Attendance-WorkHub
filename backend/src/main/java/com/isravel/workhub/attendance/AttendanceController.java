package com.isravel.workhub.attendance;

import com.isravel.workhub.auth.RequireRole;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/attendance")
public class AttendanceController {
    private final AttendanceService service;

    public AttendanceController(AttendanceService service) {
        this.service = service;
    }

    @GetMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> list(@RequestParam(required = false) String employeeId,
                                  @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime startDate,
                                  @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime endDate,
                                  @RequestParam(defaultValue = "0") int page,
                                  @RequestParam(defaultValue = "50") int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("punchTime").descending());
        if (employeeId != null) {
            Long empId = Long.parseLong(employeeId);
            Page<AttendanceLog> logs = service.findByEmployeeId(empId, pageable);
            return ResponseEntity.ok(new ApiResponse(true, "Attendance by employee", logs));
        }
        if (startDate != null && endDate != null) {
            Page<AttendanceLog> logs = service.findByDateRange(startDate, endDate, pageable);
            return ResponseEntity.ok(new ApiResponse(true, "Attendance by date range", logs));
        }
        return ResponseEntity.ok(new ApiResponse(true, "All attendance", service.findAll(pageable)));
    }

    @GetMapping("/recent")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> recent(@RequestParam(defaultValue = "10") int limit) {
        return ResponseEntity.ok(new ApiResponse(true, "Recent attendance", service.findRecent(limit)));
    }

    @GetMapping("/today")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<?> today(@RequestParam(defaultValue = "0") int page,
                                   @RequestParam(defaultValue = "50") int size) {
        Pageable pageable = PageRequest.of(page, size, Sort.by("punchTime").descending());
        LocalDateTime start = LocalDateTime.now().toLocalDate().atStartOfDay();
        LocalDateTime end = start.plusDays(1).minusNanos(1);
        return ResponseEntity.ok(new ApiResponse(true, "Today attendance", service.findByDateRange(start, end, pageable)));
    }

    record ApiResponse(boolean success, String message, Object data) {}
}
