import 'package:json_annotation/json_annotation.dart';

part 'grade_model.g.dart';

@JsonSerializable()
class GradeModel {
  final String id;
  final String labId;
  final String category;
  final double score;
  final double maxScore;
  final double percentage;
  final String? comment;

  GradeModel({
    required this.id,
    required this.labId,
    required this.category,
    required this.score,
    required this.maxScore,
    required this.percentage,
    this.comment,
  });

  factory GradeModel.fromJson(Map<String, dynamic> json) =>
      _$GradeModelFromJson(json);

  Map<String, dynamic> toJson() => _$GradeModelToJson(this);
}
