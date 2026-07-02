package com.isravel.workhub.schedule;

import com.isravel.workhub.auth.RequireRole;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/schedules")
@RequiredArgsConstructor
public class ScheduleController {

    private final WorkScheduleRepository workScheduleRepository;
    private final HolidayRepository holidayRepository;

    // Work Schedule endpoints
    @PostMapping("/work-schedules")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<WorkSchedule> createWorkSchedule(@RequestBody WorkSchedule schedule) {
        WorkSchedule saved = workScheduleRepository.save(schedule);
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/work-schedules/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<WorkSchedule> getWorkSchedule(@PathVariable Long id) {
        return workScheduleRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/work-schedules/employee/{employeeId}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<WorkSchedule> getEmployeeSchedule(@PathVariable Long employeeId) {
        return workScheduleRepository.findActiveScheduleByEmployeeId(employeeId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/work-schedules")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<WorkSchedule>> getAllWorkSchedules() {
        List<WorkSchedule> schedules = workScheduleRepository.findByActiveTrue();
        return ResponseEntity.ok(schedules);
    }

    @PutMapping("/work-schedules/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<WorkSchedule> updateWorkSchedule(
            @PathVariable Long id, @RequestBody WorkSchedule schedule) {
        schedule.setId(id);
        WorkSchedule updated = workScheduleRepository.save(schedule);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/work-schedules/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<Void> deleteWorkSchedule(@PathVariable Long id) {
        workScheduleRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }

    // Holiday endpoints
    @PostMapping("/holidays")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<Holiday> createHoliday(@RequestBody Holiday holiday) {
        Holiday saved = holidayRepository.save(holiday);
        return ResponseEntity.ok(saved);
    }

    @GetMapping("/holidays/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<Holiday> getHoliday(@PathVariable Long id) {
        return holidayRepository.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/holidays/date/{date}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<Holiday> getHolidayByDate(
            @PathVariable @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date) {
        return holidayRepository.findHolidayForDate(date)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/holidays")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<Holiday>> getAllHolidays() {
        List<Holiday> holidays = holidayRepository.findAll();
        return ResponseEntity.ok(holidays);
    }

    @GetMapping("/holidays/range")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<Holiday>> getHolidaysInRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        List<Holiday> holidays = holidayRepository.findHolidaysInPeriod(startDate, endDate);
        return ResponseEntity.ok(holidays);
    }

    @PutMapping("/holidays/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<Holiday> updateHoliday(
            @PathVariable Long id, @RequestBody Holiday holiday) {
        holiday.setId(id);
        Holiday updated = holidayRepository.save(holiday);
        return ResponseEntity.ok(updated);
    }

    @DeleteMapping("/holidays/{id}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<Void> deleteHoliday(@PathVariable Long id) {
        holidayRepository.deleteById(id);
        return ResponseEntity.noContent().build();
    }
}
