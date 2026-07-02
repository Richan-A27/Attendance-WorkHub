package com.isravel.workhub.attendance;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
public class AttendanceService {
    private final AttendanceLogRepository repo;

    public AttendanceService(AttendanceLogRepository repo) {
        this.repo = repo;
    }

    public Page<AttendanceLog> findAll(Pageable pageable) {
        return repo.findAll(pageable);
    }

    public Page<AttendanceLog> findByEmployeeId(Long employeeId, Pageable pageable) {
        return repo.findByEmployeeId(employeeId, pageable);
    }

    public Page<AttendanceLog> findByDateRange(LocalDateTime start, LocalDateTime end, Pageable pageable) {
        return repo.findByDateRange(start, end, pageable);
    }

    public List<AttendanceLog> findRecent(int limit) {
        return repo.findRecent(PageRequest.of(0, limit));
    }

    public LocalDateTime latestPunchTime() {
        return repo.findLatestPunchTime();
    }

    public AttendanceLog save(AttendanceLog log) {
        if (log.getCreatedAt() == null) {
            log.setCreatedAt(LocalDateTime.now());
        }
        return repo.save(log);
    }

    public List<AttendanceLog> saveAll(List<AttendanceLog> logs) {
        logs.forEach(log -> {
            if (log.getCreatedAt() == null) {
                log.setCreatedAt(LocalDateTime.now());
            }
        });
        return repo.saveAll(logs);
    }
}
