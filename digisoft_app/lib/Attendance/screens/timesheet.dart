import 'package:digisoft_app/services/filter_attendance.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AttendanceFilterScreen extends StatefulWidget {
  const AttendanceFilterScreen({Key? key}) : super(key: key);

  @override
  State<AttendanceFilterScreen> createState() => _AttendanceFilterScreenState();
}

class _AttendanceFilterScreenState extends State<AttendanceFilterScreen> {
  final AttendanceFilterService _service = AttendanceFilterService();
  
  bool _isLoading = false;
  List<dynamic> _attendanceData = [];
  Map<String, dynamic>? _statistics;
  String? _errorMessage;
  
  DateTime? _fromDate;
  DateTime? _toDate;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  
  String _filterType = 'month'; // 'month', 'custom', 'today'

  @override
  void initState() {
    super.initState();
    _loadCurrentMonthAttendance();
  }

  Future<void> _loadCurrentMonthAttendance() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _service.getCurrentMonthAttendance();
    
    setState(() {
      _isLoading = false;
      if (result['success']) {
        _attendanceData = result['data'];
        _statistics = _service.calculateAttendanceStatistics(_attendanceData);
      } else {
        _errorMessage = result['message'];
        _showError(result['message']);
      }
    });
  }

  Future<void> _loadAttendanceByFilter() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    Map<String, dynamic> result;
    
    if (_filterType == 'today') {
      result = await _service.getTodayAttendance();
    } else if (_filterType == 'month') {
      result = await _service.getAttendanceForMonth(
        _selectedYear,
        _selectedMonth,
      );
    } else {
      if (_fromDate == null || _toDate == null) {
        _showError('Please select both dates');
        setState(() => _isLoading = false);
        return;
      }
      result = await _service.getAttendanceForDateRange(
        _fromDate!,
        _toDate!,
      );
    }
    
    setState(() {
      _isLoading = false;
      if (result['success']) {
        _attendanceData = result['data'];
        _statistics = _service.calculateAttendanceStatistics(_attendanceData);
      } else {
        _errorMessage = result['message'];
        _showError(result['message']);
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate 
          ? (_fromDate ?? DateTime.now()) 
          : (_toDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
    }
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).dividerColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'FILTER BY',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // Filter Type Selection
                  Row(
                    children: [
                      Expanded(
                        child: _FilterChip(
                          label: 'Today',
                          selected: _filterType == 'today',
                          onSelected: (selected) {
                            setModalState(() => _filterType = 'today');
                            setState(() => _filterType = 'today');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FilterChip(
                          label: 'Month',
                          selected: _filterType == 'month',
                          onSelected: (selected) {
                            setModalState(() => _filterType = 'month');
                            setState(() => _filterType = 'month');
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FilterChip(
                          label: 'Custom',
                          selected: _filterType == 'custom',
                          onSelected: (selected) {
                            setModalState(() => _filterType = 'custom');
                            setState(() => _filterType = 'custom');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Month Filter
                  if (_filterType == 'month') ...[
                    Text(
                      'YEAR',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [2023, 2024, 2025].map((year) {
                        return _FilterChip(
                          label: year.toString(),
                          selected: _selectedYear == year,
                          onSelected: (selected) {
                            setModalState(() => _selectedYear = year);
                            setState(() => _selectedYear = year);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'MONTH',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: List.generate(12, (index) {
                        final month = index + 1;
                        final monthName = DateFormat.MMMM().format(DateTime(2025, month));
                        return _FilterChip(
                          label: monthName,
                          selected: _selectedMonth == month,
                          onSelected: (selected) {
                            setModalState(() => _selectedMonth = month);
                            setState(() => _selectedMonth = month);
                          },
                        );
                      }),
                    ),
                  ],
                  
                  // Custom Date Range
                  if (_filterType == 'custom') ...[
                    Text(
                      'DATE RANGE',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(context, true),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _fromDate != null 
                                  ? DateFormat('dd MMM yyyy').format(_fromDate!)
                                  : 'From Date',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectDate(context, false),
                            icon: const Icon(Icons.calendar_today, size: 18),
                            label: Text(
                              _toDate != null 
                                  ? DateFormat('dd MMM yyyy').format(_toDate!)
                                  : 'To Date',
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  const SizedBox(height: 24),
                  
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _loadAttendanceByFilter();
                      },
                      child: const Text('Apply Filter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('TIMESHEET'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_outlined),
            onPressed: _showFilterBottomSheet,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAttendanceByFilter,
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Loading attendance data...',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          : _attendanceData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 80,
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Attendance Records',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 48),
                        child: Text(
                          _errorMessage ?? 'No records found for the selected period.\nTry adjusting your filters.',
                          style: theme.textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton.icon(
                        onPressed: _showFilterBottomSheet,
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Change Filter'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(200, 48),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: _loadCurrentMonthAttendance,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reload'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadAttendanceByFilter,
                  child: Column(
                    children: [
                      // Statistics Card
                      if (_statistics != null)
                        Container(
                          margin: const EdgeInsets.all(16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Attendance Summary',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '${_statistics!['totalDays']} Days',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _StatItem(
                                    icon: Icons.check_circle,
                                    label: 'Present',
                                    value: '${_statistics!['presentDays']}',
                                    color: Colors.green,
                                  ),
                                  _StatItem(
                                    icon: Icons.cancel,
                                    label: 'Absent',
                                    value: '${_statistics!['absentDays']}',
                                    color: Colors.red,
                                  ),
                                  _StatItem(
                                    icon: Icons.access_time,
                                    label: 'Half Days',
                                    value: '${_statistics!['halfDays']}',
                                    color: Colors.blue,
                                  ),
                                  _StatItem(
                                    icon: Icons.event_available,
                                    label: 'Leave',
                                    value: '${_statistics!['leaveDays']}',
                                    color: Colors.orange,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      
                      // Attendance List
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _attendanceData.length,
                          itemBuilder: (context, index) {
                            final record = _service.parseAttendanceRecord(_attendanceData[index]);
                            return _AttendanceCard(record: record);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Function(bool) onSelected;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      backgroundColor: theme.chipTheme.backgroundColor,
      selectedColor: theme.chipTheme.selectedColor,
      labelStyle: selected 
          ? theme.chipTheme.secondaryLabelStyle 
          : theme.chipTheme.labelStyle,
      padding: theme.chipTheme.padding,
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final Map<String, dynamic> record;

  const _AttendanceCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = DateTime.parse(record['attendanceDate']);
    final dayName = DateFormat.E().format(date);
    final dayNum = DateFormat.d().format(date);
    
    // Debug the record to see what values we have
    print('🎯 CARD DEBUG - Date: ${record['attendanceDate']}');
    print('   statusName: ${record['statusName']}');
    print('   isAbsent: ${record['isAbsent']}');
    print('   isOnLeave: ${record['isOnLeave']}');
    print('   isHalfDay: ${record['isHalfDay']}');
    print('   isLate: ${record['isLate']}');
    print('   actualStartTime: ${record['actualStartTime']}');
    
    Color statusColor = Colors.green;
    String statusText = 'Present';
    bool isLate = false;

    // Use statusName as the primary indicator since it's more reliable
    final statusName = (record['statusName'] ?? '').toString().toLowerCase();
    
    if (statusName.contains('absent') || record['isAbsent'] == true) {
      statusColor = Colors.red;
      statusText = 'Absent';
    } else if (statusName.contains('leave') || record['isOnLeave'] == true) {
      statusColor = Colors.orange;
      statusText = 'On Leave';
    } else if (statusName.contains('half') || record['isHalfDay'] == true) {
      statusColor = Colors.blue;
      statusText = 'Half Day';
    } else if (record['actualStartTime'] == null) {
      // If no check-in time and no specific status, assume absent
      statusColor = Colors.red;
      statusText = 'Absent';
    } else {
      // If we reach here, it's a present day
      statusColor = Colors.green;
      statusText = 'Present';
      
      // Check if it's late (but keep the green color)
      if (record['isLate'] == true || statusName.contains('late') || 
          (record['lateBy'] != null && record['lateBy'].toString().isNotEmpty)) {
        isLate = true;
        // Don't change the color to orange, keep it green but we'll show "Late" text
      }
    }
    
    // Create status dot
    final statusDot = Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
      ),
    );

    print('   → Final Status: $statusText, Color: $statusColor, Is Late: $isLate');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Date
            Column(
              children: [
                Text(
                  dayName,
                  style: theme.textTheme.bodyMedium,
                ),
                Text(
                  dayNum,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                statusDot,
                const SizedBox(height: 2),
                Text(
                  isLate ? 'Late' : statusText, // Show "Late" instead of "Present" if late
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isLate ? Colors.orange : statusColor, // Late text in orange
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            
            // Time Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.login,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record['actualStartTime'] != null
                            ? DateFormat.jm().format(DateTime.parse(record['actualStartTime']))
                            : '-',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.logout,
                        size: 16,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        record['actualEndTime'] != null
                            ? DateFormat.jm().format(DateTime.parse(record['actualEndTime']))
                            : '-',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                  if (record['lateBy'] != null && record['lateBy'].toString().isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Late by: ${record['lateBy']}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Settings Icon
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: theme.iconTheme.color,
              ),
              onPressed: () {
                _showAttendanceDetails(context, record);
              },
            ),
          ],
        ),
      ),
    );
  }
  void _showAttendanceDetails(BuildContext context, Map<String, dynamic> record) {
    final theme = Theme.of(context);
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Attendance Details',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _DetailRow('Date', DateFormat('dd MMM yyyy').format(DateTime.parse(record['attendanceDate']))),
            _DetailRow('Employee', record['employeeName'] ?? '-'),
            _DetailRow('Department', record['departmentName'] ?? '-'),
            _DetailRow('Designation', record['designationName'] ?? '-'),
            _DetailRow('Shift', record['shiftName'] ?? '-'),
            _DetailRow('Status', record['statusName'] ?? '-'),
            const Divider(height: 24),
            _DetailRow('Check In', record['actualStartTime'] != null 
                ? DateFormat('hh:mm a').format(DateTime.parse(record['actualStartTime']))
                : '-'),
            _DetailRow('Check Out', record['actualEndTime'] != null 
                ? DateFormat('hh:mm a').format(DateTime.parse(record['actualEndTime']))
                : '-'),
            if (record['lateBy'] != null && record['lateBy'].toString().isNotEmpty)
              _DetailRow('Late By', record['lateBy']),
            if (record['checkInLocation'] != null && record['checkInLocation'].toString().isNotEmpty)
              _DetailRow('Location', record['checkInLocation']),
            if (record['attendanceSource'] != null && record['attendanceSource'].toString().isNotEmpty)
              _DetailRow('Source', record['attendanceSource']),
            if (record['remarks'] != null && record['remarks'].toString().isNotEmpty)
              _DetailRow('Remarks', record['remarks']),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}