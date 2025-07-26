///
/// status_record.dart
///
/// [文件说明]
/// 定义了用户每日状态记录的数据模型 (StatusRecord)。
/// 这个模型对应于 "状态问卷" 功能中的各项数据，包含了用户输入的睡眠、
/// 状态评估、饮食、焦虑水平等信息。
///
/// [主要功能]
/// - 定义 StatusRecord 类的所有字段。
/// - 提供 fromMap 方法，用于将数据库查询结果（Map）转换成 StatusRecord 对象。
/// - 提供 toMap 方法，用于将 StatusRecord 对象转换成 Map，方便存入数据库。
///
/// [未来展望]
/// - 如果未来问卷项目增加，可在此文件中添加新的字段。
/// - 可以考虑添加数据校验逻辑。
///

class StatusRecord {
  final int? id; // 数据库中的唯一ID，自增主键，可以为空
  final DateTime recordTime; // 记录创建时间

  // 问卷项目
  final String sleepTime; // 昨晚睡眠时间 (格式: "HH:mm")
  final String wakeUpTime; // 今早起床时间 (格式: "HH:mm")
  final int sleepQuality; // 睡眠质量 (1-5分)
  final int laeState; // LAE状态评估 (1-5分)
  final int exerciseState; // 运动状态评估 (1-5分)
  final int researchState; // 科研状态评估 (1-5分)
  final String dietInfo; // 饮食情况 (文本输入)
  final double anxietyLevel; // 当前焦虑水平 (1.0-5.0)
  final double overallState; // 当前整体状态 (1.0-5.0)
  final String? remarks; // 备注 (可以为空)

  StatusRecord({
    this.id,
    required this.recordTime,
    required this.sleepTime,
    required this.wakeUpTime,
    required this.sleepQuality,
    required this.laeState,
    required this.exerciseState,
    required this.researchState,
    required this.dietInfo,
    required this.anxietyLevel,
    required this.overallState,
    this.remarks,
  });

  /// 将Map对象转换为StatusRecord对象
  factory StatusRecord.fromMap(Map<String, dynamic> map) {
    return StatusRecord(
      id: map['id'],
      // 将存储的ISO 8601字符串转回DateTime对象
      recordTime: DateTime.parse(map['recordTime']),
      sleepTime: map['sleepTime'],
      wakeUpTime: map['wakeUpTime'],
      sleepQuality: map['sleepQuality'],
      laeState: map['laeState'],
      exerciseState: map['exerciseState'],
      researchState: map['researchState'],
      dietInfo: map['dietInfo'],
      anxietyLevel: map['anxietyLevel'],
      overallState: map['overallState'],
      remarks: map['remarks'],
    );
  }

  /// 将StatusRecord对象转换为Map对象，以便存入数据库
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // 将DateTime对象转换为ISO 8601格式的字符串进行存储
      'recordTime': recordTime.toIso8601String(),
      'sleepTime': sleepTime,
      'wakeUpTime': wakeUpTime,
      'sleepQuality': sleepQuality,
      'laeState': laeState,
      'exerciseState': exerciseState,
      'researchState': researchState,
      'dietInfo': dietInfo,
      'anxietyLevel': anxietyLevel,
      'overallState': overallState,
      'remarks': remarks,
    };
  }
}
