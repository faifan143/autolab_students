// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'file_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FileModel _$FileModelFromJson(Map<String, dynamic> json) => FileModel(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      size: (json['size'] as num).toInt(),
      labId: json['labId'] as String,
      sessionId: json['sessionId'] as String?,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$FileModelToJson(FileModel instance) => <String, dynamic>{
      'id': instance.id,
      'fileName': instance.fileName,
      'size': instance.size,
      'labId': instance.labId,
      'sessionId': instance.sessionId,
      'ownerId': instance.ownerId,
      'createdAt': instance.createdAt.toIso8601String(),
    };
