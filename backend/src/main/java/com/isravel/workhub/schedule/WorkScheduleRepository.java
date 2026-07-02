package com.isravel.workhub.schedule;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WorkScheduleRepository extends JpaRepository<WorkSchedule, Long> {

    List<WorkSchedule> findByEmployeeIdAndActive(Long employeeId, Boolean active);

    Optional<WorkSchedule> findByEmployeeIdAndActiveTrue(Long employeeId);

    @Query("SELECT ws FROM WorkSchedule ws WHERE ws.employeeId = :employeeId AND ws.active = true ORDER BY ws.updatedAt DESC")
    Optional<WorkSchedule> findActiveScheduleByEmployeeId(@Param("employeeId") Long employeeId);

    List<WorkSchedule> findByActiveTrue();
}
