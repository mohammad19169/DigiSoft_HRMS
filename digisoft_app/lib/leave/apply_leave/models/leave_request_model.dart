class LeaveRequest {
  final int leaveTypeID;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;
  final int companyID;
  final double totalDays;
  final String requestDate;
  final String duration;
  final int employeeID;
  final String createdBy;
  final String companyName;

  LeaveRequest({
    required this.leaveTypeID,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    required this.companyID,
    required this.totalDays,
    required this.requestDate,
    required this.duration,
    required this.employeeID,
    required this.createdBy,
    required this.companyName,
  });

  Map<String, dynamic> toJson() {
    return {
      'leaveTypeID': leaveTypeID,
      'fromDate': fromDate,
      'toDate': toDate,
      'reason': reason,
      'status': status,
      'companyID': companyID,
      'totalDays': totalDays,
      'requestDate': requestDate,
      'duration': duration,
      'employeeID': employeeID,
      'createdBy': createdBy,
      'CompanyName': companyName,
    };
  }
}