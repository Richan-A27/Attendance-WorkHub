package com.isravel.workhub.intelligence;

import com.isravel.workhub.auth.RequireRole;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/rankings")
@RequiredArgsConstructor
public class EmployeeRankingController {

    private final EmployeeRankingService rankingService;
    private final EmployeeScoreEngine scoreEngine;

    // Employee Scores
    @GetMapping("/score/{employeeId}/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<EmployeeScoreEngine.EmployeeScore> getEmployeeScore(
            @PathVariable Long employeeId,
            @PathVariable Integer month,
            @PathVariable Integer year) {
        EmployeeScoreEngine.EmployeeScore score = scoreEngine.calculateEmployeeScore(employeeId, month, year);
        return ResponseEntity.ok(score);
    }

    // Rankings
    @GetMapping("/overall/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<EmployeeRankingService.EmployeeRanking>> rankByOverallScore(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        List<EmployeeRankingService.EmployeeRanking> rankings = 
                rankingService.rankEmployeesByOverallScore(month, year);
        return ResponseEntity.ok(rankings);
    }

    @GetMapping("/attendance/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<EmployeeRankingService.EmployeeRanking>> rankByAttendance(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        List<EmployeeRankingService.EmployeeRanking> rankings = 
                rankingService.rankEmployeesByAttendance(month, year);
        return ResponseEntity.ok(rankings);
    }

    @GetMapping("/punctuality/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<EmployeeRankingService.EmployeeRanking>> rankByPunctuality(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        List<EmployeeRankingService.EmployeeRanking> rankings = 
                rankingService.rankEmployeesByPunctuality(month, year);
        return ResponseEntity.ok(rankings);
    }

    @GetMapping("/working-hours/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<EmployeeRankingService.EmployeeRanking>> rankByWorkingHours(
            @PathVariable Integer month,
            @PathVariable Integer year) {
        List<EmployeeRankingService.EmployeeRanking> rankings = 
                rankingService.rankEmployeesByWorkingHours(month, year);
        return ResponseEntity.ok(rankings);
    }

    @GetMapping("/top-performers/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<List<EmployeeRankingService.EmployeeRanking>> getTopPerformers(
            @PathVariable Integer month,
            @PathVariable Integer year,
            @RequestParam(defaultValue = "10") int limit) {
        List<EmployeeRankingService.EmployeeRanking> topPerformers = 
                rankingService.getTopPerformers(month, year, limit);
        return ResponseEntity.ok(topPerformers);
    }
}
