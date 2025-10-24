import 'package:flutter/material.dart';
import 'package:digisoft_app/services/cancel_leave.dart';
import 'package:intl/intl.dart';

class LeaveListScreen extends StatefulWidget {
  const LeaveListScreen({super.key});

  @override
  State<LeaveListScreen> createState() => _LeaveListScreenState();
}

class _LeaveListScreenState extends State<LeaveListScreen> {
  final LeaveService _service = LeaveService();
  
  bool _isLoading = false;
  List<dynamic> _leaveRequests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLeaveRequests();
  }

  Future<void> _loadLeaveRequests() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    final result = await _service.getLeaveRequests();
    
    setState(() {
      _isLoading = false;
      if (result['success']) {
        _leaveRequests = result['data'];
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

  void _deleteLeaveRequest(int leaveRequestID) async {
    // Get employee code from stored data (you might need to store this during login)
    final updatedBy = "EMP00066"; // Replace with actual employee code from prefs
    
    final result = await _service.deleteLeaveRequest(
      leaveRequestID: leaveRequestID,
      updatedBy: updatedBy,
    );

    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );
      // Refresh the list
      _loadLeaveRequests();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteDialog(int leaveRequestID) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Leave Request'),
        content: const Text('Are you sure you want to cancel this leave request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteLeaveRequest(leaveRequestID);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Leave Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaveRequests,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.colorScheme.primary))
          : _leaveRequests.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.beach_access,
                        size: 80,
                        color: theme.colorScheme.primary.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No Leave Requests',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'You have no leave requests yet.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaveRequests,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _leaveRequests.length,
                    itemBuilder: (context, index) {
                      final leave = _service.parseLeaveRecord(_leaveRequests[index]);
                      return _LeaveCard(
                        leave: leave,
                        onDelete: () => _showDeleteDialog(leave['leaveRequestID']),
                      );
                    },
                  ),
                ),
    );
  }
}

class _LeaveCard extends StatelessWidget {
  final Map<String, dynamic> leave;
  final VoidCallback onDelete;

  const _LeaveCard({required this.leave, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    Color statusColor = Colors.grey;
    if (leave['status'] == 'Approved') statusColor = Colors.green;
    if (leave['status'] == 'Pending') statusColor = Colors.orange;
    if (leave['status'] == 'Rejected') statusColor = Colors.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leave['typeName'],
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatDate(leave['fromDate'])} - ${_formatDate(leave['toDate'])}',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${leave['totalDays']} day(s) • ${leave['duration']}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: statusColor),
                    ),
                    child: Text(
                      leave['status'],
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Show delete button only for pending leaves
            if (leave['status'] == 'Pending')
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }
}