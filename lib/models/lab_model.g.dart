// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lab_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LabModel _$LabModelFromJson(Map<String, dynamic> json) => LabModel(
      id: json['id'] as String,
      name: json['name'] as String,
      teacherName: json['teacherName'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$LabModelToJson(LabModel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'teacherName': instance.teacherName,
      'description': instance.description,
    };
