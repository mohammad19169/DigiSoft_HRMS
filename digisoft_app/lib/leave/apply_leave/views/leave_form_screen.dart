// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:digisoft_app/services/leave_service.dart';
// import 'package:digisoft_app/leave/apply_leave/models/leave_type_model.dart';
// import 'package:digisoft_app/leave/apply_leave/models/leave_balance_model.dart';
// import 'package:digisoft_app/leave/apply_leave/models/leave_request_model.dart';
// import 'package:digisoft_app/utils/constants.dart';

// class LeaveFormScreen extends StatefulWidget {
//   final LeaveType selectedLeaveType;
//   final LeaveBalance leaveBalance;

//   const LeaveFormScreen({
//     super.key,
//     required this.selectedLeaveType,
//     required this.leaveBalance,
//   });

//   @override
//   State<LeaveFormScreen> createState() => _LeaveFormScreenState();
// }

// class _LeaveFormScreenState extends State<LeaveFormScreen> {
//   final LeaveService _leaveService = LeaveService();
//   final _formKey = GlobalKey<FormState>();

//   DateTime? _fromDate;
//   DateTime? _toDate;
//   String _selectedDuration = 'Full Day';
//   final TextEditingController _reasonController = TextEditingController();
//   bool _isSubmitting = false;

//   double get _calculatedDays {
//     if (_fromDate == null || _toDate == null) return 0.0;
//     return _leaveService.calculateTotalDays(_fromDate!, _toDate!, _selectedDuration);
//   }

//   Future<void> _selectFromDate() async {
//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _fromDate ?? DateTime.now(),
//       firstDate: DateTime.now(),
//       lastDate: DateTime(DateTime.now().year + 1),
//     );
//     if (picked != null) {
//       setState(() {
//         _fromDate = picked;
//         if (_toDate != null && _toDate!.isBefore(_fromDate!)) {
//           _toDate = _fromDate;
//         }
//       });
//     }
//   }

//   Future<void> _selectToDate() async {
//     if (_fromDate == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please select from date first'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     final DateTime? picked = await showDatePicker(
//       context: context,
//       initialDate: _toDate ?? _fromDate!,
//       firstDate: _fromDate!,
//       lastDate: DateTime(DateTime.now().year + 1),
//     );
//     if (picked != null) {
//       setState(() {
//         _toDate = picked;
//       });
//     }
//   }

//   Future<void> _submitLeaveRequest() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_calculatedDays > widget.leaveBalance.balanceLeave) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Requested days ($_calculatedDays) exceed available balance (${widget.leaveBalance.balanceLeave})'),
//           backgroundColor: Colors.red,
//         ),
//       );
//       return;
//     }

//     setState(() => _isSubmitting = true);

//     try {
//       final prefs = await SharedPreferences.getInstance();
      
//       final leaveRequest = LeaveRequest(
//         leaveTypeID: widget.selectedLeaveType.leaveTypeID,
//         fromDate: DateFormat('yyyy-MM-dd').format(_fromDate!),
//         toDate: DateFormat('yyyy-MM-dd').format(_toDate!),
//         reason: _reasonController.text,
//         status: 'Pending',
//         companyID: prefs.getInt('companyID') ?? 0,
//         totalDays: _calculatedDays,
//         requestDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
//         duration: _selectedDuration,
//         employeeID: prefs.getInt('employeeID') ?? 0,
//         createdBy: prefs.getString('createdBy') ?? 'hrm',
//         companyName: prefs.getString('companyName') ?? 'MultiNet',
//       );

//       final response = await _leaveService.submitLeaveRequest(leaveRequest);

//       if (response['isSuccess'] == true) {
//         // Show success dialog with leave request ID
//         _showSuccessDialog(
//           message: response['message'] ?? 'Leave application submitted successfully!',
//           leaveRequestID: response['leaveRequestID'],
//         );
//       } else {
//         throw Exception(response['message'] ?? 'Failed to submit leave request');
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error: ${e.toString()}'),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 5),
//         ),
//       );
//     } finally {
//       setState(() => _isSubmitting = false);
//     }
//   }

