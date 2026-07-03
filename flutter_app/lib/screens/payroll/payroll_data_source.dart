import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../models/payroll_record.dart';
import '../../theme/app_theme.dart';

class PayrollDataSource extends DataGridSource {
  PayrollDataSource({required List<PayrollRecord> records}) {
    final currencyFormat = NumberFormat.currency(symbol: '₹');
    final hoursFormat = NumberFormat('0.00');

    _recordData = records
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<int>(columnName: 'employeeId', value: e.employeeId),
              DataGridCell<String>(
                  columnName: 'paidHours',
                  value: '${hoursFormat.format(e.paidHours)}h'),
              DataGridCell<String>(
                  columnName: 'regularHours',
                  value: '${hoursFormat.format(e.regularHours)}h'),
              DataGridCell<String>(
                  columnName: 'overtimeHours',
                  value: '${hoursFormat.format(e.overtimeHours)}h'),
              DataGridCell<String>(
                  columnName: 'breakHours',
                  value: '${hoursFormat.format(e.breakHours)}h'),
              DataGridCell<String>(
                  columnName: 'grossPay',
                  value: currencyFormat.format(e.grossPay)),
              DataGridCell<String>(
                  columnName: 'netPay', value: currencyFormat.format(e.netPay)),
              DataGridCell<String>(columnName: 'status', value: e.status),
            ]))
        .toList();
  }

  List<DataGridRow> _recordData = [];

  @override
  List<DataGridRow> get rows => _recordData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = rows.indexOf(row);
    final alternate = index.isEven;
    final bg = alternate ? Colors.white : const Color(0xFFFBF7EF);

    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        if (e.columnName == 'status') {
          final isPaid = e.value == 'PAID';
          return Container(
            alignment: Alignment.center,
            color: bg,
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: (isPaid ? AppTheme.primaryGreen : const Color(0xFFBF8A2A))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                e.value.toString(),
                style: TextStyle(
                  color: isPaid ? AppTheme.primaryGreen : const Color(0xFFBF8A2A),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }
        // Highlight paid hours column slightly
        final isPaidHours = e.columnName == 'paidHours';
        return Container(
          alignment: Alignment.centerLeft,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            e.value.toString(),
            style: TextStyle(
              color: isPaidHours ? AppTheme.primaryGreen : AppTheme.ink,
              fontWeight: isPaidHours ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }
}
