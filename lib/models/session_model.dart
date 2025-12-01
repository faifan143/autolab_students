import 'package:json_annotation/json_annotation.dart';

part 'session_model.g.dart';

@JsonSerializable()
class SessionModel {
  final String id;
  final String labId;
  final DateTime startTime;
  final DateTime? endTime;
  final bool isStreaming;
  final String? recordedVideoUrl;

  SessionModel({
    required this.id,
    required this.labId,
    required this.startTime,
    this.endTime,
    required this.isStreaming,
    this.recordedVideoUrl,
  });

  factory SessionModel.fromJson(Map<String, dynamic> json) =>
      _$SessionModelFromJson(json);

  Map<String, dynamic> toJson() => _$SessionModelToJson(this);
}
