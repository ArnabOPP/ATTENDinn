import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

class StudentDashboard extends StatefulWidget {
  final String uid;
  const StudentDashboard({super.key, required this.uid});
  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  int _currIdx = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      StudentHome(uid: widget.uid),
      AttendanceStatusPage(uid: widget.uid),
      const LeaderboardPage()
    ];

    return Scaffold(
      body: pages[_currIdx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currIdx,
        onDestinationSelected: (i) => setState(() => _currIdx = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.fact_check_outlined), label: 'Attendance'),
          NavigationDestination(icon: Icon(Icons.leaderboard_outlined), label: 'Rank'),
        ],
      ),
    );
  }
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

class StudentHome extends StatelessWidget {
  final String uid;
  const StudentHome({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseDatabase.instance.ref('users/students/$uid').onValue,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final s = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
        bool atDoor = s['at_door'] ?? false;

        return StreamBuilder(
          stream: FirebaseDatabase.instance.ref('attendance_control/${s['section']}').onValue,
          builder: (context, ctrlSnap) {
            bool open = false;
            if (ctrlSnap.hasData && ctrlSnap.data!.snapshot.value != null) {
              final c = Map<String, dynamic>.from(ctrlSnap.data!.snapshot.value as Map);
              open = c['isOpen'] ?? false;
            }

            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              appBar: AppBar(
                title: _appLogoTitle("||   Dashboard Page"),
                centerTitle: false,
                elevation: 0,
                backgroundColor: Colors.white,
              ),
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          const CircleAvatar(
                              radius: 40,
                              backgroundColor: Color(0xFF6366F1),
                              child: Icon(Icons.person, size: 40, color: Colors.white)
                          ),
                          const SizedBox(height: 15),
                          Text(s['name'] ?? "Unknown", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          Text("${s['course']} | ${s['stream']}", style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    _statusTile("1. Gate Entry Verified", atDoor),
                    const SizedBox(height: 10),
                    _statusTile("2. Class Session Available", open),
                    const SizedBox(height: 30),
                    const Divider(),
                    const SizedBox(height: 20),
                    _buildInfoSection("Academic Info", [
                      _infoRow(Icons.badge, "Roll No", s['roll']),
                      _infoRow(Icons.grid_view, "Section", s['section']),
                      _infoRow(Icons.location_on, "Campus", s['campus']),
                    ]),
                    const SizedBox(height: 20),
                    _buildInfoSection("Personal Details", [
                      _infoRow(Icons.email, "Email", s['email']),
                      _infoRow(Icons.cake, "DOB", s['dob']),
                      _infoRow(Icons.bloodtype, "Blood Group", s['blood_group']),
                      _infoRow(Icons.family_restroom, "Father's Name", s['father_name']),
                    ]),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                          child: const Text("Logout Account", style: TextStyle(fontWeight: FontWeight.bold))
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _statusTile(String label, bool active) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: active ? Colors.green.withValues(alpha: 0.5) : Colors.grey.shade200)
      ),
      child: Row(
        children: [
          Icon(active ? Icons.check_circle : Icons.cancel, color: active ? Colors.green : Colors.grey.shade300, size: 28),
          const SizedBox(width: 15),
          Text(label, style: TextStyle(fontSize: 16, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? Colors.black : Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
        const SizedBox(height: 10),
        ...rows,
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 10),
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value?.toString() ?? "N/A", style: const TextStyle(color: Colors.black87), textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class AttendanceStatusPage extends StatefulWidget {
  final String uid;
  const AttendanceStatusPage({super.key, required this.uid});
  @override
  State<AttendanceStatusPage> createState() => _AttendanceStatusPageState();
}

class _AttendanceStatusPageState extends State<AttendanceStatusPage> {
  bool _isLoading = false;

  Future<void> _handleMarking(Map s, String sub, String teach) async {
    setState(() => _isLoading = true);
    const scriptUrl = "https://script.google.com/macros/s/AKfycbw-XLLeIvlBfLijLCzdZ2Y_af-VSaUoNDOjaAbWLp_8ikJxQBmtcNg2OCbEC6_d5wA/exec";

    try {
      await http.post(
        Uri.parse(scriptUrl),
        body: jsonEncode({
          "name": s['name'], "uid": widget.uid, "stream": s['stream'],
          "section": s['section'], "roll": s['roll'],
          "subject": sub, "teachers_name": teach
        }),
      ).timeout(const Duration(seconds: 12));
    } catch (e) {
      debugPrint("Processing Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: _appLogoTitle("||   Attendance Page"),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users/students/${widget.uid}').onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) return const Center(child: CircularProgressIndicator());
          final s = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          bool atDoor = s['at_door'] ?? false;
          String lastMarked = s['last_marked_subject'] ?? "";

          return StreamBuilder(
            stream: FirebaseDatabase.instance.ref('attendance_control/${s['section']}').onValue,
            builder: (context, ctrlSnap) {
              bool open = false; String sub = "N/A", teach = "N/A";
              if (ctrlSnap.hasData && ctrlSnap.data!.snapshot.value != null) {
                final c = Map<String, dynamic>.from(ctrlSnap.data!.snapshot.value as Map);
                open = c['isOpen'] ?? false;
                sub = c['subject'] ?? "";
                teach = c['teacherName'] ?? "";
              }
              bool isAlreadyMarked = (lastMarked == sub && sub != "" && sub != "N/A");
              bool isAccessible = open && !isAlreadyMarked;

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isAccessible) ...[
                        const Icon(Icons.lock_outline, size: 80, color: Colors.grey),
                        const SizedBox(height: 20),
                        Text(
                          isAlreadyMarked ? "Attendance Recorded for $sub" : "Attendance Interface Locked",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isAlreadyMarked ? "You have already marked your presence for this class." : "Marking will be available once the teacher opens the session.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ] else ...[
                        Text("Attendance For Class: $sub", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF6366F1))),
                        Text("Teacher: $teach", style: const TextStyle(color: Colors.grey)),
                        const SizedBox(height: 40),
                        SizedBox(
                          width: double.infinity, height: 60,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                            ),
                            onPressed: (atDoor && !_isLoading) ? () => _handleMarking(s, sub, teach) : null,
                            child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("MARK PRESENT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  String _selectedMetric = "max days present in college";
  String _selectedScope = "whole college";
  String _selectedSubject = "all subjects";

  final List<String> _metrics = [
    "max days present in college",
    "max classes present"
  ];

  final List<String> _scopes = [
    "whole college", "A1", "A2", "A3", "A4", "A5", "A6", "A7", "A8", "A9", "A10",
    "B1", "B2", "B3", "B4", "B5", "B6", "B7", "B8", "B9", "B10"
  ];

  final List<String> _subjects = [
    "all subjects", "Maths", "Physics", "Basic Electrical", "Esp", "Sdp",
    "graphics Design", "Python", "Mechanics", "Biology", "Sports",
    "Electronics", "English", "C", "Workshop", "Chemistry", "Economics",
    "Design Thinking & Innovation", "History", "Matlab"
  ];

  Future<Map<String, dynamic>> _fetchSheetStats() async {
    const url = "https://script.google.com/macros/s/AKfycbw-XLLeIvlBfLijLCzdZ2Y_af-VSaUoNDOjaAbWLp_8ikJxQBmtcNg2OCbEC6_d5wA/exec";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception("Failed to load leaderboard from Sheet");
  }

  @override
  Widget build(BuildContext context) {
    bool isSubjectDisabled = _selectedMetric == "max days present in college";

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: _appLogoTitle("||   Leaderboard Page"),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildFilterDropdown("Metric", _metrics, _selectedMetric, (val) {
                      setState(() => _selectedMetric = val!);
                    })),
                    const SizedBox(width: 12),
                    Expanded(child: _buildFilterDropdown("Scope", _scopes, _selectedScope, (val) {
                      setState(() => _selectedScope = val!);
                    })),
                  ],
                ),
                const SizedBox(height: 12),
                Opacity(
                  opacity: isSubjectDisabled ? 0.4 : 1.0,
                  child: AbsorbPointer(
                    absorbing: isSubjectDisabled,
                    child: _buildFilterDropdown("Subject", _subjects, _selectedSubject, (val) {
                      setState(() => _selectedSubject = val!);
                    }, isFullWidth: true),
                  ),
                ),
              ],
            ),
          ),

          // List Section
          Expanded(
            child: FutureBuilder(
              future: _fetchSheetStats(),
              builder: (context, statsSnap) {
                if (statsSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (statsSnap.hasError) {
                  return Center(child: Text("Sheet Error: ${statsSnap.error}"));
                }

                final stats = statsSnap.data!;

                return StreamBuilder(
                  stream: FirebaseDatabase.instance.ref('users/students').onValue,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    Map<dynamic, dynamic> data = snapshot.data!.snapshot.value as Map;
                    List<Map<String, dynamic>> students = [];

                    data.forEach((uid, value) {
                      var student = Map<String, dynamic>.from(value);
                      String studentUID = uid.toString();

                      // 1. Filter by Section Scope
                      bool matchesScope = (_selectedScope == "whole college" ||
                          student['section']?.toString().toLowerCase() == _selectedScope.toLowerCase());

                      if (matchesScope) {
                        int score = 0;
                        // 2. Calculate score based on selected Metric
                        if (_selectedMetric == "max days present in college") {
                          score = stats['gate'][studentUID] ?? 0;
                        } else {
                          var att = stats['attendance'][studentUID];
                          if (att != null) {
                            score = (_selectedSubject == "all subjects")
                                ? (att['total'] ?? 0)
                                : (att[_selectedSubject] ?? 0);
                          }
                        }
                        student['points'] = score;
                        students.add(student);
                      }
                    });

                    // Sort by Points descending
                    students.sort((a, b) => (b['points'] ?? 0).compareTo(a['points'] ?? 0));

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isTopThree = index < 3;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: isTopThree ? const Color(0xFF6366F1).withValues(alpha: 0.3) : Colors.grey.shade200),
                            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isTopThree ? const Color(0xFF6366F1) : Colors.grey.shade100,
                                child: Text("${index + 1}",
                                    style: TextStyle(color: isTopThree ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(student['name'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text("${student['stream']} | Sec ${student['section']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  Text("${student['points'] ?? 0}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF6366F1))),
                                  const Text("Points", style: TextStyle(fontSize: 10, color: Colors.grey)),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(String label, List<String> items, String currentVal, Function(String?) onChanged, {bool isFullWidth = false}) {
    return Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentVal,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down, size: 20),
          style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
