import 'package:digisoft_app/authentication/signin.dart';
import 'package:digisoft_app/leave/apply_leave/views/leave_dashboard';
import 'package:digisoft_app/Time/screens/attendance_screen.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  final Map<String, dynamic> userData;
  final String token;

  const Dashboard({super.key, required this.userData, required this.token});

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
                (route) => false,
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Center(
          child: Text(
            'Digisoft',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome, ${userData['UserName'] ?? 'User'}",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text("Email: ${userData['Email'] ?? '-'}"),
                    Text("Company: ${userData['CompanyName'] ?? '-'}"),
                    Text("Employee Code: ${userData['EmployeeCode'] ?? '-'}"),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  height: 150,
                  width: 150,
                  margin: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveRequestScreen(),
                      ),
                    ),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: ListTile(
                          leading: Icon(Icons.event_note_outlined),
                          title: Text('Leave'),
                          subtitle: Text('Apply for leave'),
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 150,
                  width: 162,
                  margin: const EdgeInsets.all(20),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AttendanceScreen(),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: ListTile(
                          leading: Icon(Icons.access_time_outlined),
                          title: Text('Time'),
                          subtitle: Text('Mark Attendance'),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  height: 150,
                  width: 175,
                  margin: const EdgeInsets.all(15),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: ListTile(
                        leading: Icon(Icons.check_circle_outline),
                        title: Text(
                          'Attendance',
                          maxLines: 1,
                          overflow: TextOverflow.visible,
                        ),
                        subtitle: Text('View your attendance'),
                      ),
                    ),
                  ),
                ),
                Container(
                  height: 150,
                  width: 160,
                  margin: const EdgeInsets.all(10),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: ListTile(
                        leading: Icon(Icons.person_outline),
                        title: Text('Profile'),
                        subtitle: Text('View your profile'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
