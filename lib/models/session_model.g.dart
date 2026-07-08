// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionModel _$SessionModelFromJson(Map<String, dynamic> json) => SessionModel(
  id: json['id'] as String,
  labId: json['labId'] as String,
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: json['endTime'] == null
      ? null
      : DateTime.parse(json['endTime'] as String),
  isStreaming: json['isStreaming'] as bool,
  streamUrl: json['streamUrl'] as String?,
  streamKey: json['streamKey'] as String?,
  recordedVideoUrl: json['recordedVideoUrl'] as String?,
);

Map<String, dynamic> _$SessionModelToJson(SessionModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labId': instance.labId,
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime?.toIso8601String(),
      'isStreaming': instance.isStreaming,
      'streamUrl': instance.streamUrl,
      'streamKey': instance.streamKey,
      'recordedVideoUrl': instance.recordedVideoUrl,
    };
