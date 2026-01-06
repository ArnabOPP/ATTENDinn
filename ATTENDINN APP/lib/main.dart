import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'intro_screens.dart';
import 'login_page.dart';
import 'student_pages.dart';
import 'teacher_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const AttendInnApp());
}

class AttendInnApp extends StatelessWidget {
  const AttendInnApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AttendInn',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6366F1),
          primary: const Color(0xFF6366F1),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          color: Colors.white,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _introFinished = false;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        
        final user = snapshot.data;

        // 1. If user is logged in, show Dashboard immediately
        if (snapshot.hasData && user != null && user.email != null) {
          return RoleSearchRedirect(email: user.email!);
        }

        // 2. If not logged in and intro isn't finished, show Intro
        if (!_introFinished) {
          return AttendInnIntro(onFinished: () {
            setState(() {
              _introFinished = true;
            });
          });
        }

        // 3. Otherwise, show Login Page
        return const LoginPage();
      },
    );
  }
}

class RoleSearchRedirect extends StatelessWidget {
  final String email;
  const RoleSearchRedirect({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _findUserByEmail(email),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const CantUseAppPage();
        }
        return snapshot.data!;
      },
    );
  }

  Future<Widget> _findUserByEmail(String email) async {
    final db = FirebaseDatabase.instance.ref();
    try {
      final studentQuery = await db.child('users/students').orderByChild('email').equalTo(email).get();
      if (studentQuery.exists && studentQuery.children.isNotEmpty) {
        return StudentDashboard(uid: studentQuery.children.first.key!);
      }

      final teacherQuery = await db.child('users/teachers').orderByChild('email').equalTo(email).get();
      if (teacherQuery.exists && teacherQuery.children.isNotEmpty) {
        return TeacherDashboard(uid: teacherQuery.children.first.key!);
      }

      return const CantUseAppPage();
    } catch (e) {
      debugPrint("Database Search Error: $e");
      return const CantUseAppPage();
    }
  }
}

class CantUseAppPage extends StatelessWidget {
  const CantUseAppPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 80, color: Colors.redAccent),
            const SizedBox(height: 10),
            const Text("Access Denied", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                "Your email was not found in our database. Please contact the administrator.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text("Back to Login"),
            )
          ],
        ),
      ),
    );
  }
}
