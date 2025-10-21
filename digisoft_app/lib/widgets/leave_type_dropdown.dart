import 'package:flutter/material.dart';
import '../leave/apply_leave/models/leave_type_model.dart';

class LeaveTypeDropdown extends StatelessWidget {
  final List<LeaveType> leaveTypes;
  final LeaveType? selectedLeaveType;
  final ValueChanged<LeaveType?> onChanged;
  final String? errorText;

  const LeaveTypeDropdown({
    super.key,
    required this.leaveTypes,
    required this.selectedLeaveType,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    final activeLeaveTypes = leaveTypes.where((type) => type.isActive).toList();

    return DropdownButtonFormField<LeaveType>(
      value: selectedLeaveType,
      decoration: InputDecoration(
        labelText: 'Leave Type',
        border: OutlineInputBorder(),
        errorText: errorText,
      ),
      items: activeLeaveTypes.map((LeaveType type) {
        return DropdownMenuItem<LeaveType>(
          value: type,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(type.typeName),
              Text(
                'Max ${type.maxDaysPerYear} days/year',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null) {
          return 'Please select a leave type';
        }
        return null;
      },
    );
  }
}