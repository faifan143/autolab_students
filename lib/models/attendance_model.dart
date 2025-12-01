import 'package:json_annotation/json_annotation.dart';

part 'attendance_model.g.dart';

@JsonSerializable()
class AttendanceModel {
  final String id;
  final String labId;
  final String? sessionId;
  final String status; // 'present', 'late', 'absent'
  final DateTime timestamp;

  AttendanceModel({
    required this.id,
    required this.labId,
    this.sessionId,
    required this.status,
    required this.timestamp,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);
}
