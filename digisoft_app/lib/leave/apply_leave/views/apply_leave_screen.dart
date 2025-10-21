// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:digisoft_app/services/leave_service.dart';
// import 'package:digisoft_app/leave/apply_leave/models/leave_type_model.dart';
// import 'leave_balance_check_screen.dart';

// class ApplyLeaveScreen extends StatefulWidget {
//   const ApplyLeaveScreen({Key? key}) : super(key: key);

//   @override
//   State<ApplyLeaveScreen> createState() => _ApplyLeaveScreenState();
// }

// class _ApplyLeaveScreenState extends State<ApplyLeaveScreen> {
//   final LeaveService _leaveService = LeaveService();
//   List<LeaveType> _leaveTypes = [];
//   LeaveType? _selectedLeaveType;
//   bool _isLoading = true;
//   String _errorMessage = '';

//   @override
//   void initState() {
//     super.initState();
//     _loadLeaveTypes();
//     _checkStoredData();
//   }

//   Future<void> _checkStoredData() async {
//     final prefs = await SharedPreferences.getInstance();
//     print('🔍 STORED DATA CHECK:');
//     print('   EmployeeID: ${prefs.getInt('employeeID')}');
//     print('   CompanyID: ${prefs.getInt('companyID')}');
//     print('   CompanyName: ${prefs.getString('companyName')}');
//     print('   CreatedBy: ${prefs.getString('createdBy')}');
//     print('   Token: ${prefs.getString('token')?.substring(0, 20)}...');
//   }

//   Future<void> _loadLeaveTypes() async {
//     try {
//       print('🔄 Starting to load leave types...');
//       final leaveTypes = await _leaveService.getLeaveTypes();
//       setState(() {
//         _leaveTypes = leaveTypes;
//         _isLoading = false;
//         _errorMessage = '';
//       });
//       print('✅ Leave types loaded successfully');
//     } catch (e) {
//       print('❌ Error loading leave types: $e');
//       setState(() {
//         _errorMessage = e.toString();
//         _isLoading = false;
//       });
//     }
//   }

//   void _proceedToBalanceCheck() {
//     if (_selectedLeaveType == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Please select a leave type'),
//           backgroundColor: Theme.of(context).colorScheme.error,
//           duration: const Duration(seconds: 2),
//         ),
//       );
//       return;
//     }

//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => LeaveBalanceCheckScreen(
//           selectedLeaveType: _selectedLeaveType!,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       resizeToAvoidBottomInset: true,
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         title: const Text('Apply Leave'),
//         backgroundColor: theme.appBarTheme.backgroundColor,
//         foregroundColor: theme.appBarTheme.foregroundColor,
//         elevation: theme.appBarTheme.elevation,
//       ),
//       body: GestureDetector(
//         onTap: () => FocusScope.of(context).unfocus(),
//         child: _isLoading
//             ? _buildLoadingState(theme)
//             : _errorMessage.isNotEmpty
//                 ? _buildErrorState(theme, colorScheme)
//                 : _buildContentState(theme, colorScheme),
//       ),
//     );
//   }