//   void _showSuccessDialog({required String message, required int leaveRequestID}) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         title: Row(
//           children: [
//             Icon(Icons.check_circle, color: Colors.green),
//             const SizedBox(width: 8),
//             const Text('Success!'),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(message),
//             const SizedBox(height: 12),
//             Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.green[50],
//                 borderRadius: BorderRadius.circular(8),
//                 border: Border.all(color: Colors.green),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.confirmation_number, color: Colors.green[700]),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         const Text(
//                           'Leave Request ID',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                         ),
//                         Text(
//                           '#$leaveRequestID',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.green[700],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Your leave request has been submitted for approval.',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               // Navigate back to dashboard
//               Navigator.of(context).popUntil((route) => route.isFirst);
//             },
//             child: const Text('Back to Dashboard'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Go back to apply leave screen to submit another request
//               Navigator.of(context).pop();
//               Navigator.of(context).pop();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Colors.blue[800],
//             ),
//             child: const Text(
//               'Apply Another Leave',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Apply Leave - Form'),
//         backgroundColor: Colors.blue[800],
//         foregroundColor: Colors.white,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Leave Type Info
//               Card(
//                 child: Padding(
//                   padding: const EdgeInsets.all(12.0),
//                   child: Row(
//                     children: [
//                       Icon(Icons.beach_access, color: Colors.blue[700]),
//                       const SizedBox(width: 12),
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                               widget.selectedLeaveType.typeName,
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.bold,
//                                 fontSize: 16,
//                               ),
//                             ),
//                             Text(
//                               'Balance: ${widget.leaveBalance.balanceLeave} days',
//                               style: TextStyle(
//                                 color: Colors.green[700],
//                                 fontSize: 14,
//                               ),
//                             ),
//                             if (widget.selectedLeaveType.description.isNotEmpty)
//                               Padding(
//                                 padding: const EdgeInsets.only(top: 4.0),
//                                 child: Text(
//                                   widget.selectedLeaveType.description,
//                                   style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey[600],
//                                     fontStyle: FontStyle.italic,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                               ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 20),

//               // Date Selection
//               Row(
//                 children: [
//                   Expanded(
//                     child: InkWell(
//                       onTap: _selectFromDate,
//                       child: InputDecorator(
//                         decoration: const InputDecoration(
//                           labelText: 'From Date',
//                           border: OutlineInputBorder(),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               _fromDate != null
//                                   ? DateFormat('dd MMM yyyy').format(_fromDate!)
//                                   : 'Select date',
//                               style: TextStyle(
//                                 color: _fromDate != null ? Colors.black : Colors.grey,
//                               ),
//                             ),
//                             const Icon(Icons.calendar_today),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 16),
//                   Expanded(
//                     child: InkWell(
//                       onTap: _selectToDate,
//                       child: InputDecorator(
//                         decoration: const InputDecoration(
//                           labelText: 'To Date',
//                           border: OutlineInputBorder(),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               _toDate != null
//                                   ? DateFormat('dd MMM yyyy').format(_toDate!)
//                                   : 'Select date',
//                               style: TextStyle(
//                                 color: _toDate != null ? Colors.black : Colors.grey,
//                               ),
//                             ),
//                             const Icon(Icons.calendar_today),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),

//               // Duration Selection
//               DropdownButtonFormField<String>(
//                 value: _selectedDuration,
//                 decoration: const InputDecoration(
//                   labelText: 'Duration',
//                   border: OutlineInputBorder(),
//                 ),
//                 items: AppConstants.durationTypes.map((String duration) {
//                   return DropdownMenuItem<String>(
//                     value: duration,
//                     child: Text(duration),
//                   );
//                 }).toList(),
//                 onChanged: (String? newValue) {
//                   setState(() {
//                     _selectedDuration = newValue!;
//                   });
//                 },
//               ),
//               const SizedBox(height: 20),

//               // Total Days Calculation
//               if (_fromDate != null && _toDate != null)
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.blue[50],
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Total Leave Days:',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       Text(
//                         '$_calculatedDays days',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           color: Colors.blue[800],
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               const SizedBox(height: 20),

//               // Reason Field
//               TextFormField(
//                 controller: _reasonController,
//                 decoration: const InputDecoration(
//                   labelText: 'Reason for Leave',
//                   border: OutlineInputBorder(),
//                   alignLabelWithHint: true,
//                 ),
//                 maxLines: 4,
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Please enter a reason for leave';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 30),

//               // Submit Button
//               SizedBox(
//                 width: double.infinity,
//                 height: 50,
//                 child: ElevatedButton(
//                   onPressed: _isSubmitting ? null : _submitLeaveRequest,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Colors.blue[800],
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                   ),
//                   child: _isSubmitting
//                       ? const SizedBox(
//                           width: 24,
//                           height: 24,
//                           child: CircularProgressIndicator(
//                             valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                             strokeWidth: 3,
//                           ),
//                         )
//                       : const Text(
//                           'Submit Leave Application',
//                           style: TextStyle(
//                             fontSize: 16,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _reasonController.dispose();
//     super.dispose();
//   }
// }