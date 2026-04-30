// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentInfo _$StudentInfoFromJson(Map<String, dynamic> json) => StudentInfo(
  id: json['_id'] as String,
  name: json['name'] as String,
  email: json['email'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$StudentInfoToJson(StudentInfo instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'name': instance.name,
      'email': instance.email,
      'role': instance.role,
    };

GradeModel _$GradeModelFromJson(Map<String, dynamic> json) => GradeModel(
  id: json['_id'] as String,
  studentId: StudentInfo.fromJson(json['studentId'] as Map<String, dynamic>),
  labId: json['labId'] as String,
  category: json['category'] as String,
  score: (json['score'] as num).toDouble(),
  maxScore: (json['maxScore'] as num?)?.toDouble(),
  comment: json['comment'] as String?,
  gradedBy: json['gradedBy'] as String?,
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$GradeModelToJson(GradeModel instance) =>
    <String, dynamic>{
      '_id': instance.id,
      'studentId': instance.studentId,
      'labId': instance.labId,
      'category': instance.category,
      'score': instance.score,
      'maxScore': ?instance.maxScore,
      'comment': ?instance.comment,
      'gradedBy': ?instance.gradedBy,
      'createdAt': ?instance.createdAt?.toIso8601String(),
      'updatedAt': ?instance.updatedAt?.toIso8601String(),
    };
