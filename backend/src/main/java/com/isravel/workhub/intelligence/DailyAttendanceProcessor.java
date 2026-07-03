package com.isravel.workhub.intelligence;

import com.isravel.workhub.attendance.AttendanceLog;
import com.isravel.workhub.attendance.AttendanceLogRepository;
import com.isravel.workhub.employee.Employee;
import com.isravel.workhub.employee.EmployeeRepository;
import com.isravel.workhub.schedule.Holiday;
import com.isravel.workhub.schedule.HolidayRepository;
import com.isravel.workhub.schedule.WorkSchedule;
import com.isravel.workhub.schedule.WorkScheduleRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class DailyAttendanceProcessor {

    private final DailyAttendanceRepository dailyAttendanceRepository;
    private final AttendanceSessionRepository sessionRepository;
    private final AttendanceLogRepository attendanceLogRepository;
    private final WorkScheduleRepository workScheduleRepository;
    private final HolidayRepository holidayRepository;
    private final EmployeeRepository employeeRepository;
    private final AttendanceBreakRepository attendanceBreakRepository;
    private final com.isravel.workhub.settings.CompanyProfileRepository companyProfileRepository;

    @Transactional
    public DailyAttendance processDailyAttendance(Long employeeId, LocalDate date) {
        log.info("Processing daily attendance for employee {} on date {}", employeeId, date);
        
        // Check if it's a holiday
        java.util.Optional<Holiday> holidayOpt = holidayRepository.findHolidayForDate(date);
        if (holidayOpt.isPresent()) {
            return createHolidayAttendance(employeeId, date, holidayOpt.get());
        }
        
        // Check if it's a weekend
        if (isWeekend(date)) {
            return createWeekendAttendance(employeeId, date);
        }
        
        // Get work schedule
        WorkSchedule schedule = workScheduleRepository
                .findActiveScheduleByEmployeeId(employeeId)
                .orElse(null);
        
        // Get attendance sessions for this date
        List<AttendanceSession> sessions = sessionRepository
                .findByEmployeeIdAndSessionDate(employeeId, date);
        
        // Get breaks
        List<AttendanceBreak> breaks = attendanceBreakRepository
                .findByEmployeeIdAndAttendanceDateOrderByBreakNumberAsc(employeeId, date);
        
        // Get raw punches (shifted by day boundary)
        LocalTime dayBoundary = companyProfileRepository.findAll().stream().findFirst()
                .map(com.isravel.workhub.settings.CompanyProfile::getDayBoundary)
                .orElse(LocalTime.of(6, 0));
        if (dayBoundary == null) {
            dayBoundary = LocalTime.of(6, 0);
        }

        LocalDateTime startOfDay = date.atTime(dayBoundary);
        LocalDateTime endOfDay = date.plusDays(1).atTime(dayBoundary).minusNanos(1);
        
        Employee employee = employeeRepository.findById(employeeId).orElse(null);
        if (employee == null) {
            log.warn("Employee not found with id {}", employeeId);
            return null;
        }
        
        List<AttendanceLog> punches = attendanceLogRepository
                .findByEmployeeIdAndPunchTimeBetweenOrderByPunchTimeAsc(
                        employeeId, startOfDay, endOfDay);
        
        // Create or update daily attendance record
        DailyAttendance dailyAttendance = dailyAttendanceRepository
                .findByEmployeeIdAndAttendanceDate(employeeId, date)
                .orElse(new DailyAttendance());
        
        dailyAttendance.setEmployeeId(employeeId);
        dailyAttendance.setAttendanceDate(date);
        dailyAttendance.setWorkScheduleId(schedule != null ? schedule.getId().intValue() : null);
        
        if (punches.isEmpty()) {
            // No punches - mark as absent
            dailyAttendance.setStatus("ABSENT");
            dailyAttendance.setFirstPunch(null);
            dailyAttendance.setLastPunch(null);
            dailyAttendance.setTotalWorkingMinutes(0);
            dailyAttendance.setWorkingMinutes(0);
            dailyAttendance.setBreakMinutes(0);
            dailyAttendance.setBreakDurationMinutes(0);
            dailyAttendance.setTotalMinutes(0);
            dailyAttendance.setOvertimeMinutes(0);
        } else {
            // Process punches
            processPunches(dailyAttendance, punches, sessions, breaks, schedule);
        }
        
        // Calculate scheduled work minutes
        if (schedule != null) {
            dailyAttendance.setScheduledWorkMinutes(calculateScheduledWorkMinutes(schedule, date));
        }
        
        // Calculate overtime
        calculateOvertime(dailyAttendance);
        
        // Determine final status
        determineAttendanceStatus(dailyAttendance, schedule);
        
        DailyAttendance saved = dailyAttendanceRepository.save(dailyAttendance);
        log.info("Processed daily attendance for employee {} on date {}: status {}", 
                employeeId, date, saved.getStatus());
        
        return saved;
    }

    private void processPunches(DailyAttendance dailyAttendance, List<AttendanceLog> punches, 
                               List<AttendanceSession> sessions, List<AttendanceBreak> breaks, WorkSchedule schedule) {
        if (sessions.isEmpty()) return;
        
        // Set first and last punch from sessions (first starts session, last ends it)
        dailyAttendance.setFirstPunch(sessions.get(0).getPunchIn());
        
        AttendanceSession lastSession = sessions.get(sessions.size() - 1);
        dailyAttendance.setLastPunch(lastSession.getPunchOut());
        
        // Calculate durations
        int totalWorking = 0;
        for (AttendanceSession s : sessions) {
            if (s.getDurationMinutes() != null) {
                totalWorking += s.getDurationMinutes();
            }
        }
        
        int totalBreak = 0;
        for (AttendanceBreak b : breaks) {
            if (b.getDurationMinutes() != null) {
                totalBreak += b.getDurationMinutes();
            }
        }
        
        dailyAttendance.setWorkingMinutes(totalWorking);
        dailyAttendance.setTotalWorkingMinutes(totalWorking); // for compatibility
        
        dailyAttendance.setBreakMinutes(totalBreak);
        dailyAttendance.setBreakDurationMinutes(totalBreak); // for compatibility
        
        if (dailyAttendance.getFirstPunch() != null && dailyAttendance.getLastPunch() != null) {
            int totalMin = (int) java.time.Duration.between(dailyAttendance.getFirstPunch(), dailyAttendance.getLastPunch()).toMinutes();
            dailyAttendance.setTotalMinutes(totalMin);
        } else {
            dailyAttendance.setTotalMinutes(0);
        }
        
        // Detect late arrival
        if (schedule != null && dailyAttendance.getFirstPunch() != null) {
            detectLateArrival(dailyAttendance, schedule);
        }
        
        // Detect early departure
        if (schedule != null && dailyAttendance.getLastPunch() != null) {
            detectEarlyDeparture(dailyAttendance, schedule);
        } else {
            dailyAttendance.setIsEarlyDeparture(false);
            dailyAttendance.setEarlyDepartureMinutes(0);
        }
    }

    private void detectLateArrival(DailyAttendance dailyAttendance, WorkSchedule schedule) {
        LocalTime firstPunchTime = dailyAttendance.getFirstPunch().toLocalTime();
        LocalTime shiftStart = schedule.getStartTime();
        int gracePeriod = schedule.getGracePeriodMinutes() != null ? schedule.getGracePeriodMinutes() : 0;
        
        // Calculate allowed arrival time (shift start + grace period)
        LocalTime allowedArrival = shiftStart.plusMinutes(gracePeriod);
        
        if (firstPunchTime.isAfter(allowedArrival)) {
            dailyAttendance.setIsLate(true);
            int lateMinutes = (int) java.time.Duration.between(shiftStart, firstPunchTime).toMinutes();
            dailyAttendance.setLateMinutes(lateMinutes);
        } else {
            dailyAttendance.setIsLate(false);
            dailyAttendance.setLateMinutes(0);
        }
    }

    private void detectEarlyDeparture(DailyAttendance dailyAttendance, WorkSchedule schedule) {
        LocalTime lastPunchTime = dailyAttendance.getLastPunch().toLocalTime();
        LocalTime shiftEnd = schedule.getEndTime();
        
        // Early departure is leaving more than 15 minutes before shift end
        if (lastPunchTime.isBefore(shiftEnd.minusMinutes(15))) {
            dailyAttendance.setIsEarlyDeparture(true);
            int earlyMinutes = (int) java.time.Duration.between(lastPunchTime, shiftEnd).toMinutes();
            dailyAttendance.setEarlyDepartureMinutes(earlyMinutes);
        } else {
            dailyAttendance.setIsEarlyDeparture(false);
            dailyAttendance.setEarlyDepartureMinutes(0);
        }
    }

    private void calculateOvertime(DailyAttendance dailyAttendance) {
        if (dailyAttendance.getScheduledWorkMinutes() != null && dailyAttendance.getScheduledWorkMinutes() > 0) {
            int overtime = dailyAttendance.getTotalWorkingMinutes() - dailyAttendance.getScheduledWorkMinutes();
            dailyAttendance.setOvertimeMinutes(overtime > 0 ? overtime : 0);
        } else {
            dailyAttendance.setOvertimeMinutes(0);
        }
    }

    private void determineAttendanceStatus(DailyAttendance dailyAttendance, WorkSchedule schedule) {
        // If already set to ABSENT (no punches), keep it
        if (dailyAttendance.getFirstPunch() == null) {
            dailyAttendance.setStatus("ABSENT");
            return;
        }
        
        // If checkout is missing (incomplete punches)
        if (dailyAttendance.getLastPunch() == null) {
            dailyAttendance.setStatus("INCOMPLETE");
            return;
        }
        
        // Check for half day (less than 50% of scheduled hours)
        if (schedule != null && dailyAttendance.getScheduledWorkMinutes() != null) {
            double workRatio = (double) dailyAttendance.getTotalWorkingMinutes() / dailyAttendance.getScheduledWorkMinutes();
            if (workRatio < 0.5) {
                dailyAttendance.setStatus("HALF_DAY");
                return;
            }
        }
        
        // Check if late
        if (dailyAttendance.getIsLate() != null && dailyAttendance.getIsLate()) {
            dailyAttendance.setStatus("LATE");
            return;
        }
        
        // Default to PRESENT
        dailyAttendance.setStatus("PRESENT");
    }

    private DailyAttendance createHolidayAttendance(Long employeeId, LocalDate date, Holiday holiday) {
        DailyAttendance dailyAttendance = dailyAttendanceRepository
                .findByEmployeeIdAndAttendanceDate(employeeId, date)
                .orElse(new DailyAttendance());
        
        dailyAttendance.setEmployeeId(employeeId);
        dailyAttendance.setAttendanceDate(date);
        dailyAttendance.setStatus("HOLIDAY");
        dailyAttendance.setFirstPunch(null);
        dailyAttendance.setLastPunch(null);
        dailyAttendance.setTotalWorkingMinutes(0);
        dailyAttendance.setWorkingMinutes(0);
        dailyAttendance.setBreakMinutes(0);
        dailyAttendance.setBreakDurationMinutes(0);
        dailyAttendance.setTotalMinutes(0);
        dailyAttendance.setOvertimeMinutes(0);
        
        return dailyAttendanceRepository.save(dailyAttendance);
    }

    private DailyAttendance createWeekendAttendance(Long employeeId, LocalDate date) {
        DailyAttendance dailyAttendance = dailyAttendanceRepository
                .findByEmployeeIdAndAttendanceDate(employeeId, date)
                .orElse(new DailyAttendance());
        
        dailyAttendance.setEmployeeId(employeeId);
        dailyAttendance.setAttendanceDate(date);
        dailyAttendance.setStatus("WEEKEND");
        dailyAttendance.setFirstPunch(null);
        dailyAttendance.setLastPunch(null);
        dailyAttendance.setTotalWorkingMinutes(0);
        dailyAttendance.setWorkingMinutes(0);
        dailyAttendance.setBreakMinutes(0);
        dailyAttendance.setBreakDurationMinutes(0);
        dailyAttendance.setTotalMinutes(0);
        dailyAttendance.setOvertimeMinutes(0);
        
        return dailyAttendanceRepository.save(dailyAttendance);
    }

    private boolean isWeekend(LocalDate date) {
        DayOfWeek day = date.getDayOfWeek();
        return day == DayOfWeek.SATURDAY || day == DayOfWeek.SUNDAY;
    }

    private int calculateScheduledWorkMinutes(WorkSchedule schedule, LocalDate date) {
        if (schedule == null || schedule.getStartTime() == null || schedule.getEndTime() == null) {
            return 0;
        }
        
        // Check if this day is a work day
        DayOfWeek day = date.getDayOfWeek();
        String dayName = day.name();
        
        if (schedule.getWorkDays() != null && !schedule.getWorkDays().contains(dayName)) {
            return 0;
        }
        
        // Calculate work duration
        int workMinutes = (int) java.time.Duration.between(
                schedule.getStartTime(), 
                schedule.getEndTime()
        ).toMinutes();
        
        // Subtract lunch duration
        int lunchMinutes = schedule.getLunchDurationMinutes() != null ? schedule.getLunchDurationMinutes() : 45;
        
        return Math.max(0, workMinutes - lunchMinutes);
    }

    @Transactional
    public void processAllAttendanceForDate(LocalDate date) {
        log.info("Processing daily attendance for all employees on date {}", date);
        
        List<Employee> activeEmployees = employeeRepository.findAll().stream()
                .filter(Employee::getActive)
                .toList();
        
        for (Employee employee : activeEmployees) {
            try {
                processDailyAttendance(employee.getId(), date);
            } catch (Exception e) {
                log.error("Error processing attendance for employee {} on date {}", 
                        employee.getId(), date, e);
            }
        }
        
        log.info("Completed processing daily attendance for date {}", date);
    }

    @Transactional
    public void processDateRange(LocalDate startDate, LocalDate endDate) {
        log.info("Processing daily attendance for date range {} to {}", startDate, endDate);
        
        LocalDate current = startDate;
        while (!current.isAfter(endDate)) {
            processAllAttendanceForDate(current);
            current = current.plusDays(1);
        }
        
        log.info("Completed processing daily attendance for date range {} to {}", startDate, endDate);
    }
}
