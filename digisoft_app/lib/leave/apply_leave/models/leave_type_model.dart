class LeaveType {
  final int leaveTypeID;
  final String typeName;
  final int companyID;
  final String description;
  final double maxDaysPerYear;
  final bool isActive;
  final bool isDeleted;
  final String createdBy;
  final String? updatedBy;
  final DateTime createdOn;
  final DateTime? deletedOn;
  final DateTime? updatedOn;

  LeaveType({
    required this.leaveTypeID,
    required this.typeName,
    required this.companyID,
    required this.description,
    required this.maxDaysPerYear,
    required this.isActive,
    required this.isDeleted,
    required this.createdBy,
    this.updatedBy,
    required this.createdOn,
    this.deletedOn,
    this.updatedOn,
  });

  factory LeaveType.fromJson(Map<String, dynamic> json) {
    return LeaveType(
      leaveTypeID: json['leaveTypeID'],
      typeName: json['typeName'],
      companyID: json['companyID'],
      description: json['description'],
      maxDaysPerYear: json['maxDaysPerYear']?.toDouble() ?? 0.0,
      isActive: json['isActive'],
      isDeleted: json['isDeleted'],
      createdBy: json['createdBy'],
      updatedBy: json['updatedBy'],
      createdOn: DateTime.parse(json['createdOn']),
      deletedOn: json['deletedOn'] != null ? DateTime.parse(json['deletedOn']) : null,
      updatedOn: json['updatedOn'] != null ? DateTime.parse(json['updatedOn']) : null,
    );
  }
}