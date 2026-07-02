package com.isravel.workhub.intelligence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface DailyAttendanceRepository extends JpaRepository<DailyAttendance, Long> {

    Optional<DailyAttendance> findByEmployeeIdAndAttendanceDate(Long employeeId, LocalDate attendanceDate);

    List<DailyAttendance> findByEmployeeIdAndAttendanceDateBetweenOrderByAttendanceDateDesc(
            Long employeeId, LocalDate startDate, LocalDate endDate);

    List<DailyAttendance> findByAttendanceDateBetweenOrderByAttendanceDate(LocalDate startDate, LocalDate endDate);

    List<DailyAttendance> findByAttendanceDate(LocalDate attendanceDate);

    @Query("SELECT da FROM DailyAttendance da WHERE da.attendanceDate = :date")
    List<DailyAttendance> findAllByDate(@Param("date") LocalDate date);

    @Query("SELECT COUNT(da) FROM DailyAttendance da WHERE da.employeeId = :employeeId AND da.attendanceDate BETWEEN :startDate AND :endDate AND da.status = 'PRESENT'")
    Long countPresentDays(@Param("employeeId") Long employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    @Query("SELECT COUNT(da) FROM DailyAttendance da WHERE da.employeeId = :employeeId AND da.attendanceDate BETWEEN :startDate AND :endDate AND da.status = 'ABSENT'")
    Long countAbsentDays(@Param("employeeId") Long employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    @Query("SELECT COUNT(da) FROM DailyAttendance da WHERE da.employeeId = :employeeId AND da.attendanceDate BETWEEN :startDate AND :endDate AND da.isLate = true")
    Long countLateDays(@Param("employeeId") Long employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    @Query("SELECT COALESCE(SUM(da.totalWorkingMinutes), 0) FROM DailyAttendance da WHERE da.employeeId = :employeeId AND da.attendanceDate BETWEEN :startDate AND :endDate")
    Integer sumWorkingMinutes(@Param("employeeId") Long employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);

    @Query("SELECT COALESCE(SUM(da.overtimeMinutes), 0) FROM DailyAttendance da WHERE da.employeeId = :employeeId AND da.attendanceDate BETWEEN :startDate AND :endDate")
    Integer sumOvertimeMinutes(@Param("employeeId") Long employeeId, @Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
}
