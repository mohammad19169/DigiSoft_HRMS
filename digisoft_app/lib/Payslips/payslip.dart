import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:digisoft_app/services/payslip_service.dart';

class PayslipScreen extends StatefulWidget {
  @override
  _PayslipScreenState createState() => _PayslipScreenState();
}

class _PayslipScreenState extends State<PayslipScreen> {
  List<SalarySlip> _allSalarySlips = [];
  List<SalarySlip> _filteredSalarySlips = [];
  bool _isLoading = false;
  String _error = '';
  Map<int, bool> _generatingPayslips = {};
  
  // Filter properties
  int? _selectedYear;
  int? _selectedMonth;
  String _selectedStatus = 'All';
  
  final List<int> _years = [2025, 2024, 2023];
  final Map<int, String> _months = {
    1: 'January', 2: 'February', 3: 'March', 4: 'April',
    5: 'May', 6: 'June', 7: 'July', 8: 'August',
    9: 'September', 10: 'October', 11: 'November', 12: 'December'
  };
  final List<String> _statuses = ['All', 'Paid', 'Pending', 'Draft'];

  @override
  void initState() {
    super.initState();
    _loadSalarySlips();
  }

  Future<void> _loadSalarySlips() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await SalarySlipService.getSalarySlip();
      setState(() {
        _allSalarySlips = response.data;
        _filteredSalarySlips = _allSalarySlips;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredSalarySlips = _allSalarySlips.where((slip) {
        bool yearMatch = _selectedYear == null || slip.payrollYear == _selectedYear;
        bool monthMatch = _selectedMonth == null || slip.payrollMonth == _selectedMonth;
        bool statusMatch = _selectedStatus == 'All' || slip.payrollStatus == _selectedStatus;
        
        return yearMatch && monthMatch && statusMatch;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedYear = null;
      _selectedMonth = null;
      _selectedStatus = 'All';
      _filteredSalarySlips = _allSalarySlips;
    });
  }

  Future<void> _generateAndSharePayslip(SalarySlip salarySlip) async {
    setState(() {
      _generatingPayslips[salarySlip.payrollID] = true;
    });

    try {
      await SalarySlipService.generateAndSharePayslip(salarySlip);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payslip ready! Choose an app to open or share.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate payslip: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        _generatingPayslips.remove(salarySlip.payrollID);
      });
    }
  }

  Widget _buildFilterSection() {
    return Card(
      margin: EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  'Filters',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Year and Month Dropdowns
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedYear,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Years', style: TextStyle(color: Colors.grey[600])),
                      ),
                      ..._years.map((year) => DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedYear = value);
                    },
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<int?>(
                    value: _selectedMonth,
                    decoration: InputDecoration(
                      labelText: 'Month',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    items: [
                      DropdownMenuItem(
                        value: null,
                        child: Text('All Months', style: TextStyle(color: Colors.grey[600])),
                      ),
                      ..._months.entries.map((entry) => DropdownMenuItem(
                            value: entry.key,
                            child: Text(entry.value),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedMonth = value);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Status Dropdown
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                labelText: 'Status',
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              items: _statuses.map((status) => DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  )).toList(),
              onChanged: (value) {
                setState(() => _selectedStatus = value!);
              },
            ),
            SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _applyFilters,
                      icon: Icon(Icons.search, size: 20),
                      label: Text('Apply Filters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: _clearFilters,
                      icon: Icon(Icons.clear, size: 20),
                      label: Text('Clear'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        side: BorderSide(color: Colors.grey[400]!),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPayslipCard(SalarySlip salarySlip) {
    bool isGenerating = _generatingPayslips[salarySlip.payrollID] == true;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salarySlip.formattedPeriod,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[800],
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        '${salarySlip.employeeCode} - ${salarySlip.fullName}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(salarySlip.payrollStatus),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    salarySlip.payrollStatus,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Department and Designation
            Row(
              children: [
                _buildInfoItem(Icons.business_center, salarySlip.departmentName),
                Spacer(),
                _buildInfoItem(Icons.work, salarySlip.designationName),
              ],
            ),
            
            SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[300]),
            SizedBox(height: 16),
            
            // Salary Summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSalaryItem(
                  'Gross Salary',
                  salarySlip.totalAllowances,
                  Colors.green[700]!,
                ),
                _buildSalaryItem(
                  'Deductions',
                  salarySlip.totalDeductions,
                  Colors.red[700]!,
                ),
                _buildSalaryItem(
                  'Net Salary',
                  salarySlip.netSalary,
                  Colors.blue[800]!,
                  isNet: true,
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: isGenerating ? null : () => _generateAndSharePayslip(salarySlip),
                icon: isGenerating 
                    ? SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.picture_as_pdf, size: 22),
                label: isGenerating 
                    ? Text('Generating PDF...', style: TextStyle(fontSize: 16))
                    : Text('Download & Share PDF', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        SizedBox(width: 6),
        Container(
          constraints: BoxConstraints(maxWidth: 120),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSalaryItem(String label, double amount, Color color, {bool isNet = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6),
          Text(
            'PKR ${NumberFormat('#,##0').format(amount)}',
            style: TextStyle(
              fontSize: isNet ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'draft':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Payslips...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch your salary information',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Column(
      children: [
        // Debug Info Card
        Card(
          margin: EdgeInsets.all(16),
          color: Colors.orange[50],
          elevation: 2,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange[800]),
                    SizedBox(width: 8),
                    Text(
                      'Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  _error,
                  style: TextStyle(color: Colors.red[700]),
                ),
                SizedBox(height: 12),
                Text(
                  'Possible solutions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text('• Check your internet connection'),
                Text('• Ensure you are logged in'),
                Text('• Contact HR if issue persists'),
              ],
            ),
          ),
        ),
        
        // Main Error Content
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 80,
                    color: Colors.red[400],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Unable to Load Payslips',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  Text(
                    _error,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _loadSalarySlips,
                      icon: Icon(Icons.refresh),
                      label: Text('Try Again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: [
        _buildFilterSection(),
        Expanded(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'No Payslips Found',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _selectedYear != null || _selectedMonth != null || _selectedStatus != 'All'
                        ? 'Try adjusting your filters to see more results'
                        : 'No salary records available for your account',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 24),
                  if (_selectedYear != null || _selectedMonth != null || _selectedStatus != 'All')
                    SizedBox(
                      width: 200,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: _clearFilters,
                        child: Text('Clear Filters'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[700]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessState() {
    return Column(
      children: [
        _buildFilterSection(),
        if (_filteredSalarySlips.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 18, color: Colors.green),
                SizedBox(width: 6),
                Text(
                  '${_filteredSalarySlips.length} payslip${_filteredSalarySlips.length > 1 ? 's' : ''} found',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredSalarySlips.length,
            itemBuilder: (context, index) {
              final salarySlip = _filteredSalarySlips[index];
              return _buildPayslipCard(salarySlip);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'My Payslips',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadSalarySlips,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : _error.isNotEmpty
              ? _buildErrorWidget()
              : _allSalarySlips.isEmpty
                  ? _buildEmptyState()
                  : _filteredSalarySlips.isEmpty
                      ? _buildEmptyState()
                      : _buildSuccessState(),
    );
  }
}