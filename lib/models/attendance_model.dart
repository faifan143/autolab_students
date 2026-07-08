import 'package:json_annotation/json_annotation.dart';

part 'attendance_model.g.dart';

@JsonSerializable()
class AttendanceModel {
  final String id;
  final String sessionId;
  final String studentId;
  final String status;
  @JsonKey(name: 'scannedAt')
  final DateTime timestamp;

  AttendanceModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.status,
    required this.timestamp,
  });

  factory AttendanceModel.fromJson(Map<String, dynamic> json) =>
      _$AttendanceModelFromJson(json);

  Map<String, dynamic> toJson() => _$AttendanceModelToJson(this);
}

@JsonSerializable()
class StudentCheckInQrResponse {
  final String token;
  final String expiresAt;

  StudentCheckInQrResponse({
    required this.token,
    required this.expiresAt,
  });

  factory StudentCheckInQrResponse.fromJson(Map<String, dynamic> json) =>
      _$StudentCheckInQrResponseFromJson(json);

  Map<String, dynamic> toJson() => _$StudentCheckInQrResponseToJson(this);
}
