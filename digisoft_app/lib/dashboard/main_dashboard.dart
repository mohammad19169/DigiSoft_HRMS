import 'package:digisoft_app/Attendance/screens/timesheet.dart';
import 'package:digisoft_app/Times/views/attendance.dart';
import 'package:digisoft_app/leave/apply_leave/views/unified_apply_leave.dart';
import 'package:digisoft_app/utils/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:digisoft_app/authentication/signin.dart';
import 'package:digisoft_app/utils/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String token;

  const Dashboard({super.key, required this.userData, required this.token});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  int selectedTab = 0;
  int noticeCount = 7;
  late AnimationController _controller;

  final List<Map<String, dynamic>> menuItems = [
    {'icon': Icons.add_task_outlined, 'label': 'Things to do'},
    {'icon': Icons.assignment_outlined, 'label': 'Request Status'},
    {'icon': Icons.calendar_today_outlined, 'label': 'Leave'},
    {'icon': Icons.group_outlined, 'label': 'Team'},
    {'icon': Icons.chat_bubble_outline, 'label': 'Reach HR'},
    {'icon': Icons.book_outlined, 'label': 'Directory'},
    {'icon': Icons.timer, 'label': 'Time'},
    {'icon': Icons.tv_outlined, 'label': 'Notice Board'},
    {'icon': Icons.dynamic_feed_outlined, 'label': 'Activity Feed'},
    {'icon': Icons.speed_outlined, 'label': 'Performance'},
    {'icon': Icons.receipt_long_outlined, 'label': 'Payslip'},
    {'icon': Icons.access_time_outlined, 'label': 'Attendance'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void handleTap(String label) {
    if (label == "Notice Board") {
      setState(() {
        noticeCount = 0;
      });
    }

    // Only Leave is functional
    if (label == "Leave") {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ApplyLeaveScreen()),
      );
    }
    else if (label == "Time") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceWithMapScreen(
          ),
        ),
      );}
      else if (label == "Attendance") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceFilterScreen(
          ),
        ),
      );}
     else {
      // Show coming soon for other features
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label feature coming soon!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    }
  }

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
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('token');
              await prefs.remove('rememberedEmail');
              await prefs.remove('rememberedPassword');
              await prefs.setBool('shouldRemember', false);

              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            child: Text(
              'Logout',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isProfile = selectedTab == 0;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Image.asset(
              'images/digilogo.png',
              width: 150,
              height: 50,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 20),

            // Animated Tab Switch
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: isProfile
                  ? buildProfileHeader(theme, colorScheme)
                  : buildTimelineHeader(theme, colorScheme),
            ),

            const SizedBox(height: 25),

            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: isProfile
                    ? buildGridMenu(theme, colorScheme)
                    : buildTimelineView(theme),
              ),
            ),

            // Sign out section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => _confirmLogout(context),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: colorScheme.error),
                        const SizedBox(width: 5),
                        Text(
                          "SIGN OUT",
                          style: TextStyle(
                            color: colorScheme.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MySettings(),
                        ),
                      );
                    },
                    icon: Icon(Icons.settings, color: colorScheme.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileHeader(ThemeData theme, ColorScheme colorScheme) {
    final employeeThumbnail =
        widget.userData['EmployeeThumbnail']?.toString() ?? '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        buildTabButton("Profile", 0, colorScheme.primary, theme),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: employeeThumbnail.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      employeeThumbnail,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return CircleAvatar(
                          radius: 30,
                          backgroundColor: colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: colorScheme.primary,
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: colorScheme.primary.withOpacity(
                              0.1,
                            ),
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: colorScheme.primary,
                            ),
                          ),
                    ),
                  )
                : Icon(Icons.person, size: 30, color: colorScheme.primary),
          ),
        ),
        buildTabButton("Timeline", 1, colorScheme.secondary, theme),
      ],
    );
  }

  Widget buildTimelineHeader(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      children: [
        buildProfileHeader(theme, colorScheme),
        const SizedBox(height: 10),
        Text(
          "Recent Updates",
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget buildTabButton(String title, int index, Color color, ThemeData theme) {
    final bool isSelected = selectedTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTab = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 120,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : theme.cardColor,
          borderRadius: BorderRadius.horizontal(
            left: index == 0 ? const Radius.circular(30) : Radius.zero,
            right: index == 1 ? const Radius.circular(30) : Radius.zero,
          ),
          border: Border.all(color: isSelected ? color : theme.dividerColor!),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget buildGridMenu(ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        itemCount: menuItems.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, index) {
          final item = menuItems[index];
          return GestureDetector(
            onTap: () => handleTap(item['label']),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadowColor.withOpacity(0.05),
                    blurRadius: 3,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'],
                          color: colorScheme.primary,
                          size: 55,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item['label'],
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (item['label'] == 'Notice Board' && noticeCount > 0)
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          noticeCount.toString(),
                          style: TextStyle(
                            color: colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget buildTimelineView(ThemeData theme) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) => Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          leading: Icon(Icons.history, color: theme.colorScheme.secondary),
          title: Text(
            "Timeline Event ${index + 1}",
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text("Coming soon...", style: theme.textTheme.bodySmall),
        ),
      ),
    );
  }
}