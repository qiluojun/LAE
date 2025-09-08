import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:lae_app/services/notification_service.dart';
import 'package:lae_app/services/database_helper.dart';
import 'package:lae_app/pages/status_survey_page.dart';
import 'package:lae_app/pages/records_display_page.dart';
import 'package:lae_app/services/supabase_service.dart'; // Import Supabase service
import 'package:lae_app/pages/planning_data_display_page.dart'; // Import the new page

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

    // Sync planning data on startup
    await supabaseService.syncPlanningData();
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
  bool _isSyncing = false; // Add state for planning data sync

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

  // Add navigation to the new planning data page
  void _navigateToPlanningDataPage(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PlanningDataDisplayPage()),
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

  // Add a new handler for syncing planning data
  Future<void> _handleSync() async {
    setState(() {
      _isSyncing = true;
    });

    await supabaseService.syncPlanningData();

    setState(() {
      _isSyncing = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sync process completed!')),
      );
    }
  }

  // 新增：处理测试提醒的函数
  Future<void> _handleTestNotification() async {
    debugPrint('开始设置测试提醒...');
    try {
      await notificationService.scheduleTestNotification();
      debugPrint('测试提醒设置成功！');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('测试提醒已设置！10秒后将弹出提醒。')),
        );
      }
    } catch (e) {
      debugPrint('设置测试提醒时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置提醒失败: $e')),
        );
      }
    }
  }

  // 新增：处理立即测试提醒的函数
  Future<void> _handleImmediateTestNotification() async {
    debugPrint('开始显示立即测试提醒...');
    try {
      await notificationService.showImmediateTestNotification();
      debugPrint('立即测试提醒显示成功！');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('立即测试提醒已显示！')),
        );
      }
    } catch (e) {
      debugPrint('显示立即测试提醒时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('显示立即提醒失败: $e')),
        );
      }
    }
  }

  // 新增：处理3秒测试提醒的函数
  Future<void> _handleShortTestNotification() async {
    debugPrint('开始设置3秒测试提醒...');
    try {
      await notificationService.scheduleShortTestNotification();
      debugPrint('3秒测试提醒设置成功！');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('3秒测试提醒已设置！')),
        );
      }
    } catch (e) {
      debugPrint('设置3秒测试提醒时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('设置3秒提醒失败: $e')),
        );
      }
    }
  }

  // 新增：处理取消测试提醒的函数
  Future<void> _handleCancelTestNotifications() async {
    debugPrint('开始取消所有测试提醒...');
    try {
      await notificationService.cancelAllTestNotifications();
      debugPrint('测试提醒已取消！');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('所有测试提醒已取消！')),
        );
      }
    } catch (e) {
      debugPrint('取消测试提醒时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('取消提醒失败: $e')),
        );
      }
    }
  }

  // 新增：处理权限检查的函数
  Future<void> _handlePermissionCheck() async {
    debugPrint('开始检查权限...');
    try {
      final permissionStatus =
          await notificationService.checkAndRequestPermissions();
      debugPrint('权限检查完成: $permissionStatus');

      String message = '权限状态:\n';
      message +=
          '通知权限: ${permissionStatus['notification'] == true ? '✅ 已授权' : '❌ 未授权'}\n';
      message +=
          '精确闹钟权限: ${permissionStatus['scheduleExactAlarm'] == true ? '✅ 已授权' : '❌ 未授权'}\n';
      message +=
          '电池优化白名单: ${permissionStatus['ignoreBatteryOptimizations'] == true ? '✅ 已添加' : '❌ 未添加'}';

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('权限检查结果'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('确定'),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      debugPrint('检查权限时出错: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('权限检查失败: $e')),
        );
      }
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
              onPressed: () => _navigateToPlanningDataPage(context),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: const Text('查看计划数据'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSyncing ? null : _handleSync,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: _isSyncing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('同步计划与提醒'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _handleImmediateTestNotification,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.green, // 绿色表示立即测试
              ),
              child: const Text('立即测试提醒'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _handleShortTestNotification,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.blue, // 蓝色表示短时间测试
              ),
              child: const Text('测试短延时提醒（3秒后）'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _handleTestNotification,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.orange, // 橙色表示延时测试
              ),
              child: const Text('测试延时提醒（10秒后）'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _handlePermissionCheck,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.purple, // 紫色表示权限检查
              ),
              child: const Text('检查和请求权限'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _handleCancelTestNotifications,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: const TextStyle(fontSize: 16),
                backgroundColor: Colors.red, // 红色表示取消
              ),
              child: const Text('取消所有测试提醒'),
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