//   Widget _buildLoadingState(ThemeData theme) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           CircularProgressIndicator(
//             strokeWidth: 2,
//             color: theme.colorScheme.primary,
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Loading leave types...',
//             style: theme.textTheme.bodyMedium?.copyWith(
//               color: theme.textTheme.bodySmall?.color,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildErrorState(ThemeData theme, ColorScheme colorScheme) {
//     return Center(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(24.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               Icons.error_outline,
//               size: 56,
//               color: colorScheme.error,
//             ),
//             const SizedBox(height: 20),
//             Text(
//               'Unable to Load Leave Types',
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 12),
//             Text(
//               _errorMessage,
//               textAlign: TextAlign.center,
//               style: theme.textTheme.bodySmall,
//             ),
//             const SizedBox(height: 32),
//             Wrap(
//               alignment: WrapAlignment.center,
//               spacing: 12,
//               runSpacing: 12,
//               children: [
//                 ElevatedButton(
//                   onPressed: _loadLeaveTypes,
//                   style: theme.elevatedButtonTheme.style?.copyWith(
//                     minimumSize: MaterialStateProperty.all(
//                       const Size(120, 44),
//                     ),
//                   ),
//                   child: const Text('Try Again'),
//                 ),
//                 OutlinedButton(
//                   onPressed: _showDebugInfo,
//                   style: theme.outlinedButtonTheme.style?.copyWith(
//                     minimumSize: MaterialStateProperty.all(
//                       const Size(120, 44),
//                     ),
//                   ),
//                   child: const Text('Debug Info'),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildContentState(ThemeData theme, ColorScheme colorScheme) {
//     return SafeArea(
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(
//               'Select Leave Type',
//               style: theme.textTheme.titleMedium?.copyWith(
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               '${_leaveTypes.length} leave type${_leaveTypes.length != 1 ? 's' : ''} available',
//               style: theme.textTheme.bodySmall,
//             ),
//             const SizedBox(height: 20),
//             DropdownButtonFormField<LeaveType>(
//               value: _selectedLeaveType,
//               decoration: InputDecoration(
//                 labelText: 'Leave Type',
//                 border: theme.inputDecorationTheme.border,
//                 enabledBorder: theme.inputDecorationTheme.enabledBorder,
//                 focusedBorder: theme.inputDecorationTheme.focusedBorder,
//                 contentPadding: theme.inputDecorationTheme.contentPadding,
//                 labelStyle: theme.inputDecorationTheme.labelStyle,
//                 filled: theme.inputDecorationTheme.filled,
//                 fillColor: theme.inputDecorationTheme.fillColor,
//               ),
//               items: _leaveTypes
//                   .where((type) => type.isActive)
//                   .map((LeaveType type) {
//                 return DropdownMenuItem<LeaveType>(
//                   value: type,
//                   child: Text(
//                     type.typeName,
//                     style: theme.textTheme.bodyMedium,
//                   ),
//                 );
//               }).toList(),
//               onChanged: (LeaveType? newValue) {
//                 setState(() {
//                   _selectedLeaveType = newValue;
//                 });
//               },
//             ),
//             if (_selectedLeaveType != null) ...[
//               const SizedBox(height: 16),
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: colorScheme.primary.withOpacity(0.1),
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: colorScheme.primary.withOpacity(0.3),
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.info_outline,
//                       size: 18,
//                       color: colorScheme.primary,
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'Max ${_selectedLeaveType!.maxDaysPerYear} days per year',
//                         style: theme.textTheme.bodyMedium?.copyWith(
//                           color: colorScheme.primary,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//             const SizedBox(height: 32),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _proceedToBalanceCheck,
//                 style: theme.elevatedButtonTheme.style,
//                 child: const Text('Check Balance & Continue'),
//               ),
//             ),
//             const SizedBox(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   void _showDebugInfo() async {
//     final prefs = await SharedPreferences.getInstance();

//     if (!mounted) return;

//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Debug Information'),
//         content: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _debugRow('Leave Types', '${_leaveTypes.length}'),
//               _debugRow('Error', _errorMessage.isEmpty ? 'None' : _errorMessage),
//               const SizedBox(height: 16),
//               Text(
//                 'Stored User Data:',
//                 style: Theme.of(context).textTheme.bodySmall?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 8),
//               _debugRow('Employee ID', '${prefs.getInt('employeeID')}'),
//               _debugRow('Company ID', '${prefs.getInt('companyID')}'),
//               _debugRow('Company Name', '${prefs.getString('companyName')}'),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Close'),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _debugRow(String label, String value) {
//     final theme = Theme.of(context);

//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8.0),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Text(
//               '$label:',
//               style: theme.textTheme.bodySmall?.copyWith(
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               value,
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
//               ),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }