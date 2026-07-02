package com.isravel.workhub.intelligence;

import com.isravel.workhub.employee.Employee;
import com.isravel.workhub.employee.EmployeeRepository;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.List;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
@Slf4j
public class EmployeeRankingService {

    private final EmployeeScoreEngine scoreEngine;
    private final EmployeeRepository employeeRepository;

    public List<EmployeeRanking> rankEmployeesByOverallScore(Integer month, Integer year) {
        log.info("Ranking employees by overall score for month {} year {}", month, year);
        
        List<Employee> activeEmployees = employeeRepository.findAll().stream()
                .filter(Employee::getActive)
                .toList();
        
        List<EmployeeRanking> rankings = new ArrayList<>();
        
        for (Employee employee : activeEmployees) {
            try {
                EmployeeScoreEngine.EmployeeScore score = scoreEngine.calculateEmployeeScore(
                        employee.getId(), month, year);
                
                EmployeeRanking ranking = new EmployeeRanking();
                ranking.setEmployeeId(employee.getId());
                ranking.setEmployeeName(employee.getName());
                ranking.setScore(score);
                rankings.add(ranking);
            } catch (Exception e) {
                log.error("Error calculating score for employee {}", employee.getId(), e);
            }
        }
        
        // Sort by overall score descending
        rankings.sort(Comparator.comparing(EmployeeRanking::getOverallScore).reversed());
        
        // Assign ranks
        for (int i = 0; i < rankings.size(); i++) {
            rankings.get(i).setRank(i + 1);
        }
        
        log.info("Ranked {} employees", rankings.size());
        return rankings;
    }

    public List<EmployeeRanking> rankEmployeesByAttendance(Integer month, Integer year) {
        log.info("Ranking employees by attendance for month {} year {}", month, year);
        
        List<EmployeeRanking> rankings = rankEmployeesByOverallScore(month, year);
        
        // Sort by attendance percentage descending
        rankings.sort(Comparator.comparing(EmployeeRanking::getAttendancePercentage).reversed());
        
        // Reassign ranks
        for (int i = 0; i < rankings.size(); i++) {
            rankings.get(i).setRank(i + 1);
        }
        
        return rankings;
    }

    public List<EmployeeRanking> rankEmployeesByPunctuality(Integer month, Integer year) {
        log.info("Ranking employees by punctuality for month {} year {}", month, year);
        
        List<EmployeeRanking> rankings = rankEmployeesByOverallScore(month, year);
        
        // Sort by punctuality percentage descending
        rankings.sort(Comparator.comparing(EmployeeRanking::getPunctualityPercentage).reversed());
        
        // Reassign ranks
        for (int i = 0; i < rankings.size(); i++) {
            rankings.get(i).setRank(i + 1);
        }
        
        return rankings;
    }

    public List<EmployeeRanking> rankEmployeesByWorkingHours(Integer month, Integer year) {
        log.info("Ranking employees by working hours for month {} year {}", month, year);
        
        List<EmployeeRanking> rankings = rankEmployeesByOverallScore(month, year);
        
        // Sort by total working hours descending
        rankings.sort(Comparator.comparing(EmployeeRanking::getTotalWorkingHours).reversed());
        
        // Reassign ranks
        for (int i = 0; i < rankings.size(); i++) {
            rankings.get(i).setRank(i + 1);
        }
        
        return rankings;
    }

    public List<EmployeeRanking> getTopPerformers(Integer month, Integer year, int limit) {
        log.info("Getting top {} performers for month {} year {}", limit, month, year);
        
        List<EmployeeRanking> rankings = rankEmployeesByOverallScore(month, year);
        
        return rankings.stream()
                .limit(limit)
                .collect(Collectors.toList());
    }

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class EmployeeRanking {
        private Integer rank;
        private Long employeeId;
        private String employeeName;
        private EmployeeScoreEngine.EmployeeScore score;
        
        // Convenience methods
        public Double getOverallScore() {
            return score != null ? score.getOverallScore() : 0.0;
        }
        
        public Double getAttendancePercentage() {
            return score != null ? score.getAttendancePercentage() : 0.0;
        }
        
        public Double getPunctualityPercentage() {
            return score != null ? score.getPunctualityPercentage() : 0.0;
        }
        
        public Double getTotalWorkingHours() {
            return score != null ? score.getTotalWorkingHours() : 0.0;
        }
    }
}
