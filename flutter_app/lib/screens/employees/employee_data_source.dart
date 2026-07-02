import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datagrid/datagrid.dart';

import '../../models/employee.dart';
import '../../theme/app_theme.dart';

class EmployeeDataSource extends DataGridSource {
  EmployeeDataSource({required List<Employee> employeeData}) {
    _employeeData = employeeData
        .map<DataGridRow>((e) => DataGridRow(cells: [
              DataGridCell<int>(columnName: 'id', value: e.id),
              DataGridCell<String>(columnName: 'name', value: e.name),
              DataGridCell<double>(
                  columnName: 'hourlyRate', value: e.hourlyRate ?? 0.0),
              DataGridCell<bool>(columnName: 'active', value: e.active),
            ]))
        .toList();
  }

  List<DataGridRow> _employeeData = [];

  @override
  List<DataGridRow> get rows => _employeeData;

  @override
  DataGridRowAdapter buildRow(DataGridRow row) {
    final index = rows.indexOf(row);
    final alternate = index.isEven;

    return DataGridRowAdapter(
      cells: row.getCells().map<Widget>((e) {
        if (e.columnName == 'active') {
          final isActive = e.value == true;
          return Container(
            alignment: Alignment.center,
            color: alternate ? Colors.white : const Color(0xFFFBF7EF),
            padding: const EdgeInsets.all(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color:
                    (isActive ? AppTheme.primaryGreen : const Color(0xFFC45B4A))
                        .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  color: isActive
                      ? AppTheme.primaryGreen
                      : const Color(0xFFC45B4A),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }

        if (e.columnName == 'name') {
          final name = e.value.toString();
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
                    name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
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

        return Container(
          alignment: e.columnName == 'hourlyRate'
              ? Alignment.centerRight
              : Alignment.centerLeft,
          color: alternate ? Colors.white : const Color(0xFFFBF7EF),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            e.columnName == 'hourlyRate'
                ? '\$${(e.value as double).toStringAsFixed(2)}'
                : e.value.toString(),
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
