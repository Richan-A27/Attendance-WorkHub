package com.isravel.workhub.payroll;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PayrollRecordRepository extends JpaRepository<PayrollRecord, Long> {

    Optional<PayrollRecord> findByEmployeeIdAndMonthAndYear(Long employeeId, Integer month, Integer year);

    List<PayrollRecord> findByMonthAndYear(Integer month, Integer year);

    List<PayrollRecord> findByEmployeeId(Long employeeId);

    List<PayrollRecord> findByStatus(String status);

    @Query("SELECT pr FROM PayrollRecord pr WHERE pr.month = :month AND pr.year = :year ORDER BY pr.employeeId")
    List<PayrollRecord> findByMonthAndYearOrderByEmployee(@Param("month") Integer month, @Param("year") Integer year);

    @Query("SELECT COALESCE(SUM(pr.netPay), 0) FROM PayrollRecord pr WHERE pr.month = :month AND pr.year = :year")
    java.math.BigDecimal sumNetPayForMonth(@Param("month") Integer month, @Param("year") Integer year);

    @Query("SELECT COALESCE(SUM(pr.grossPay), 0) FROM PayrollRecord pr WHERE pr.month = :month AND pr.year = :year")
    java.math.BigDecimal sumGrossPayForMonth(@Param("month") Integer month, @Param("year") Integer year);

    @Query("SELECT pr FROM PayrollRecord pr WHERE pr.employeeId = :employeeId ORDER BY pr.year DESC, pr.month DESC")
    List<PayrollRecord> findEmployeePayrollHistory(@Param("employeeId") Long employeeId);
}
