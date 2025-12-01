// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GradeModel _$GradeModelFromJson(Map<String, dynamic> json) => GradeModel(
      id: json['id'] as String,
      labId: json['labId'] as String,
      category: json['category'] as String,
      score: (json['score'] as num).toDouble(),
      maxScore: (json['maxScore'] as num).toDouble(),
      percentage: (json['percentage'] as num).toDouble(),
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$GradeModelToJson(GradeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'labId': instance.labId,
      'category': instance.category,
      'score': instance.score,
      'maxScore': instance.maxScore,
      'percentage': instance.percentage,
      'comment': instance.comment,
    };
