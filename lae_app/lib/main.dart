import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lae_app/services/notification_service.dart';
import 'package:lae_app/services/database_helper.dart';
import 'package:lae_app/pages/status_survey_page.dart';
import 'package:lae_app/pages/records_display_page.dart';
import 'package:lae_app/services/supabase_service.dart'; // Import Supabase service

// 全局变量，方便在其他地方访问服务实例
final NotificationService notificationService = NotificationService();
final DatabaseHelper databaseHelper = DatabaseHelper();
final SupabaseService supabaseService = SupabaseService(); // Create an instance

// 为Navigator创建GlobalKey，以便在应用外部导航
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // 确保Flutter绑定已经初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 定义当用户点击通知时要执行的回调函数
  void onDidReceiveNotificationResponse(NotificationResponse response) {
    // 使用navigator key导航到问卷页面
    // 'currentState?'确保在key未附加到widget时不会崩溃
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (context) => const StatusSurveyPage()),
    );
  }

  // 初始化所有服务
  try {
    // Initialize Supabase
    await SupabaseService.initialize();

    // 将回调函数作为命名参数传递给init方法
    await notificationService.init(
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
    // 设置每日23:00的定时通知
    await notificationService.scheduleDailySurveyNotification();

    // 初始化数据库
    await databaseHelper.init();
  } catch (e) {
    // 在调试控制台打印初始化错误
    debugPrint('Services initialization failed: $e');
  }

  // 运行Flutter应用
  runApp(const MyApp());
} // <--- 这里是之前缺失的 main 函数的右花括号

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 将navigatorKey分配给MaterialApp
      navigatorKey: navigatorKey,
      title: 'LAE System',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isUploading = false;

  // 导航到问卷页面的辅助函数
  void _navigateToSurveyPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const StatusSurveyPage()),
    );
  }

  // 新增：导航到记录显示页面的辅助函数
  void _navigateToRecordsPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RecordsDisplayPage()),
    );
  }

  // 新增：处理数据上传的函数
  Future<void> _handleUpload() async {
    setState(() {
      _isUploading = true;
    });

    await supabaseService.uploadStatusRecords();

    setState(() {
      _isUploading = false;
    });

    // Optionally, show a confirmation dialog
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload process completed!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LAE 主界面'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              '欢迎使用LAE系统',
              style: TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _navigateToSurveyPage(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('手动填写今日状态问卷'),
            ),
            const SizedBox(height: 20), // 增加一些间距
            ElevatedButton(
              onPressed: () => _navigateToRecordsPage(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('查看历史状态记录'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isUploading ? null : _handleUpload,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isUploading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('上传数据到云端'),
            ),
          ],
        ),
      ),
    );
  }
}
