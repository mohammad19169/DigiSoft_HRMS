import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:digisoft_app/global.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class SalarySlipService {
  static String get baseUrl {
    String url = baseURL;
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  static Future<pw.Font> _loadCustomFont() async {
    try {
      final fontData = await rootBundle.load('assets/fonts/OpenSans-Regular.ttf');
      return pw.Font.ttf(fontData);
    } catch (e) {
      print('⚠️ Could not load OpenSans font: $e');
      return pw.Font.courier();
    }
  }

  static Future<pw.ImageProvider?> _loadCompanyLogo() async {
    try {
      // Try multiple possible logo paths
      final possiblePaths = [
        'images/digilogo.png',
        'assets/images/digilogo.png',
        'assets/digilogo.png',
        'assets/images/digilogo.png',
      ];
      
      for (final path in possiblePaths) {
        try {
          final logoData = await rootBundle.load(path);
          print('✅ Company logo loaded from: $path');
          return pw.MemoryImage(logoData.buffer.asUint8List());
        } catch (e) {
          continue;
        }
      }
      
      print('⚠️ Could not load company logo from any path');
      return null;
    } catch (e) {
      print('⚠️ Error loading company logo: $e');
      return null;
    }
  }

  static Future<Map<String, int>> _getUserIdsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final employeeID = prefs.getInt('employeeID') ?? 0;
      final companyID = prefs.getInt('companyID') ?? 0;
      
      print('🔍 Retrieved from SharedPreferences:');
      print('   EmployeeID: $employeeID');
      print('   CompanyID: $companyID');
      
      if (employeeID == 0 || companyID == 0) {
        throw Exception('User not logged in or IDs not found in SharedPreferences');
      }
      
      return {
        'employeeID': employeeID,
        'companyID': companyID,
      };
    } catch (e) {
      print('❌ Error getting IDs from SharedPreferences: $e');
      rethrow;
    }
  }

  static Future<SalarySlipResponse> getSalarySlip() async {
    try {
      final ids = await _getUserIdsFromPrefs();
      final companyId = ids['companyID']!;
      final employeeId = ids['employeeID']!;
      
      final url = '$baseUrl/hrm/api/Payroll/getsalaryslip?companyId=$companyId&employeeId=$employeeId';
      print('📡 Making API call to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(Duration(seconds: 30));

      print('📊 Response Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ Salary slip retrieved successfully');
        
        return SalarySlipResponse.fromJson(responseData);
      } else if (response.statusCode == 404) {
        throw Exception('API endpoint not found (404). Please check the URL: $url');
      } else if (response.statusCode == 401) {
        throw Exception('Unauthorized access. Please login again.');
      } else if (response.statusCode == 500) {
        throw Exception('Server error. Please try again later.');
      } else {
        throw Exception('Failed to load salary slip. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Unexpected error loading salary slip: $e');
      throw Exception('Failed to load salary slip: $e');
    }
  }

  static Future<void> generateAndSharePayslip(SalarySlip salarySlip) async {
    try {
      print('🔄 Starting PDF generation...');
      
      final pdf = pw.Document();
      final font = await _loadCustomFont();
      final logo = await _loadCompanyLogo();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return _buildExactPdfFormat(salarySlip, font, logo);
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final String fileName = 'payslip_${salarySlip.employeeCode}_${salarySlip.payrollMonth}_${salarySlip.payrollYear}.pdf';
      final String filePath = '${tempDir.path}/$fileName';
      final File file = File(filePath);
      
      final Uint8List pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);
      
      print('✅ PDF generated at: $filePath');
      print('📄 File size: ${pdfBytes.length} bytes');

      await _showShareSheet(file, salarySlip);
      
    } catch (e) {
      print('❌ PDF generation/sharing error: $e');
      throw Exception('Failed to generate PDF: $e');
    }
  }

  static pw.Widget _buildExactPdfFormat(SalarySlip salarySlip, pw.Font font, pw.ImageProvider? logo) {
    return pw.Container(
      padding: pw.EdgeInsets.all(30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header with Logo and Title
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              // Logo on the left
              if (logo != null)
                pw.Container(
                  width: 80,
                  height: 80,
                  child: pw.Image(logo, fit: pw.BoxFit.contain),
                )
              else
                pw.SizedBox(width: 80),
              
              // Title in the center
              pw.Expanded(
                child: pw.Center(
                  child: pw.Text(
                    'Salary Slip',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              // Empty space on the right for symmetry
              pw.SizedBox(width: 80),
            ],
          ),
          pw.SizedBox(height: 25),
          
          // Employee Info Section (2x2 grid)
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            columnWidths: {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
            },
            children: [
              // Row 1: Headers
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildCell('Employee', font, isHeader: true),
                  _buildCell('Designation', font, isHeader: true),
                ],
              ),
              // Row 2: Values
              pw.TableRow(
                children: [
                  _buildCell('${salarySlip.employeeCode} ${salarySlip.fullName}', font),
                  _buildCell(salarySlip.designationName, font),
                ],
              ),
              // Row 3: Headers
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildCell('Department', font, isHeader: true),
                  _buildCell('Payroll Month', font, isHeader: true),
                ],
              ),
              // Row 4: Values
              pw.TableRow(
                children: [
                  _buildCell(salarySlip.departmentName, font),
                  _buildCell(_getMonthName(salarySlip.payrollMonth), font),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 25),
          
          // Salary & Deductions Table (side by side)
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            columnWidths: {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(1.5),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1.5),
            },
            children: [
              // Headers
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildCell('Salary', font, isHeader: true),
                  _buildCell('Amount', font, isHeader: true),
                  _buildCell('Deductions', font, isHeader: true),
                  _buildCell('Amount', font, isHeader: true),
                ],
              ),
              // Basic Salary | Tax
              pw.TableRow(
                children: [
                  _buildCell('Basic Salary', font),
                  _buildCell('${_formatCurrency(salarySlip.basicSalary)} PKR', font),
                  _buildCell('Tax (TDS)', font),
                  _buildCell('${_formatCurrency(salarySlip.taxDeduction)} PKR', font),
                ],
              ),
              // Allowances | Late Deduction
              pw.TableRow(
                children: [
                  _buildCell('Allowances', font),
                  _buildCell('${_formatCurrency(salarySlip.medicalAllowance + salarySlip.houseRentAllowance + salarySlip.conveyanceAllowance + salarySlip.specialAllowance + salarySlip.bonus + salarySlip.fuelReimbursement + salarySlip.overtimeAmount)} PKR', font),
                  _buildCell('Late Deduction', font),
                  _buildCell('${_formatCurrency(salarySlip.lateDeduction)} PKR', font),
                ],
              ),
              // Gross Salary | Total Deductions
              pw.TableRow(
                children: [
                  _buildCell('Gross Salary', font),
                  _buildCell('${_formatCurrency(salarySlip.grossSalary)} PKR', font),
                  _buildCell('Total Deductions', font),
                  _buildCell('${_formatCurrency(salarySlip.totalDeductions)} PKR', font),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 25),
          
          // Summary Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.black, width: 1),
            columnWidths: {
              0: pw.FlexColumnWidth(1),
              1: pw.FlexColumnWidth(1),
              2: pw.FlexColumnWidth(1),
              3: pw.FlexColumnWidth(1),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColors.grey300),
                children: [
                  _buildCell('Summary', font, isHeader: true),
                  _buildCell('Gross', font, isHeader: true),
                  _buildCell('Total Deductions', font, isHeader: true),
                  _buildCell('Net Payable', font, isHeader: true),
                ],
              ),
              pw.TableRow(
                children: [
                  _buildCell('', font),
                  _buildCell('${_formatCurrency(salarySlip.grossSalary)} PKR', font),
                  _buildCell('${_formatCurrency(salarySlip.totalDeductions)} PKR', font),
                  _buildCell('${_formatCurrency(salarySlip.netSalary)} PKR', font),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 40),
          
          // Signature Section
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Employee Signature',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
              pw.Text(
                'HR / Accounts Signature',
                style: pw.TextStyle(font: font, fontSize: 10),
              ),
            ],
          ),
          
          pw.Spacer(),
          
          // Company Name (bold)
          pw.Center(
            child: pw.Text(
              salarySlip.companyName,
              style: pw.TextStyle(
                font: font,
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          
          // Footer timestamp
          pw.Center(
            child: pw.Text(
              'Generated on ${_formatDateTime(DateTime.now())} Page 1 of 1',
              style: pw.TextStyle(
                font: font,
                fontSize: 9,
                color: PdfColors.grey700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Padding(
      padding: pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static Future<void> _showShareSheet(File file, SalarySlip salarySlip) async {
    try {
      final String subject = 'Salary Slip - ${salarySlip.fullName} - ${_getMonthName(salarySlip.payrollMonth)} ${salarySlip.payrollYear}';
      final String text = 'Salary Slip for ${salarySlip.fullName} - ${_getMonthName(salarySlip.payrollMonth)} ${salarySlip.payrollYear}';
      
      print('📤 Sharing file: ${file.path}');
      
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: subject,
        text: text,
      );
      
      print('✅ Share sheet opened successfully');
      
    } catch (e) {
      print('❌ Error in share sheet: $e');
      
      try {
        print('🔄 Trying to open file directly...');
        final result = await OpenFile.open(file.path);
        print('📁 Open file result: ${result.type} - ${result.message}');
      } catch (openError) {
        print('❌ Error opening file: $openError');
        throw Exception('Failed to share or open PDF: $e');
      }
    }
  }

  static String _formatCurrency(double amount) {
    return NumberFormat('#,##0').format(amount);
  }

  static String _getMonthName(int month) {
    final months = {
      1: 'January', 2: 'February', 3: 'March', 4: 'April',
      5: 'May', 6: 'June', 7: 'July', 8: 'August',
      9: 'September', 10: 'October', 11: 'November', 12: 'December'
    };
    return months[month] ?? 'Unknown';
  }

  static String _formatDateTime(DateTime dateTime) {
    return DateFormat('dd/MM/yyyy, HH:mm:ss').format(dateTime);
  }
}

// Response Models
class SalarySlipResponse {
  final int statusCode;
  final String message;
  final List<SalarySlip> data;
  final List<dynamic> errors;
  final bool isSuccess;
  final String timestamp;

  SalarySlipResponse({
    required this.statusCode,
    required this.message,
    required this.data,
    required this.errors,
    required this.isSuccess,
    required this.timestamp,
  });

  factory SalarySlipResponse.fromJson(Map<String, dynamic> json) {
    return SalarySlipResponse(
      statusCode: json['statusCode'] ?? 0,
      message: json['message'] ?? '',
      data: (json['data'] as List<dynamic>?)
          ?.map((item) => SalarySlip.fromJson(item))
          .toList() ?? [],
      errors: json['errors'] ?? [],
      isSuccess: json['isSuccess'] ?? false,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class SalarySlip {
  final int payrollID;
  final int employeeId;
  final String employeeCode;
  final String firstName;
  final String lastName;
  final String designationName;
  final String departmentName;
  final int companyId;
  final String companyName;
  final int payrollMonth;
  final int payrollYear;
  final String payrollStatus;
  final double basicSalary;
  final double medicalAllowance;
  final double houseRentAllowance;
  final double conveyanceAllowance;
  final double specialAllowance;
  final double bonus;
  final double fuelReimbursement;
  final double overtimeAmount;
  final double providentFund;
  final double taxDeduction;
  final double loanRecovery;
  final double loanDeduction;
  final double advanceSalary;
  final double lateDeduction;
  final double absentDeduction;
  final double eobi;
  final double totalAllowances;
  final double totalDeductions;
  final double grossSalary;
  final double netSalary;
  final int presentDays;
  final int absentDays;
  final int lateDays;
  final int leaveDays;
  final int holidayDays;
  final int weekOffDays;
  final String profilePic;
  final String createdOn;

  SalarySlip({
    required this.payrollID,
    required this.employeeId,
    required this.employeeCode,
    required this.firstName,
    required this.lastName,
    required this.designationName,
    required this.departmentName,
    required this.companyId,
    required this.companyName,
    required this.payrollMonth,
    required this.payrollYear,
    required this.payrollStatus,
    required this.basicSalary,
    required this.medicalAllowance,
    required this.houseRentAllowance,
    required this.conveyanceAllowance,
    required this.specialAllowance,
    required this.bonus,
    required this.fuelReimbursement,
    required this.overtimeAmount,
    required this.providentFund,
    required this.taxDeduction,
    required this.loanRecovery,
    required this.loanDeduction,
    required this.advanceSalary,
    required this.lateDeduction,
    required this.absentDeduction,
    required this.eobi,
    required this.totalAllowances,
    required this.totalDeductions,
    required this.grossSalary,
    required this.netSalary,
    required this.presentDays,
    required this.absentDays,
    required this.lateDays,
    required this.leaveDays,
    required this.holidayDays,
    required this.weekOffDays,
    required this.profilePic,
    required this.createdOn,
  });

  factory SalarySlip.fromJson(Map<String, dynamic> json) {
    return SalarySlip(
      payrollID: json['payrollID'] ?? 0,
      employeeId: json['employeeId'] ?? 0,
      employeeCode: json['employeeCode'] ?? '',
      firstName: json['firstName'] ?? '',
      lastName: json['lastName'] ?? '',
      designationName: json['designationName'] ?? '',
      departmentName: json['departmentName'] ?? '',
      companyId: json['companyId'] ?? 0,
      companyName: json['companyName'] ?? '',
      payrollMonth: json['payrollMonth'] ?? 0,
      payrollYear: json['payrollYear'] ?? 0,
      payrollStatus: json['payrollStatus'] ?? '',
      basicSalary: (json['basicSalary'] ?? 0.0).toDouble(),
      medicalAllowance: (json['medicalAllowance'] ?? 0.0).toDouble(),
      houseRentAllowance: (json['houseRentAllowance'] ?? 0.0).toDouble(),
      conveyanceAllowance: (json['conveyanceAllowance'] ?? 0.0).toDouble(),
      specialAllowance: (json['specialAllowance'] ?? 0.0).toDouble(),
      bonus: (json['bonus'] ?? 0.0).toDouble(),
      fuelReimbursement: (json['fuelReimbursement'] ?? 0.0).toDouble(),
      overtimeAmount: (json['overtimeAmount'] ?? 0.0).toDouble(),
      providentFund: (json['providentFund'] ?? 0.0).toDouble(),
      taxDeduction: (json['taxDeduction'] ?? 0.0).toDouble(),
      loanRecovery: (json['loanRecovery'] ?? 0.0).toDouble(),
      loanDeduction: (json['loanDeduction'] ?? 0.0).toDouble(),
      advanceSalary: (json['advanceSalary'] ?? 0.0).toDouble(),
      lateDeduction: (json['lateDeduction'] ?? 0.0).toDouble(),
      absentDeduction: (json['absentDeduction'] ?? 0.0).toDouble(),
      eobi: (json['eobi'] ?? 0.0).toDouble(),
      totalAllowances: (json['totalAllowances'] ?? 0.0).toDouble(),
      totalDeductions: (json['totalDeductions'] ?? 0.0).toDouble(),
      grossSalary: (json['grossSalary'] ?? 0.0).toDouble(),
      netSalary: (json['netSalary'] ?? 0.0).toDouble(),
      presentDays: json['presentDays'] ?? 0,
      absentDays: json['absentDays'] ?? 0,
      lateDays: json['lateDays'] ?? 0,
      leaveDays: json['leaveDays'] ?? 0,
      holidayDays: json['holidayDays'] ?? 0,
      weekOffDays: json['weekOffDays'] ?? 0,
      profilePic: json['profilePic'] ?? '',
      createdOn: json['createdOn'] ?? '',
    );
  }

  String get fullName => '$firstName $lastName';

  String get formattedPeriod {
    final monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${monthNames[payrollMonth]} $payrollYear';
  }
}