package com.isravel.workhub.schedule;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface HolidayRepository extends JpaRepository<Holiday, Long> {

    Optional<Holiday> findByHolidayDate(LocalDate holidayDate);

    @Query("SELECT h FROM Holiday h WHERE h.holidayDate = :date OR (h.isRecurring = true AND EXTRACT(MONTH FROM h.holidayDate) = EXTRACT(MONTH FROM CAST(:date as date)) AND EXTRACT(DAY FROM h.holidayDate) = EXTRACT(DAY FROM CAST(:date as date)))")
    Optional<Holiday> findHolidayForDate(@Param("date") LocalDate date);

    List<Holiday> findByHolidayDateBetween(LocalDate startDate, LocalDate endDate);

    @Query("SELECT h FROM Holiday h WHERE h.holidayDate >= :startDate AND h.holidayDate <= :endDate ORDER BY h.holidayDate")
    List<Holiday> findHolidaysInPeriod(@Param("startDate") LocalDate startDate, @Param("endDate") LocalDate endDate);
}
