package com.isravel.workhub.attendance;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface AttendanceAdjustmentRepository extends JpaRepository<AttendanceAdjustmentEntity, Long> {
    
    List<AttendanceAdjustmentEntity> findByEmployeeIdOrderByCreatedAtDesc(Long employeeId);
    
    List<AttendanceAdjustmentEntity> findByStatusOrderByCreatedAtDesc(String status);
    
    List<AttendanceAdjustmentEntity> findAllByOrderByCreatedAtDesc();
    
    @Query("SELECT a FROM AttendanceAdjustmentEntity a WHERE a.attendanceDate BETWEEN :startDate AND :endDate ORDER BY a.createdAt DESC")
    List<AttendanceAdjustmentEntity> findByDateRange(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
    
    @Query("SELECT COUNT(a) FROM AttendanceAdjustmentEntity a WHERE a.status = 'PENDING'")
    Long countPendingAdjustments();
}
