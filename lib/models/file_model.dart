import 'package:json_annotation/json_annotation.dart';

part 'file_model.g.dart';

@JsonSerializable()
class FileModel {
  @JsonKey(name: 'id')
  final String id;

  @JsonKey(name: 'fileName')
  final String fileName;

  @JsonKey(name: 'mimeType')
  final String mimeType;

  @JsonKey(name: 'size')
  final int size;

  @JsonKey(name: 'ownerId', includeIfNull: false)
  final String? ownerId;

  @JsonKey(name: 'labId', includeIfNull: false)
  final String? labId;

  @JsonKey(name: 'sessionId', includeIfNull: false)
  final String? sessionId;

  @JsonKey(name: 'storageKey')
  final String storageKey;

  @JsonKey(name: 'version', includeIfNull: false)
  final int? version;

  @JsonKey(name: 'description', includeIfNull: false)
  final String? description;

  @JsonKey(name: 'createdAt', includeIfNull: false)
  final DateTime? createdAt;

  @JsonKey(name: 'updatedAt', includeIfNull: false)
  final DateTime? updatedAt;

  FileModel({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.size,
    this.ownerId,
    this.labId,
    this.sessionId,
    required this.storageKey,
    this.version,
    this.description,
    this.createdAt,
    this.updatedAt,
  });

  factory FileModel.fromJson(Map<String, dynamic> json) =>
      _$FileModelFromJson(json);

  Map<String, dynamic> toJson() => _$FileModelToJson(this);
}
