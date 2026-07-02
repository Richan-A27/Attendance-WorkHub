package com.isravel.workhub.export;

import com.isravel.workhub.auth.RequireRole;
import com.isravel.workhub.intelligence.DailyAttendance;
import com.isravel.workhub.intelligence.DailyAttendanceRepository;
import com.isravel.workhub.payroll.PayrollRecord;
import com.isravel.workhub.payroll.PayrollRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/export")
@RequiredArgsConstructor
public class ExportController {

    private final ExportService exportService;
    private final DailyAttendanceRepository dailyAttendanceRepository;
    private final PayrollRecordRepository payrollRecordRepository;

    // Daily Attendance Exports
    @GetMapping("/attendance/csv/{employeeId}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<byte[]> exportAttendanceCsv(
            @PathVariable Long employeeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) throws IOException {
        
        List<DailyAttendance> attendances = dailyAttendanceRepository
                .findByEmployeeIdAndAttendanceDateBetweenOrderByAttendanceDateDesc(
                        employeeId, startDate, endDate);
        
        byte[] csvData = exportService.exportDailyAttendanceToCsv(attendances);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv"));
        headers.setContentDispositionFormData("attachment", 
                "attendance_" + employeeId + "_" + startDate + "_to_" + endDate + ".csv");
        
        return ResponseEntity.ok()
                .headers(headers)
                .body(csvData);
    }

    @GetMapping("/attendance/excel/{employeeId}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<byte[]> exportAttendanceExcel(
            @PathVariable Long employeeId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) throws IOException {
        
        List<DailyAttendance> attendances = dailyAttendanceRepository
                .findByEmployeeIdAndAttendanceDateBetweenOrderByAttendanceDateDesc(
                        employeeId, startDate, endDate);
        
        byte[] excelData = exportService.exportDailyAttendanceToExcel(attendances);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
        headers.setContentDispositionFormData("attachment", 
                "attendance_" + employeeId + "_" + startDate + "_to_" + endDate + ".xlsx");
        
        return ResponseEntity.ok()
                .headers(headers)
                .body(excelData);
    }

    // Payroll Exports
    @GetMapping("/payroll/csv/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<byte[]> exportPayrollCsv(
            @PathVariable Integer month,
            @PathVariable Integer year) throws IOException {
        
        List<PayrollRecord> payrollRecords = payrollRecordRepository.findByMonthAndYear(month, year);
        byte[] csvData = exportService.exportPayrollToCsv(payrollRecords);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("text/csv"));
        headers.setContentDispositionFormData("attachment", 
                "payroll_" + month + "_" + year + ".csv");
        
        return ResponseEntity.ok()
                .headers(headers)
                .body(csvData);
    }

    @GetMapping("/payroll/excel/{month}/{year}")
    @RequireRole({"ADMIN", "MANAGER"})
    public ResponseEntity<byte[]> exportPayrollExcel(
            @PathVariable Integer month,
            @PathVariable Integer year) throws IOException {
        
        List<PayrollRecord> payrollRecords = payrollRecordRepository.findByMonthAndYear(month, year);
        byte[] excelData = exportService.exportPayrollToExcel(payrollRecords);
        
        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.parseMediaType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
        headers.setContentDispositionFormData("attachment", 
                "payroll_" + month + "_" + year + ".xlsx");
        
        return ResponseEntity.ok()
                .headers(headers)
                .body(excelData);
    }
}
