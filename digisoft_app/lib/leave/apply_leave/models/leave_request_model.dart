class LeaveRequestModel {
  final int leaveTypeID;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;
  final int companyID;
  final int totalDays;
  final String requestDate;
  final String duration;
  final int employeeID;
  final String createdBy;
  final String companyName;

  LeaveRequestModel({
    required this.leaveTypeID,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.status = 'Pending',
    required this.companyID,
    required this.totalDays,
    required this.requestDate,
    required this.duration,
    required this.employeeID,
    required this.createdBy,
    required this.companyName,
  });

  Map<String, String> toFormData() {
    return {
      'leaveTypeID': leaveTypeID.toString(),
      'fromDate': fromDate,
      'toDate': toDate,
      'reason': reason,
      'status': status,
      'companyID': companyID.toString(),
      'totalDays': totalDays.toString(),
      'requestDate': requestDate,
      'duration': duration,
      'employeeID': employeeID.toString(),
      'createdBy': createdBy,
      'CompanyName': companyName,
    };
  }
}
