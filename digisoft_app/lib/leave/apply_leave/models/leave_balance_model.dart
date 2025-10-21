class LeaveBalance {
  final int employeeID;
  final int employeeTypeID;
  final int leaveTypeID;
  final int companyID;
  final int year;
  final double totalAllocatedLeave;
  final double totalConsumedLeave;
  final double balanceLeave;
  final String statusMessage;

  LeaveBalance({
    required this.employeeID,
    required this.employeeTypeID,
    required this.leaveTypeID,
    required this.companyID,
    required this.year,
    required this.totalAllocatedLeave,
    required this.totalConsumedLeave,
    required this.balanceLeave,
    required this.statusMessage,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    try {
      return LeaveBalance(
        employeeID: json['employeeID'] ?? 0,
        employeeTypeID: json['employeeTypeID'] ?? 0,
        leaveTypeID: json['leaveTypeID'] ?? 0,
        companyID: json['companyID'] ?? 0,
        year: json['year'] ?? DateTime.now().year,
        totalAllocatedLeave: (json['totalAllocatedLeave'] ?? 0.0).toDouble(),
        totalConsumedLeave: (json['totalConsumedLeave'] ?? 0.0).toDouble(),
        balanceLeave: (json['balanceLeave'] ?? 0.0).toDouble(),
        statusMessage: json['statusMessage'] ?? 'Balance information available',
      );
    } catch (e) {
      print('❌ Error parsing LeaveBalance: $e');
      print('📦 JSON data: $json');
      rethrow;
    }
  }

  // Helper method to check if balance is sufficient
  bool get hasSufficientBalance => balanceLeave > 0;
  
  // Helper method to get status message with emoji
  String get displayStatus {
    if (statusMessage.toLowerCase().contains('sufficient')) {
      return '✅ $statusMessage';
    } else if (statusMessage.toLowerCase().contains('insufficient')) {
      return '⚠️ $statusMessage';
    } else {
      return 'ℹ️ $statusMessage';
    }
  }
}