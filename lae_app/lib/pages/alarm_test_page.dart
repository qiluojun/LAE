import 'package:flutter/material.dart';
import '../services/alarm_manager_service.dart';
import '../services/permission_service.dart';

class AlarmTestPage extends StatefulWidget {
  const AlarmTestPage({super.key});

  @override
  State<AlarmTestPage> createState() => _AlarmTestPageState();
}

class _AlarmTestPageState extends State<AlarmTestPage> {
  String _statusText = '准备测试AlarmManager功能';
  bool _isLoading = false;
  Map<String, bool> _permissions = {};

  @override
  void initState() {
    super.initState();
    _initializeAndCheckPermissions();
  }

  Future<void> _initializeAndCheckPermissions() async {
    setState(() {
      _isLoading = true;
      _statusText = '正在检查权限和初始化AlarmManager...';
    });

    // 检查权限
    final permissions = await PermissionService.checkAllPermissions();
    
    // 初始化AlarmManager
    final success = await AlarmManagerService.initialize();
    
    setState(() {
      _isLoading = false;
      _permissions = permissions;
      
      final missingPermissions = PermissionService.getMissingPermissions(permissions);
      if (missingPermissions.isNotEmpty) {
        _statusText = 'AlarmManager${success ? "初始化成功" : "初始化失败"}，但缺少权限: ${missingPermissions.join(", ")}';
      } else {
        _statusText = 'AlarmManager${success ? "初始化成功" : "初始化失败"}，所有权限已授予';
      }
    });
  }

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
      _statusText = '正在请求权限...';
    });

    final results = await PermissionService.requestAllPermissions();
    
    setState(() {
      _isLoading = false;
      _permissions = results;
      
      final missingPermissions = PermissionService.getMissingPermissions(results);
      if (missingPermissions.isEmpty) {
        _statusText = '所有权限已获取！';
        _showSnackBar('权限配置完成，可以开始测试', Colors.green);
      } else {
        _statusText = '仍缺少权限: ${missingPermissions.join(", ")}';
        _showSnackBar('部分权限未授予，可能影响功能', Colors.orange);
      }
    });
  }

  Future<void> _scheduleTestAlarm(int seconds) async {
    setState(() {
      _isLoading = true;
      _statusText = '正在调度${seconds}秒后的测试提醒...';
    });

    final success = await AlarmManagerService.scheduleTestAlarm(
      delaySeconds: seconds,
      title: '测试提醒 - ${seconds}秒',
      content: '这是一个${seconds}秒延时的测试提醒，验证OnePlus设备息屏弹窗功能',
    );

    setState(() {
      _isLoading = false;
      _statusText = success 
        ? '✅ ${seconds}秒测试提醒调度成功！请锁屏等待弹窗...' 
        : '❌ ${seconds}秒测试提醒调度失败！';
    });

    if (success) {
      _showSnackBar('${seconds}秒后将弹出全屏提醒，请锁屏测试', Colors.green);
    } else {
      _showSnackBar('调度失败，请检查权限设置', Colors.red);
    }
  }

  /// 新增：原生AlarmManager测试方法
  Future<void> _scheduleNativeTestAlarm(int seconds) async {
    setState(() {
      _isLoading = true;
      _statusText = '🆕 正在调度原生${seconds}秒后的测试提醒（绕过Flutter回调隔离）...';
    });

    final success = await AlarmManagerService.scheduleNativeTestAlarm(
      delaySeconds: seconds,
      title: '原生测试提醒 - ${seconds}秒',
      content: '这是原生AlarmManager测试，${seconds}秒延时，绕过Flutter回调隔离问题',
    );
    
    setState(() {
      _isLoading = false;
      if (success) {
        _statusText = '✅ 原生${seconds}秒后的提醒已调度成功！应该能在OnePlus上工作';
        _showSnackBar('原生提醒调度成功！${seconds}秒后将弹出全屏提醒', Colors.purple);
      } else {
        _statusText = '❌ 原生${seconds}秒后的提醒调度失败';
        _showSnackBar('原生提醒调度失败，请检查权限设置', Colors.red);
      }
    });
  }

  Future<void> _cancelAllAlarms() async {
    setState(() {
      _isLoading = true;
      _statusText = '正在取消所有提醒...';
    });

    final success = await AlarmManagerService.cancelAllAlarms();
    
    setState(() {
      _isLoading = false;
      _statusText = success ? '✅ 所有提醒已取消' : '❌ 取消提醒失败';
    });
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Widget _buildPermissionRow(String name, bool granted) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(name),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AlarmManager测试'),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '测试说明',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• 点击下面的按钮调度测试提醒\n'
                      '• 锁屏等待指定时间\n'
                      '• 验证是否能在息屏状态下弹出全屏提醒\n'
                      '• 这将测试OnePlus设备的兼容性',
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _statusText,
                      style: const TextStyle(fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 权限状态显示
            Card(
              color: _permissions.isNotEmpty && PermissionService.areAllPermissionsGranted(_permissions) 
                  ? Colors.green.shade50 
                  : Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '权限状态',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    if (_permissions.isNotEmpty) ...[
                      _buildPermissionRow('通知权限', _permissions['notification'] ?? false),
                      _buildPermissionRow('悬浮窗权限', _permissions['systemAlertWindow'] ?? false),
                      _buildPermissionRow('精确闹钟权限', _permissions['exactAlarm'] ?? false),
                      _buildPermissionRow('电池优化白名单', _permissions['batteryOptimization'] ?? false),
                    ] else
                      const Text('正在检查权限...'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 权限管理按钮
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _requestPermissions,
                    icon: const Icon(Icons.security),
                    label: const Text('请求权限'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () async {
                      await PermissionService.openSystemSettings();
                    },
                    icon: const Icon(Icons.settings),
                    label: const Text('系统设置'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            const Text(
              '测试提醒调度',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _scheduleTestAlarm(10),
                    child: const Text('10秒后'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _scheduleTestAlarm(30),
                    child: const Text('30秒后'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _scheduleTestAlarm(60),
                    child: const Text('1分钟后'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _scheduleTestAlarm(300),
                    child: const Text('5分钟后'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // 原生AlarmManager测试区域
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.purple, width: 2),
                borderRadius: BorderRadius.circular(8),
                color: Colors.purple.shade50,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    '🆕 原生AlarmManager测试 (解决回调隔离问题)',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '使用原生BroadcastReceiver，绕过Flutter回调隔离问题',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  
                  // 原生测试按钮
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _scheduleNativeTestAlarm(10),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          child: const Text('原生10秒', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _scheduleNativeTestAlarm(30),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          child: const Text('原生30秒', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _scheduleNativeTestAlarm(60),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          child: const Text('原生1分钟', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () => _scheduleNativeTestAlarm(300),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                          child: const Text('原生5分钟', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // 直接测试按钮
            ElevatedButton.icon(
              onPressed: _isLoading ? null : () async {
                try {
                  await AlarmManagerService.platform.invokeMethod('launchAlarmActivity', {
                    'title': '直接测试',
                    'content': '这是直接调用MethodChannel的测试',
                  });
                  _showSnackBar('直接调用成功！Activity应该已启动', Colors.green);
                } catch (e) {
                  _showSnackBar('直接调用失败: $e', Colors.red);
                }
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('直接测试Activity'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _cancelAllAlarms,
              icon: const Icon(Icons.cancel),
              label: const Text('取消所有提醒'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 24),
            
            const Card(
              color: Colors.orange,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⚠️ 重要提示',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '如果提醒不能正常弹出，请检查：\n'
                      '• 应用的所有权限都已开启\n'
                      '• 电池优化已关闭\n'
                      '• 后台应用管理已设置为允许\n'
                      '• OnePlus系统需特别注意悬浮窗权限',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}