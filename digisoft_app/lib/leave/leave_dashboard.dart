import 'package:digisoft_app/leave/cancel_leave/screens/cancel_leave_screen.dart';
import 'package:digisoft_app/leave/apply_leave/views/unified_apply_leave.dart';
import 'package:flutter/material.dart';

class LeaveMainScreen extends StatelessWidget {
  const LeaveMainScreen({super.key});

  void _navigateToApplyLeave(BuildContext context) {
    // Navigate to Apply Leave Screen
    Navigator.push(context, MaterialPageRoute(builder: (context) => ApplyLeaveScreen()));
  }

  void _navigateToMyLeaves(BuildContext context) {
    // Navigate to My Leaves Screen
    Navigator.push(context, MaterialPageRoute(builder: (context) => LeaveListScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leave Management'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Apply Leave Card Button
            _BigCardButton(
              title: 'Apply Leave',
              subtitle: 'Request new time off',
              icon: Icons.add_circle_outline,
              iconColor: Colors.green,
              backgroundColor: Colors.green.withOpacity(0.1),
              onTap: () => _navigateToApplyLeave(context),
            ),
            
            const SizedBox(height: 24),
            
            // My Leaves Card Button
            _BigCardButton(
              title: ' Pending Leaves',
              subtitle: 'View & manage your leaves',
              icon: Icons.list_alt,
              iconColor: Colors.blue,
              backgroundColor: Colors.blue.withOpacity(0.1),
              onTap: () => _navigateToMyLeaves(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _BigCardButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const _BigCardButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150, // Big card size
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: backgroundColor,
          ),
          child: Row(
            children: [
              // Icon
              Icon(
                icon,
                size: 60,
                color: iconColor,
              ),
              const SizedBox(width: 20),
              
              // Text Content
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon
              const Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
