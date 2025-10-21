// import 'package:flutter/material.dart';
// import 'package:digisoft_app/services/leave_service.dart';
// import 'package:digisoft_app/leave/apply_leave/models/leave_type_model.dart';
// import 'package:digisoft_app/leave/apply_leave/models/leave_balance_model.dart';
// import 'leave_form_screen.dart';

// class LeaveBalanceCheckScreen extends StatefulWidget {
//   final LeaveType selectedLeaveType;

//   const LeaveBalanceCheckScreen({
//     Key? key,
//     required this.selectedLeaveType,
//   }) : super(key: key);

//   @override
//   State<LeaveBalanceCheckScreen> createState() => _LeaveBalanceCheckScreenState();
// }

// class _LeaveBalanceCheckScreenState extends State<LeaveBalanceCheckScreen> {
//   final LeaveService _leaveService = LeaveService();
//   LeaveBalance? _leaveBalance;
//   bool _isLoading = true;
//   String _errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     _checkLeaveBalance();
//   }

//   Future<void> _checkLeaveBalance() async {
//     try {
//       print('🔄 Starting balance check for leaveTypeID: ${widget.selectedLeaveType.leaveTypeID}');
//       final balance = await _leaveService.checkLeaveBalance(widget.selectedLeaveType.leaveTypeID);
//       setState(() {
//         _leaveBalance = balance;
//         _isLoading = false;
//         _errorMessage = '';
//       });
//       print('✅ Balance check completed successfully');
//     } catch (e) {
//       print('❌ Balance check error: $e');
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   void _proceedToForm() {
//     if (_leaveBalance != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => LeaveFormScreen(
//             selectedLeaveType: widget.selectedLeaveType,
//             leaveBalance: _leaveBalance!,
//           ),
//         ),
//       );
//     }
//   }

//   bool get _canProceedToForm {
//     if (_leaveBalance == null) return false;
//     return true;
//   }

//   String get _proceedButtonText {
//     if (_leaveBalance == null) return 'Cannot Proceed';
    
//     if (_leaveBalance!.balanceLeave <= 0) {
//       return 'Proceed with No Balance';
//     } else if (_leaveBalance!.balanceLeave < 1) {
//       return 'Proceed with Low Balance';
//     } else {
//       return 'Continue to Apply Leave';
//     }
//   }

//   Color get _proceedButtonColor {
//     if (_leaveBalance == null) return Colors.grey;
    
//     if (_leaveBalance!.balanceLeave <= 0) {
//       return Colors.orange;
//     } else if (_leaveBalance!.balanceLeave < 1) {
//       return Colors.amber;
//     } else {
//       return Colors.blue[800]!;
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Leave Balance Check'),
//         backgroundColor: Colors.blue[800],
//         foregroundColor: Colors.white,
//       ),
//       body: _isLoading
//           ? const Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   CircularProgressIndicator(),
//                   SizedBox(height: 16),
//                   Text('Checking leave balance...'),
//                 ],
//               ),
//             )
//           : _errorMessage.isNotEmpty
//               ? Center(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.all(20.0),
//                     child: Column(
//                       mainAxisAlignment: MainAxisAlignment.center,
//                       children: [
//                         Icon(
//                           Icons.error_outline,
//                           size: 64,
//                           color: Colors.red[700],
//                         ),
//                         const SizedBox(height: 16),
//                         Text(
//                           'Balance Check Failed',
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.red[700],
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         Text(
//                           _errorMessage,
//                           textAlign: TextAlign.center,
//                           style: const TextStyle(
//                             color: Colors.grey,
//                             fontSize: 14,
//                           ),
//                         ),
//                         const SizedBox(height: 24),
//                         Wrap(
//                           spacing: 16,
//                           runSpacing: 16,
//                           children: [
//                             ElevatedButton(
//                               onPressed: _checkLeaveBalance,
//                               style: ElevatedButton.styleFrom(
//                                 backgroundColor: Colors.blue[800],
//                               ),
//                               child: const Text(
//                                 'Try Again',
//                                 style: TextStyle(color: Colors.white),
//                               ),
//                             ),
//                             OutlinedButton(
//                               onPressed: () {
//                                 if (_leaveBalance == null) {
//                                   final defaultBalance = LeaveBalance(
//                                     employeeID: 0,
//                                     employeeTypeID: 0,
//                                     leaveTypeID: widget.selectedLeaveType.leaveTypeID,
//                                     companyID: 0,
//                                     year: DateTime.now().year,
//                                     totalAllocatedLeave: 0.0,
//                                     totalConsumedLeave: 0.0,
//                                     balanceLeave: 0.0,
//                                     statusMessage: 'Balance check failed, proceeding anyway',
//                                   );
//                                   setState(() {
//                                     _leaveBalance = defaultBalance;
//                                     _errorMessage = '';
//                                   });
//                                 }
//                               },
//                               child: const Text('Proceed Anyway'),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ),
//                 )
//               : SingleChildScrollView( // Changed to SingleChildScrollView
//                   padding: const EdgeInsets.all(16.0),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Leave Type Info
//                       Card(
//                         elevation: 4,
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 widget.selectedLeaveType.typeName,
//                                 style: const TextStyle(
//                                   fontSize: 20,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 widget.selectedLeaveType.description,
//                                 style: TextStyle(
//                                   color: Colors.grey[600],
//                                   fontStyle: FontStyle.italic,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 'Max ${widget.selectedLeaveType.maxDaysPerYear} days per year',
//                                 style: TextStyle(
//                                   color: Colors.blue[700],
//                                   fontWeight: FontWeight.w500,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20),

//                       // Balance Information
//                       Card(
//                         elevation: 4,
//                         child: Padding(
//                           padding: const EdgeInsets.all(16.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               const Text(
//                                 'Leave Balance',
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 16),
//                               _buildBalanceInfo('Total Allocated', '${_leaveBalance!.totalAllocatedLeave} days'),
//                               _buildBalanceInfo('Total Consumed', '${_leaveBalance!.totalConsumedLeave} days'),
//                               _buildBalanceInfo('Balance Available', '${_leaveBalance!.balanceLeave} days', 
//                                 isBalance: true),
//                               const SizedBox(height: 16),
//                               Container(
//                                 padding: const EdgeInsets.all(12),
//                                 decoration: BoxDecoration(
//                                   color: _leaveBalance!.balanceLeave > 0 ? Colors.green[50] : Colors.orange[50],
//                                   borderRadius: BorderRadius.circular(8),
//                                   border: Border.all(
//                                     color: _leaveBalance!.balanceLeave > 0 ? Colors.green : Colors.orange,
//                                   ),
//                                 ),
//                                 child: Row(
//                                   children: [
//                                     Icon(
//                                       _leaveBalance!.balanceLeave > 0 ? Icons.check_circle : Icons.warning,
//                                       color: _leaveBalance!.balanceLeave > 0 ? Colors.green : Colors.orange,
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Expanded(
//                                       child: Text(
//                                         _leaveBalance!.statusMessage,
//                                         style: TextStyle(
//                                           fontWeight: FontWeight.bold,
//                                           color: _leaveBalance!.balanceLeave > 0 ? Colors.green[800] : Colors.orange[800],
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
                      
//                       // Button with proper spacing (REMOVED SPACER)
//                       const SizedBox(height: 32), // Added space instead of Spacer
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed: _canProceedToForm ? _proceedToForm : null,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: _canProceedToForm ? _proceedButtonColor : Colors.grey,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                           child: Text(
//                             _proceedButtonText,
//                             style: const TextStyle(
//                               fontSize: 16,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 20), // Extra bottom padding for safety
//                     ],
//                   ),
//                 ),
//     );
//   }

//   Widget _buildBalanceInfo(String label, String value, {bool isBalance = false}) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 6.0),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: TextStyle(
//               color: Colors.grey[700],
//               fontSize: 16,
//             ),
//           ),
//           Text(
//             value,
//             style: TextStyle(
//               fontWeight: FontWeight.bold,
//               fontSize: 16,
//               color: isBalance 
//                   ? (_leaveBalance!.balanceLeave > 0 ? Colors.green[700] : Colors.orange[700])
//                   : Colors.black,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }