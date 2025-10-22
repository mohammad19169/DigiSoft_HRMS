import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:digisoft_app/services/leave_service.dart';
import 'package:digisoft_app/leave/apply_leave/models/leave_type_model.dart';
import 'package:digisoft_app/leave/apply_leave/models/leave_balance_model.dart';
import 'package:digisoft_app/leave/apply_leave/models/leave_request_model.dart';
import 'package:digisoft_app/utils/constants.dart';
import 'package:digisoft_app/utils/theme_provider.dart';

class ApplyLeaveScreen extends StatefulWidget {
  const ApplyLeaveScreen({super.key});

  @override
  State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
}

class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
  final LeaveService _leaveService = LeaveService();
  final _formKey = GlobalKey<FormState>();

  // State variables
  List<LeaveType> _leaveTypes = [];
  List<LeaveBalance> _leaveBalances = [];
  LeaveType? _selectedLeaveType;
  LeaveBalance? _selectedLeaveBalance;
  
  DateTime? _fromDate;
  DateTime? _toDate;
  String _selectedDuration = 'Full Day';
  String? _selectedReason;
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = true;
  bool _isSubmitting = false;
  int _selectedYear = DateTime.now().year;

  final List<String> _predefinedReasons = [
    'Personal Work',
    'Medical Emergency',
    'Family Function',
    'Vacation',
    'Other',
  ];

  double get _calculatedDays {
    if (_fromDate == null || _toDate == null) return 0.0;
    return _leaveService.calculateTotalDays(_fromDate!, _toDate!, _selectedDuration);
  }

  @override
  void initState() {
    super.initState();
    _loadLeaveData();
  }

  Future<void> _loadLeaveData() async {
    try {
      setState(() => _isLoading = true);
      
      final prefs = await SharedPreferences.getInstance();
      final employeeID = prefs.getInt('employeeID') ?? 0;
      final companyID = prefs.getInt('companyID') ?? 0;

      final leaveTypes = await _leaveService.getLeaveTypes();
      
      final List<LeaveBalance> leaveBalances = [];
      for (final leaveType in leaveTypes) {
        try {
          final balance = await _leaveService.checkLeaveBalance(leaveType.leaveTypeID);
          leaveBalances.add(balance);
        } catch (e) {
          leaveBalances.add(LeaveBalance(
            employeeID: employeeID,
            employeeTypeID: 0,
            leaveTypeID: leaveType.leaveTypeID,
            companyID: companyID,
            year: _selectedYear,
            totalAllocatedLeave: leaveType.maxDaysPerYear,
            totalConsumedLeave: 0,
            balanceLeave: leaveType.maxDaysPerYear,
            statusMessage: 'Balance information not available',
          ));
        }
      }

      setState(() {
        _leaveTypes = leaveTypes;
        _leaveBalances = leaveBalances;
        if (_leaveTypes.isNotEmpty) {
          _selectedLeaveType = _leaveTypes.first;
          _selectedLeaveBalance = _getBalanceForSelectedType();
        }
      });
    } catch (e) {
      _showErrorSnackBar('Error loading leave data: ${e.toString()}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  LeaveBalance? _getBalanceForSelectedType() {
    if (_selectedLeaveType == null) return null;
    
    final existingBalance = _leaveBalances.firstWhere(
      (balance) => balance.leaveTypeID == _selectedLeaveType!.leaveTypeID,
      orElse: () => LeaveBalance(
        employeeID: 0,
        employeeTypeID: 0,
        leaveTypeID: _selectedLeaveType!.leaveTypeID,
        companyID: 0,
        year: _selectedYear,
        totalAllocatedLeave: _selectedLeaveType!.maxDaysPerYear,
        totalConsumedLeave: 0,
        balanceLeave: _selectedLeaveType!.maxDaysPerYear,
        statusMessage: 'Default balance',
      ),
    );
    
    return existingBalance;
  }

  Future<void> _selectFromDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked;
        if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
          _toDate = _fromDate;
        }
      });
    }
  }

  Future<void> _selectToDate() async {
    if (_fromDate == null) {
      _showWarningSnackBar('Please select from date first');
      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _toDate ?? _fromDate!,
      firstDate: _fromDate!,
      lastDate: DateTime(DateTime.now().year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _toDate = picked;
      });
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedLeaveType == null) {
      _showErrorSnackBar('Please select a leave type');
      return;
    }

    if (_fromDate == null || _toDate == null) {
      _showErrorSnackBar('Please select both from and to dates');
      return;
    }

    if (_selectedReason == null) {
      _showErrorSnackBar('Please select a reason for leave');
      return;
    }

    final availableBalance = _selectedLeaveBalance?.balanceLeave ?? 0;
    if (_calculatedDays > availableBalance) {
      _showErrorSnackBar('Requested days (${_calculatedDays.toStringAsFixed(1)}) exceed available balance (${availableBalance.toStringAsFixed(1)})');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      
      final leaveRequest = LeaveRequest(
        leaveTypeID: _selectedLeaveType!.leaveTypeID,
        fromDate: DateFormat('yyyy-MM-dd').format(_fromDate!),
        toDate: DateFormat('yyyy-MM-dd').format(_toDate!),
        reason: _selectedReason == 'Other' ? _reasonController.text.trim() : _selectedReason!,
        status: 'Pending',
        companyID: prefs.getInt('companyID') ?? 0,
        totalDays: _calculatedDays,
        requestDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        duration: _selectedDuration,
        employeeID: prefs.getInt('employeeID') ?? 0,
        createdBy: prefs.getString('createdBy') ?? 'hrm',
        companyName: prefs.getString('companyName') ?? 'MultiNet',
      );

      final response = await _leaveService.submitLeaveRequest(leaveRequest);

      if (response['isSuccess'] == true) {
        _showSuccessDialog(
          message: response['message'] ?? 'Leave application submitted successfully!',
         // leaveRequestID: response['leaveRequestID'],
        );
      } else {
        throw Exception(response['message'] ?? 'Failed to submit leave request');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog({required String message}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('Success!', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Text('Back to Dashboard', style: Theme.of(context).textTheme.labelLarge),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resetForm();
            },
            child: Text('Apply Another Leave', style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            )),
          ),
        ],
      ),
    );
  }

  void _resetForm() {
    setState(() {
      _fromDate = null;
      _toDate = null;
      _selectedReason = null;
      _reasonController.clear();
      _selectedDuration = 'Full Day';
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showWarningSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.primary,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'APPLY LEAVE',
          style: TextStyle(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.primary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.onPrimary))
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  // Year Section
                  _buildYearSection(colorScheme),
                  
                  // Scrollable Content
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Leave Type Section
                              _buildLeaveTypeSection(colorScheme),
                              const SizedBox(height: 20),
                              
                              // Leave Balance Info
                              if (_selectedLeaveBalance != null) 
                                _buildBalanceSection(colorScheme),
                              const SizedBox(height: 20),
                              
                              // Reason Dropdown
                              _buildReasonSection(colorScheme),
                              const SizedBox(height: 20),
                              
                              // Date and Duration Section
                              _buildDateDurationSection(colorScheme),
                              const SizedBox(height: 20),
                              
                              // Attach Documents Section
                              // _buildAttachDocumentsSection(colorScheme),
                              // const SizedBox(height: 20),
                              
                              // Attachments Section
                              // _buildAttachmentsSection(colorScheme),
                              // const SizedBox(height: 20),
                              
                              // Comment Section (if reason is Other)
                              if (_selectedReason == 'Other')
                                _buildCommentSection(colorScheme),
                              
                              const SizedBox(height: 30),
                              
                              // Submit Button
                              _buildSubmitButton(colorScheme),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildYearSection(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Column(
        children: [
          Text(
            'YEAR',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: colorScheme.onPrimary, size: 30),
                onPressed: () {
                  setState(() {
                    _selectedYear--;
                    _loadLeaveData();
                  });
                },
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  '$_selectedYear',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: colorScheme.onPrimary, size: 30),
                onPressed: () {
                  setState(() {
                    _selectedYear++;
                    _loadLeaveData();
                  });
                },
              ),
            ],
          ),
          Container(
            width: 200,
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colorScheme.onPrimary.withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveTypeSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.amber,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              'LEAVE TYPE',
              style: TextStyle(
                color: colorScheme.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _leaveTypes
                .where((type) => type.isActive && !type.isDeleted)
                .map((leaveType) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _buildLeaveTypeChip(leaveType, colorScheme),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLeaveTypeChip(LeaveType leaveType, ColorScheme colorScheme) {
    final isSelected = _selectedLeaveType?.leaveTypeID == leaveType.leaveTypeID;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedLeaveType = leaveType;
          _selectedLeaveBalance = _getBalanceForSelectedType();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.deepOrange : colorScheme.surface,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.deepOrange : colorScheme.outline,
            width: 2,
          ),
        ),
        child: Text(
          leaveType.typeName,
          style: TextStyle(
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBalanceSection(ColorScheme colorScheme) {
    final balance = _selectedLeaveBalance!;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBalanceItem(
            'Leave Balance',
            '${balance.balanceLeave.toInt()}/${balance.totalAllocatedLeave.toInt()}',
            colorScheme,
          ),
         // Container(width: 1, height: 50, color: Colors.amber),
          // _buildBalanceItem(
          //   'Last Leave Taken',
          //   '-',
          //   colorScheme,
          // ),
          Container(width: 1, height: 50, color: Colors.amber),
          _buildBalanceItem(
            'Leave Pending',
            '0/${balance.totalAllocatedLeave.toInt()}',
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceItem(String label, String value, ColorScheme colorScheme) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildReasonSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Reason',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedReason,
              hint: Text('Select', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.5))),
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.onSurface),
              items: _predefinedReasons.map((String reason) {
                return DropdownMenuItem<String>(
                  value: reason,
                  child: Text(reason),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedReason = newValue;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDateDurationSection(ColorScheme colorScheme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'From',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _selectFromDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _fromDate != null
                                ? DateFormat('MMM dd').format(_fromDate!)
                                : 'Oct 15',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Icon(Icons.edit, size: 16, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedDuration,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => _showDurationPicker(colorScheme),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDuration,
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Icon(Icons.edit, size: 16, color: Colors.deepOrange),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: _selectToDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                      decoration: BoxDecoration(
                        border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _toDate != null
                                ? DateFormat('MMM dd').format(_toDate!)
                                : 'Oct 15',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          Icon(Icons.edit, size: 16, color: colorScheme.primary),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Text(
                      'No Of Days',
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _calculatedDays.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDurationPicker(ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppConstants.durationTypes.map((duration) {
            return ListTile(
              title: Text(duration),
              trailing: _selectedDuration == duration
                  ? Icon(Icons.check, color: colorScheme.primary)
                  : null,
              onTap: () {
                setState(() {
                  _selectedDuration = duration;
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildAttachButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(icon, size: 50, color: color),
            Positioned(
              right: -5,
              bottom: -5,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentSection(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Comment',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _reasonController,
          decoration: InputDecoration(
            hintText: 'Enter additional details...',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colorScheme.outline),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          maxLines: 4,
          validator: (value) {
            if (_selectedReason == 'Other' && (value == null || value.trim().isEmpty)) {
              return 'Please provide additional details';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton(ColorScheme colorScheme) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitLeaveRequest,
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(colorScheme.onPrimary),
                  strokeWidth: 3,
                ),
              )
            : Text(
                'SUBMIT',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}