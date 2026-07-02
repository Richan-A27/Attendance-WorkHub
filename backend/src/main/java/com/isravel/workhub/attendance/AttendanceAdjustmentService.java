package com.isravel.workhub.attendance;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AttendanceAdjustmentService {
    
    @Autowired
    private AttendanceAdjustmentRepository attendanceAdjustmentRepository;
    
    @Transactional
    public AttendanceAdjustmentEntity createAdjustment(AttendanceAdjustmentEntity adjustment) {
        adjustment.setStatus("PENDING");
        return attendanceAdjustmentRepository.save(adjustment);
    }
    
    @Transactional
    public AttendanceAdjustmentEntity approveAdjustment(Long adjustmentId, Long approvedBy) {
        AttendanceAdjustmentEntity adjustment = attendanceAdjustmentRepository.findById(adjustmentId)
                .orElseThrow(() -> new RuntimeException("Adjustment not found"));
        
        if (!"PENDING".equals(adjustment.getStatus())) {
            throw new RuntimeException("Adjustment is not pending");
        }
        
        adjustment.setStatus("APPROVED");
        adjustment.setApprovedBy(approvedBy);
        adjustment.setApprovedAt(LocalDateTime.now());
        
        // Apply the adjustment based on type
        applyAdjustment(adjustment);
        
        return attendanceAdjustmentRepository.save(adjustment);
    }
    
    @Transactional
    public AttendanceAdjustmentEntity rejectAdjustment(Long adjustmentId, Long approvedBy) {
        AttendanceAdjustmentEntity adjustment = attendanceAdjustmentRepository.findById(adjustmentId)
                .orElseThrow(() -> new RuntimeException("Adjustment not found"));
        
        if (!"PENDING".equals(adjustment.getStatus())) {
            throw new RuntimeException("Adjustment is not pending");
        }
        
        adjustment.setStatus("REJECTED");
        adjustment.setApprovedBy(approvedBy);
        adjustment.setApprovedAt(LocalDateTime.now());
        
        return attendanceAdjustmentRepository.save(adjustment);
    }
    
    private void applyAdjustment(AttendanceAdjustmentEntity adjustment) {
        // Note: This is a simplified implementation
        // The actual implementation would need to:
        // 1. Parse the old_value and new_value JSON to extract punch details
        // 2. For ADD_MISSING_PUNCH: Create new attendance_log record
        // 3. For EDIT_PUNCH: Update existing attendance_log record
        // 4. For DELETE_PUNCH: Delete existing attendance_log record
        // 5. Recalculate daily_attendance for the affected date
        // For now, we'll just log that the adjustment was approved
        // The actual attendance log manipulation would require more complex logic
        // and potentially additional database queries to find the correct records
    }
    
    public List<AttendanceAdjustmentEntity> getAllAdjustments() {
        return attendanceAdjustmentRepository.findAllByOrderByCreatedAtDesc();
    }
    
    public List<AttendanceAdjustmentEntity> getPendingAdjustments() {
        return attendanceAdjustmentRepository.findByStatusOrderByCreatedAtDesc("PENDING");
    }
    
    public List<AttendanceAdjustmentEntity> getEmployeeAdjustments(Long employeeId) {
        return attendanceAdjustmentRepository.findByEmployeeIdOrderByCreatedAtDesc(employeeId);
    }
    
    public Long getPendingAdjustmentsCount() {
        return attendanceAdjustmentRepository.countPendingAdjustments();
    }
}
