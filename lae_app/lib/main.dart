import 'package:flutter/material.dart';
import 'package:lae_app/pages/status_survey_page.dart';
import 'package:lae_app/services/notification_service.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  // Ensure that plugin services are initialized so that `availableCameras()`
  // can be called before `runApp()`
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize notification service
  await NotificationService().init(navigatorKey);
  // Schedule the daily notification
  await NotificationService().scheduleDailySurveyNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LAE System',
      navigatorKey: navigatorKey, // Set the navigator key
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      // Define the home widget and routes
      home: const HomePage(), // You can create a simple HomePage
      routes: {
        '/survey': (context) => const StatusSurveyPage(),
      },
    );
  }
}

// A placeholder for your main screen
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LAE Home'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('欢迎使用LAE系统'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                // Manually navigate to the survey page for testing
                Navigator.pushNamed(context, '/survey');
              },
              child: const Text('手动填写问卷'),
            ),
          ],
        ),
      ),
    );
  }
}
