package com.isravel.workhub.attendance;

import com.isravel.workhub.auth.RequireRole;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/attendance-adjustments")
@CrossOrigin(origins = "*")
public class AttendanceAdjustmentController {
    
    @Autowired
    private AttendanceAdjustmentService attendanceAdjustmentService;
    
    @PostMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<AttendanceAdjustmentEntity> createAdjustment(@RequestBody AttendanceAdjustmentEntity adjustment) {
        return ResponseEntity.ok(attendanceAdjustmentService.createAdjustment(adjustment));
    }
    
    @GetMapping
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AttendanceAdjustmentEntity>> getAllAdjustments() {
        return ResponseEntity.ok(attendanceAdjustmentService.getAllAdjustments());
    }
    
    @GetMapping("/pending")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AttendanceAdjustmentEntity>> getPendingAdjustments() {
        return ResponseEntity.ok(attendanceAdjustmentService.getPendingAdjustments());
    }
    
    @GetMapping("/employee/{employeeId}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<AttendanceAdjustmentEntity>> getEmployeeAdjustments(@PathVariable Long employeeId) {
        return ResponseEntity.ok(attendanceAdjustmentService.getEmployeeAdjustments(employeeId));
    }
    
    @GetMapping("/pending/count")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<Map<String, Long>> getPendingAdjustmentsCount() {
        Map<String, Long> response = Map.of("count", attendanceAdjustmentService.getPendingAdjustmentsCount());
        return ResponseEntity.ok(response);
    }
    
    @PostMapping("/{id}/approve")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<AttendanceAdjustmentEntity> approveAdjustment(
            @PathVariable Long id,
            @RequestBody Map<String, Long> request) {
        Long approvedBy = request.get("approvedBy");
        return ResponseEntity.ok(attendanceAdjustmentService.approveAdjustment(id, approvedBy));
    }
    
    @PostMapping("/{id}/reject")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<AttendanceAdjustmentEntity> rejectAdjustment(
            @PathVariable Long id,
            @RequestBody Map<String, Long> request) {
        Long approvedBy = request.get("approvedBy");
        return ResponseEntity.ok(attendanceAdjustmentService.rejectAdjustment(id, approvedBy));
    }
}
