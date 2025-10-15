import 'package:digisoft_app/leave/apply_leave/views/leave_dashboard';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text('Digisoft', style: TextStyle(
            fontSize: 25, fontWeight: FontWeight.bold,color: Colors.black 
        ))),
        backgroundColor: Colors.blueGrey,
      ),
      body: Column(
        children: [
          Row(
            children: [
              Container(
                height: 150,
                width: 150,
                margin: EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LeaveRequestScreen())),
                  child: Card(
                    child: Center(
                      child: ListTile(
                        leading: Icon(Icons.event_note_outlined),
                        title: Text('Leave'),
                        subtitle: Text('Apply for leave'),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 150,
                width: 150,
                margin: EdgeInsets.all(20),
                child: Card(
                  child: Center(
                    child: ListTile(
                      leading: Icon(Icons.access_time_outlined),
                      title: Text('Time'),
                      subtitle: Text('Log your time'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
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
                margin: EdgeInsets.all(15),
                child: Card(
                  child: Center(
                    child: ListTile(
                      leading: Icon(Icons.check_circle_outline),
                      title: Text(
                        'Attendance',
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                      ),
                      subtitle: Text('Mark your attendance'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                height: 150,
                width: 160,
                margin: EdgeInsets.all(10),
                child: Card(
                  child: Center(
                    child: ListTile(
                      leading: Icon(Icons.person_outline),
                      title: Text('Profile'),
                      subtitle: Text('View your profile'),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
