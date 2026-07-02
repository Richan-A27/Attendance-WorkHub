package com.isravel.workhub.export;

import com.fasterxml.jackson.dataformat.csv.CsvMapper;
import com.fasterxml.jackson.dataformat.csv.CsvSchema;
import com.isravel.workhub.intelligence.DailyAttendance;
import com.isravel.workhub.payroll.PayrollRecord;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ExportService {

    private final CsvMapper csvMapper = new CsvMapper();

    // CSV Export Methods
    public byte[] exportDailyAttendanceToCsv(List<DailyAttendance> attendances) throws IOException {
        CsvSchema schema = csvMapper.schemaFor(DailyAttendance.class)
                .withHeader()
                .withColumnSeparator(',')
                .withQuoteChar('"');
        
        return csvMapper.writer(schema)
                .writeValueAsBytes(attendances);
    }

    public byte[] exportPayrollToCsv(List<PayrollRecord> payrollRecords) throws IOException {
        CsvSchema schema = csvMapper.schemaFor(PayrollRecord.class)
                .withHeader()
                .withColumnSeparator(',')
                .withQuoteChar('"');
        
        return csvMapper.writer(schema)
                .writeValueAsBytes(payrollRecords);
    }

    // Excel Export Methods
    public byte[] exportDailyAttendanceToExcel(List<DailyAttendance> attendances) throws IOException {
        try (Workbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            
            Sheet sheet = workbook.createSheet("Daily Attendance");
            
            // Create header row
            Row headerRow = sheet.createRow(0);
            String[] headers = {
                "Employee ID", "Date", "First Punch", "Last Punch",
                "Working Minutes", "Break Minutes", "Lunch Minutes",
                "Status", "Late", "Late Minutes", "Early Departure",
                "Early Departure Minutes", "Overtime Minutes"
            };
            
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                
                CellStyle headerStyle = workbook.createCellStyle();
                Font font = workbook.createFont();
                font.setBold(true);
                headerStyle.setFont(font);
                cell.setCellStyle(headerStyle);
            }
            
            // Create data rows
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
            int rowNum = 1;
            
            for (DailyAttendance attendance : attendances) {
                Row row = sheet.createRow(rowNum++);
                
                row.createCell(0).setCellValue(attendance.getEmployeeId());
                row.createCell(1).setCellValue(attendance.getAttendanceDate() != null ? 
                        attendance.getAttendanceDate().toString() : "");
                row.createCell(2).setCellValue(attendance.getFirstPunch() != null ? 
                        attendance.getFirstPunch().format(formatter) : "");
                row.createCell(3).setCellValue(attendance.getLastPunch() != null ? 
                        attendance.getLastPunch().format(formatter) : "");
                row.createCell(4).setCellValue(attendance.getTotalWorkingMinutes() != null ? 
                        attendance.getTotalWorkingMinutes() : 0);
                row.createCell(5).setCellValue(attendance.getBreakDurationMinutes() != null ? 
                        attendance.getBreakDurationMinutes() : 0);
                row.createCell(6).setCellValue(attendance.getLunchDurationMinutes() != null ? 
                        attendance.getLunchDurationMinutes() : 0);
                row.createCell(7).setCellValue(attendance.getStatus() != null ? 
                        attendance.getStatus() : "");
                row.createCell(8).setCellValue(attendance.getIsLate() != null ? 
                        attendance.getIsLate() : false);
                row.createCell(9).setCellValue(attendance.getLateMinutes() != null ? 
                        attendance.getLateMinutes() : 0);
                row.createCell(10).setCellValue(attendance.getIsEarlyDeparture() != null ? 
                        attendance.getIsEarlyDeparture() : false);
                row.createCell(11).setCellValue(attendance.getEarlyDepartureMinutes() != null ? 
                        attendance.getEarlyDepartureMinutes() : 0);
                row.createCell(12).setCellValue(attendance.getOvertimeMinutes() != null ? 
                        attendance.getOvertimeMinutes() : 0);
            }
            
            // Auto-size columns
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }
            
            workbook.write(out);
            return out.toByteArray();
        }
    }

    public byte[] exportPayrollToExcel(List<PayrollRecord> payrollRecords) throws IOException {
        try (Workbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            
            Sheet sheet = workbook.createSheet("Payroll Records");
            
            // Create header row
            Row headerRow = sheet.createRow(0);
            String[] headers = {
                "Employee ID", "Month", "Year", "Regular Hours", "Overtime Hours",
                "Hourly Rate", "Overtime Multiplier", "Gross Pay",
                "Deductions", "Bonuses", "Net Pay", "Status"
            };
            
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                
                CellStyle headerStyle = workbook.createCellStyle();
                Font font = workbook.createFont();
                font.setBold(true);
                headerStyle.setFont(font);
                cell.setCellStyle(headerStyle);
            }
            
            // Create data rows
            int rowNum = 1;
            
            for (PayrollRecord record : payrollRecords) {
                Row row = sheet.createRow(rowNum++);
                
                row.createCell(0).setCellValue(record.getEmployeeId());
                row.createCell(1).setCellValue(record.getMonth());
                row.createCell(2).setCellValue(record.getYear());
                row.createCell(3).setCellValue(record.getRegularHours() != null ? 
                        record.getRegularHours().doubleValue() : 0);
                row.createCell(4).setCellValue(record.getOvertimeHours() != null ? 
                        record.getOvertimeHours().doubleValue() : 0);
                row.createCell(5).setCellValue(record.getHourlyRate() != null ? 
                        record.getHourlyRate().doubleValue() : 0);
                row.createCell(6).setCellValue(record.getOvertimeMultiplier() != null ? 
                        record.getOvertimeMultiplier().doubleValue() : 0);
                row.createCell(7).setCellValue(record.getGrossPay() != null ? 
                        record.getGrossPay().doubleValue() : 0);
                row.createCell(8).setCellValue(record.getDeductions() != null ? 
                        record.getDeductions().doubleValue() : 0);
                row.createCell(9).setCellValue(record.getBonuses() != null ? 
                        record.getBonuses().doubleValue() : 0);
                row.createCell(10).setCellValue(record.getNetPay() != null ? 
                        record.getNetPay().doubleValue() : 0);
                row.createCell(11).setCellValue(record.getStatus() != null ? 
                        record.getStatus() : "");
            }
            
            // Auto-size columns
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }
            
            workbook.write(out);
            return out.toByteArray();
        }
    }

    // Generic Excel export for any data
    public byte[] exportToExcel(String sheetName, String[] headers, List<Object[]> data) throws IOException {
        try (Workbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream out = new ByteArrayOutputStream()) {
            
            Sheet sheet = workbook.createSheet(sheetName);
            
            // Create header row
            Row headerRow = sheet.createRow(0);
            CellStyle headerStyle = workbook.createCellStyle();
            Font font = workbook.createFont();
            font.setBold(true);
            headerStyle.setFont(font);
            
            for (int i = 0; i < headers.length; i++) {
                Cell cell = headerRow.createCell(i);
                cell.setCellValue(headers[i]);
                cell.setCellStyle(headerStyle);
            }
            
            // Create data rows
            int rowNum = 1;
            for (Object[] rowData : data) {
                Row row = sheet.createRow(rowNum++);
                for (int i = 0; i < rowData.length; i++) {
                    Cell cell = row.createCell(i);
                    if (rowData[i] != null) {
                        if (rowData[i] instanceof Number) {
                            cell.setCellValue(((Number) rowData[i]).doubleValue());
                        } else {
                            cell.setCellValue(rowData[i].toString());
                        }
                    }
                }
            }
            
            // Auto-size columns
            for (int i = 0; i < headers.length; i++) {
                sheet.autoSizeColumn(i);
            }
            
            workbook.write(out);
            return out.toByteArray();
        }
    }
}
