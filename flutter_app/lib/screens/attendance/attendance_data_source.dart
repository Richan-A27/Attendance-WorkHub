import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../models/attendance_log.dart';
import '../../models/employee.dart';
import '../../theme/app_theme.dart';

class AttendanceDataSource extends DataGridSource {
  AttendanceDataSource(
      {required List<AttendanceLog> logs, required List<Employee> employees}) {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

    _logData = logs.map<DataGridRow>((e) {
      final punchTime = DateTime.tryParse(e.punchTime);
      final formattedTime =
          punchTime != null ? dateFormat.format(punchTime) : e.punchTime;

      final employee = employees
          .where((emp) => emp.id == e.employeeId)
          .firstOrNull;
      final displayName = employee != null
          ? "${employee.name} (ID: ${e.employeeId})"
          : "Unknown (ID: ${e.employeeId})";

      return DataGridRow(cells: [
        DataGridCell<int>(columnName: 'id', value: e.id),
        DataGridCell<String>(columnName: 'employeeName', value: displayName),
        DataGridCell<String>(columnName: 'punchTime', value: formattedTime),
        DataGridCell<String>(
            columnName: 'verifyMode', value: e.verifyMode ?? '-'),
        DataGridCell<String>(columnName: 'status', value: e.status ?? '-'),
      ]);
    }).toList();
  }

  List<DataGridRow> _logData = [];

  @override
  List<DataGridRow> get rows => _logData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = rows.indexOf(row);
    final alternate = index.isEven;

    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        if (e.columnName == 'employeeName') {
          final displayName = e.value.toString();
          return Container(
            alignment: Alignment.centerLeft,
            color: alternate ? Colors.white : const Color(0xFFFBF7EF),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.sage,
                  child: Text(
                    displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      color: AppTheme.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        if (e.columnName == 'status') {
          final status = e.value.toString();
          final normalized = status.toLowerCase();
          final color =
              normalized == 'ok' || normalized == 'present' || status == '-'
                  ? AppTheme.primaryGreen
                  : const Color(0xFFC45B4A);
          return Container(
            alignment: Alignment.centerLeft,
            color: alternate ? Colors.white : const Color(0xFFFBF7EF),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                status == '-' ? 'Normal' : status,
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ),
          );
        }

        if (e.columnName == 'verifyMode') {
          return Container(
            alignment: Alignment.centerLeft,
            color: alternate ? Colors.white : const Color(0xFFFBF7EF),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              e.value.toString(),
              style: const TextStyle(
                color: AppTheme.mutedText,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return Container(
          alignment: Alignment.centerLeft,
          color: alternate ? Colors.white : const Color(0xFFFBF7EF),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            e.value.toString(),
            style: const TextStyle(
              color: AppTheme.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
