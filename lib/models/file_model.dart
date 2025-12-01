import 'package:json_annotation/json_annotation.dart';

part 'file_model.g.dart';

@JsonSerializable()
class FileModel {
  final String id;
  final String fileName;
  final int size;
  final String labId;
  final String? sessionId;
  final String ownerId;
  final DateTime createdAt;

  FileModel({
    required this.id,
    required this.fileName,
    required this.size,
    required this.labId,
    this.sessionId,
    required this.ownerId,
    required this.createdAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) =>
      _$FileModelFromJson(json);

  Map<String, dynamic> toJson() => _$FileModelToJson(this);
}

