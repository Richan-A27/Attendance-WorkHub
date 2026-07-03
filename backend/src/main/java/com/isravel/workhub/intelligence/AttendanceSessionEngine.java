package com.isravel.workhub.intelligence;

import com.isravel.workhub.attendance.AttendanceLog;
import com.isravel.workhub.attendance.AttendanceLogRepository;
import com.isravel.workhub.employee.Employee;
import com.isravel.workhub.employee.EmployeeRepository;
import com.isravel.workhub.schedule.WorkSchedule;
import com.isravel.workhub.schedule.WorkScheduleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class AttendanceSessionEngine {

    private final AttendanceSessionRepository sessionRepository;
    private final AttendanceLogRepository attendanceLogRepository;
    private final WorkScheduleRepository workScheduleRepository;
    private final EmployeeRepository employeeRepository;
    private final AttendanceBreakRepository attendanceBreakRepository;
    private final com.isravel.workhub.settings.CompanyProfileRepository companyProfileRepository;

    @Transactional
    public List<AttendanceSession> processAttendanceSessions(Long employeeId, LocalDate date) {
        log.info("Processing attendance sessions for employee {} on date {}", employeeId, date);
        
        // Load day boundary
        LocalTime dayBoundary = companyProfileRepository.findAll().stream().findFirst()
                .map(com.isravel.workhub.settings.CompanyProfile::getDayBoundary)
                .orElse(LocalTime.of(6, 0));
        if (dayBoundary == null) {
            dayBoundary = LocalTime.of(6, 0);
        }

        // Get all punches for the employee on this date (shifted by day boundary)
        LocalDateTime startOfDay = date.atTime(dayBoundary);
        LocalDateTime endOfDay = date.plusDays(1).atTime(dayBoundary).minusNanos(1);
        
        List<AttendanceLog> punches = attendanceLogRepository
                .findByEmployeeIdAndPunchTimeBetweenOrderByPunchTimeAsc(
                        employeeId, startOfDay, endOfDay);
        
        if (punches.isEmpty()) {
            log.info("No punches found for employee {} on date {}", employeeId, date);
            return new ArrayList<>();
        }
        
        // Sort punches by time
        punches.sort(Comparator.comparing(AttendanceLog::getPunchTime));
        
        // Get work schedule for lunch duration
        WorkSchedule schedule = workScheduleRepository
                .findActiveScheduleByEmployeeId(employeeId)
                .orElse(null);
        
        int lunchDurationMinutes = schedule != null ? schedule.getLunchDurationMinutes() : 45;
        
        // Convert punches to sessions
        List<AttendanceSession> sessions = createSessionsFromPunches(employeeId, date, punches, lunchDurationMinutes);
        
        // Delete existing sessions and breaks for this employee/date
        sessionRepository.deleteByEmployeeIdAndSessionDate(employeeId, date);
        attendanceBreakRepository.deleteByEmployeeIdAndAttendanceDate(employeeId, date);
        
        // Save new sessions
        List<AttendanceSession> savedSessions = sessionRepository.saveAll(sessions);
        
        // Create breaks from sessions (gaps between working sessions)
        List<AttendanceBreak> breaks = new ArrayList<>();
        for (int i = 0; i < savedSessions.size() - 1; i++) {
            AttendanceSession current = savedSessions.get(i);
            AttendanceSession next = savedSessions.get(i + 1);
            if (current.getPunchOut() != null && next.getPunchIn() != null) {
                AttendanceBreak b = new AttendanceBreak();
                b.setEmployeeId(employeeId);
                b.setAttendanceDate(date);
                b.setBreakNumber(i + 1);
                b.setBreakStart(current.getPunchOut());
                b.setBreakEnd(next.getPunchIn());
                b.setDurationMinutes((int) java.time.Duration.between(current.getPunchOut(), next.getPunchIn()).toMinutes());
                breaks.add(b);
            }
        }
        if (!breaks.isEmpty()) {
            attendanceBreakRepository.saveAll(breaks);
        }
        
        log.info("Created {} attendance sessions and {} breaks for employee {} on date {}", savedSessions.size(), breaks.size(), employeeId, date);
        
        return savedSessions;
    }

    private List<AttendanceSession> createSessionsFromPunches(
            Long employeeId, LocalDate date, List<AttendanceLog> punches, int lunchDurationMinutes) {
        
        List<AttendanceSession> sessions = new ArrayList<>();
        
        for (int i = 0; i < punches.size(); i += 2) {
            AttendanceLog punchIn = punches.get(i);
            AttendanceLog punchOut = (i + 1 < punches.size()) ? punches.get(i + 1) : null;
            
            AttendanceSession session = new AttendanceSession();
            session.setEmployeeId(employeeId);
            session.setSessionDate(date);
            session.setSessionNumber((i / 2) + 1);
            session.setPunchIn(punchIn.getPunchTime());
            session.setPunchOut(punchOut != null ? punchOut.getPunchTime() : null);
            
            // Calculate duration if both punches exist
            if (punchOut != null) {
                long durationMinutes = java.time.Duration.between(punchIn.getPunchTime(), punchOut.getPunchTime()).toMinutes();
                session.setDurationMinutes((int) durationMinutes);
                
                // Check if this is a lunch break (keeping for compatibility, but breaks are now gap-based)
                if (isLunchBreak(punchIn.getPunchTime(), punchOut.getPunchTime(), lunchDurationMinutes)) {
                    session.setIsLunchBreak(true);
                }
            }
            
            sessions.add(session);
        }
        
        return sessions;
    }

    private boolean isLunchBreak(LocalDateTime punchIn, LocalDateTime punchOut, int expectedDurationMinutes) {
        LocalTime inTime = punchIn.toLocalTime();
        LocalTime outTime = punchOut.toLocalTime();
        
        // Lunch is typically between 11:30 and 14:30
        LocalTime lunchStartWindow = LocalTime.of(11, 30);
        LocalTime lunchEndWindow = LocalTime.of(14, 30);
        
        boolean inLunchWindow = !inTime.isBefore(lunchStartWindow) && !inTime.isAfter(lunchEndWindow);
        boolean outLunchWindow = !outTime.isBefore(lunchStartWindow) && !outTime.isAfter(lunchEndWindow);
        
        // Duration should be close to expected lunch duration (within 15 minutes tolerance)
        long actualDuration = java.time.Duration.between(punchIn, punchOut).toMinutes();
        boolean durationMatches = Math.abs(actualDuration - expectedDurationMinutes) <= 15;
        
        return inLunchWindow && outLunchWindow && durationMatches;
    }

    @Transactional
    public void processAllAttendanceForDate(LocalDate date) {
        log.info("Processing attendance sessions for all employees on date {}", date);
        
        // Load day boundary
        LocalTime dayBoundary = companyProfileRepository.findAll().stream().findFirst()
                .map(com.isravel.workhub.settings.CompanyProfile::getDayBoundary)
                .orElse(LocalTime.of(6, 0));
        if (dayBoundary == null) {
            dayBoundary = LocalTime.of(6, 0);
        }

        // Get all employees who have punches on this date (using shifted boundary)
        LocalDateTime startOfDay = date.atTime(dayBoundary);
        LocalDateTime endOfDay = date.plusDays(1).atTime(dayBoundary).minusNanos(1);
        
        List<Long> employeeIds = attendanceLogRepository.findDistinctEmployeeIdsByPunchTimeBetween(startOfDay, endOfDay);
        
        for (Long employeeId : employeeIds) {
            try {
                processAttendanceSessions(employeeId, date);
            } catch (Exception e) {
                log.warn("Error processing attendance session for employee_id {}", employeeId, e);
            }
        }
        
        log.info("Completed processing attendance sessions for date {}", date);
    }
}
