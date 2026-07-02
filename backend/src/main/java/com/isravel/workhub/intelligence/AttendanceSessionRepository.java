package com.isravel.workhub.intelligence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface AttendanceSessionRepository extends JpaRepository<AttendanceSession, Long> {

    List<AttendanceSession> findByEmployeeIdAndSessionDate(Long employeeId, LocalDate sessionDate);

    List<AttendanceSession> findByEmployeeIdAndSessionDateBetweenOrderBySessionDateAscSessionNumberAsc(
            Long employeeId, LocalDate startDate, LocalDate endDate);

    @Query("SELECT s FROM AttendanceSession s WHERE s.employeeId = :employeeId AND s.sessionDate = :date ORDER BY s.sessionNumber")
    List<AttendanceSession> findSessionsForEmployeeOnDate(@Param("employeeId") Long employeeId, @Param("date") LocalDate date);

    @Query("SELECT s FROM AttendanceSession s WHERE s.sessionDate BETWEEN :startDate AND :endDate ORDER BY s.sessionDate, s.employeeId, s.sessionNumber")
    List<AttendanceSession> findSessionsInPeriod(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    @Query("SELECT COALESCE(SUM(s.durationMinutes), 0) FROM AttendanceSession s WHERE s.employeeId = :employeeId AND s.sessionDate = :date AND s.isLunchBreak = false")
    Integer calculateWorkMinutesForEmployeeOnDate(@Param("employeeId") Long employeeId, @Param("date") LocalDate date);

    @Query("SELECT COALESCE(SUM(s.durationMinutes), 0) FROM AttendanceSession s WHERE s.employeeId = :employeeId AND s.sessionDate = :date AND s.isLunchBreak = true")
    Integer calculateLunchMinutesForEmployeeOnDate(@Param("employeeId") Long employeeId, @Param("date") LocalDate date);

    void deleteByEmployeeIdAndSessionDate(Long employeeId, LocalDate sessionDate);
}
