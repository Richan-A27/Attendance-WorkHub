package com.isravel.workhub.intelligence;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface AttendanceBreakRepository extends JpaRepository<AttendanceBreak, Long> {
    List<AttendanceBreak> findByEmployeeIdAndAttendanceDateOrderByBreakNumberAsc(Long employeeId, LocalDate attendanceDate);
    void deleteByEmployeeIdAndAttendanceDate(Long employeeId, LocalDate attendanceDate);
}
