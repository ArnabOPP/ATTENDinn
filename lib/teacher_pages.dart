import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TeacherDashboard extends StatefulWidget {
  final String uid;
  const TeacherDashboard({super.key, required this.uid});
  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: _appLogoTitle("|| Teacher Portal"),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => FirebaseAuth.instance.signOut(),
            icon: const Icon(Icons.logout, color: Colors.redAccent),
          )
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users/teachers/${widget.uid}').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: CircularProgressIndicator());
          }
          final t = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _profileHeader(t),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 10),
                child: Text(
                  "Manage Class Attendance",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
              ),
              Expanded(child: _sectionList(t)),
            ],
          );
        },
      ),
    );
  }

  Widget _appLogoTitle(String pageTitle) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Image.asset('assets/logo.png', height: 35),
        ),
        Transform.translate(
          offset: const Offset(0, -2),
          child: Text(
            pageTitle,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
              fontSize: 20,
              color: Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _profileHeader(Map t) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFF6366F1),
            child: Icon(Icons.school_rounded, size: 40, color: Colors.white),
          ),
          const SizedBox(height: 15),
          Text(
            t['name'] ?? "Teacher",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "Subject: ${t['subject']}",
              style: const TextStyle(
                color: Color(0xFF6366F1),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionList(Map t) {
    final sections = [
      for (var i = 1; i <= 10; i++) 'A$i',
      for (var i = 1; i <= 10; i++) 'B$i'
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: sections.length,
      itemBuilder: (context, i) {
        final sec = sections[i];
        return StreamBuilder(
          stream: FirebaseDatabase.instance.ref('attendance_control/$sec').onValue,
          builder: (context, snap) {
            bool active = false;
            String openedByUID = "";
            String openedByName = "";

            if (snap.hasData && snap.data!.snapshot.value != null) {
              final data = Map<String, dynamic>.from(snap.data!.snapshot.value as Map);
              active = data['isOpen'] ?? false;
              openedByUID = data['openedByUID'] ?? "";
              openedByName = data['teacherName'] ?? "Unknown";
            }

            // CHECK: Is the session active AND opened by someone ELSE?
            bool isLockedByOther = active && (openedByUID != widget.uid);

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isLockedByOther ? Colors.grey.shade50 : Colors.white,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: active ? const Color(0xFF6366F1).withValues(alpha: 0.5) : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: SwitchListTile(
                activeTrackColor: const Color(0xFF6366F1).withValues(alpha: 0.5),
                activeThumbColor: const Color(0xFF6366F1),
                // Disable the switch if locked by someone else
                onChanged: isLockedByOther ? null : (val) {
                  FirebaseDatabase.instance.ref('attendance_control/$sec').set({
                    'isOpen': val,
                    'subject': t['subject'],
                    'teacherName': t['name'],
                    'openedByUID': val ? widget.uid : "", // Store UID when opening
                  });
                },
                value: active,
                secondary: Icon(
                  Icons.group_work_rounded,
                  color: active ? const Color(0xFF6366F1) : Colors.grey,
                ),
                title: Text(
                  "Section $sec",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: active ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                  ),
                ),
                subtitle: Text(
                  isLockedByOther
                      ? "In Use by $openedByName"
                      : (active ? "Attendance is LIVE" : "Attendance is CLOSED"),
                  style: TextStyle(
                    color: isLockedByOther ? Colors.orange : (active ? Colors.green : Colors.grey),
                    fontWeight: isLockedByOther ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
