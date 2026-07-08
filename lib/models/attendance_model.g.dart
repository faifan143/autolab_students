// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attendance_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttendanceModel _$AttendanceModelFromJson(Map<String, dynamic> json) =>
    AttendanceModel(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      studentId: json['studentId'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['scannedAt'] as String),
    );

Map<String, dynamic> _$AttendanceModelToJson(AttendanceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'studentId': instance.studentId,
      'status': instance.status,
      'scannedAt': instance.timestamp.toIso8601String(),
    };

StudentCheckInQrResponse _$StudentCheckInQrResponseFromJson(
        Map<String, dynamic> json) =>
    StudentCheckInQrResponse(
      token: json['token'] as String,
      expiresAt: json['expiresAt'] as String,
    );

Map<String, dynamic> _$StudentCheckInQrResponseToJson(
        StudentCheckInQrResponse instance) =>
    <String, dynamic>{
      'token': instance.token,
      'expiresAt': instance.expiresAt,
    };
