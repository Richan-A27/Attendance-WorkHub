package com.isravel.workhub.attendance;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface AttendanceLogRepository extends JpaRepository<AttendanceLog, Long> {
    Page<AttendanceLog> findByEmployeeId(Long employeeId, Pageable pageable);

    @Query("SELECT a FROM AttendanceLog a WHERE a.punchTime >= :start AND a.punchTime <= :end")
    Page<AttendanceLog> findByDateRange(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end, Pageable pageable);

    @Query("SELECT a FROM AttendanceLog a ORDER BY a.punchTime DESC")
    List<AttendanceLog> findRecent(org.springframework.data.domain.Pageable pageable);

    @Query("SELECT MAX(a.punchTime) FROM AttendanceLog a")
    LocalDateTime findLatestPunchTime();

    List<AttendanceLog> findByEmployeeIdAndPunchTimeBetweenOrderByPunchTimeAsc(
            Long employeeId, LocalDateTime start, LocalDateTime end);

    @Query("SELECT DISTINCT a.employeeId FROM AttendanceLog a WHERE a.punchTime BETWEEN :start AND :end")
    List<Long> findDistinctEmployeeIdsByPunchTimeBetween(@Param("start") LocalDateTime start, @Param("end") LocalDateTime end);
}
