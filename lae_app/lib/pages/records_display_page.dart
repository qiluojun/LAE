import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/status_record.dart';
import '../services/database_helper.dart';

class RecordsDisplayPage extends StatefulWidget {
  const RecordsDisplayPage({super.key});

  @override
  State<RecordsDisplayPage> createState() => _RecordsDisplayPageState();
}

class _RecordsDisplayPageState extends State<RecordsDisplayPage> {
  late Future<List<StatusRecord>> _recordsFuture;

  @override
  void initState() {
    super.initState();
    _recordsFuture = DatabaseHelper().getAllStatusRecords();
  }

  // 新增：构建详情文本的辅助函数
  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value ?? '未提供')),
        ],
      ),
    );
  }

  // 新增：刷新记录列表的函数
  void _refreshRecords() {
    setState(() {
      _recordsFuture = DatabaseHelper().getAllStatusRecords();
    });
  }

  // 新增：显示详情弹窗的函数
  void _showRecordDetails(BuildContext context, StatusRecord record) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(DateFormat('yyyy-MM-dd HH:mm').format(record.recordTime)),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDetailRow(
                    '整体状态', record.overallState?.toStringAsFixed(1)),
                _buildDetailRow(
                    '焦虑水平', record.anxietyLevel?.toStringAsFixed(1)),
                _buildDetailRow(
                    '睡眠质量', record.sleepQuality?.toStringAsFixed(1)),
                _buildDetailRow('LAE状态', record.laeState?.toStringAsFixed(1)),
                _buildDetailRow(
                    '运动状态', record.exerciseState?.toStringAsFixed(1)),
                _buildDetailRow(
                    '科研状态', record.researchState?.toStringAsFixed(1)),
                _buildDetailRow('昨晚睡着时间', record.sleepTime),
                _buildDetailRow('今早离开床的时间', record.wakeUpTime),
                _buildDetailRow('昨夜入睡用时', record.timeToFallAsleep),
                _buildDetailRow('今早起床用时', record.timeToGetUp),
                _buildDetailRow('睡眠相关异常', record.sleepAbnormalities),
                _buildDetailRow('饮食情况', record.dietInfo),
                _buildDetailRow('备注', record.remarks),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('删除'),
              onPressed: () async {
                if (record.id != null) {
                  await DatabaseHelper().deleteStatusRecord(record.id!);
                  if (mounted) {
                    Navigator.of(context).pop(); // Close the dialog
                    _refreshRecords(); // Refresh the list
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('记录已删除')),
                    );
                  }
                }
              },
            ),
            TextButton(
              child: const Text('关闭'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史状态记录'),
      ),
      body: FutureBuilder<List<StatusRecord>>(
        future: _recordsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('发生错误: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('没有找到任何记录。'));
          } else {
            final records = snapshot.data!;
            return ListView.builder(
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                // 创建一个摘要字符串，并处理null值
                final overallStateStr =
                    record.overallState?.toStringAsFixed(1) ?? 'N/A';
                final sleepQualityStr =
                    record.sleepQuality?.toStringAsFixed(1) ?? 'N/A';
                final laeStateStr =
                    record.laeState?.toStringAsFixed(1) ?? 'N/A';

                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    title: Text(
                        '记录于: ${DateFormat('yyyy-MM-dd HH:mm').format(record.recordTime)}'),
                    subtitle: Text(
                        '整体: $overallStateStr / 睡眠: $sleepQualityStr / LAE: $laeStateStr'),
                    onTap: () {
                      // 点击时显示完整详情
                      _showRecordDetails(context, record);
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
