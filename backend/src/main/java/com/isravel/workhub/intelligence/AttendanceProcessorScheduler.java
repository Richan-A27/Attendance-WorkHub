package com.isravel.workhub.intelligence;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDate;

@Component
@RequiredArgsConstructor
@Slf4j
public class AttendanceProcessorScheduler {

    private final AttendanceSessionEngine sessionEngine;
    private final DailyAttendanceProcessor dailyAttendanceProcessor;

    @Scheduled(fixedDelay = 10000) // Every 10 seconds
    public void processRecentAttendance() {
        LocalDate today = LocalDate.now();
        // Process today, yesterday, and the day before to ensure any late/cross-day/recent punches are processed
        for (int i = 0; i <= 2; i++) {
            LocalDate dateToProcess = today.minusDays(i);
            try {
                sessionEngine.processAllAttendanceForDate(dateToProcess);
                dailyAttendanceProcessor.processAllAttendanceForDate(dateToProcess);
            } catch (Exception e) {
                log.error("Failed to automatically process attendance for date {}", dateToProcess, e);
            }
        }
    }
}
