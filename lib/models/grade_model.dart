import 'package:json_annotation/json_annotation.dart';

part 'grade_model.g.dart';

@JsonSerializable()
class StudentInfo {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String email;
  final String role;

  StudentInfo({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) =>
      _$StudentInfoFromJson(json);

  Map<String, dynamic> toJson() => _$StudentInfoToJson(this);
}

@JsonSerializable()
class GradeModel {
  @JsonKey(name: '_id')
  final String id;
  final StudentInfo studentId;
  @JsonKey(name: 'labId')
  final String labId;
  final String category;
  final double score;
  @JsonKey(name: 'maxScore', includeIfNull: false)
  final double? maxScore;
  @JsonKey(name: 'comment', includeIfNull: false)
  final String? comment;
  @JsonKey(name: 'gradedBy', includeIfNull: false)
  final String? gradedBy;
  @JsonKey(name: 'createdAt', includeIfNull: false)
  final DateTime? createdAt;
  @JsonKey(name: 'updatedAt', includeIfNull: false)
  final DateTime? updatedAt;

  GradeModel({
    required this.id,
    required this.studentId,
    required this.labId,
    required this.category,
    required this.score,
    this.maxScore,
    this.comment,
    this.gradedBy,
    this.createdAt,
    this.updatedAt,
  });

  // Computed property for percentage
  double get percentage {
    if (maxScore == null || maxScore == 0) return 0.0;
    return (score / maxScore!) * 100;
  }

  factory GradeModel.fromJson(Map<String, dynamic> json) =>
      _$GradeModelFromJson(json);

  Map<String, dynamic> toJson() => _$GradeModelToJson(this);
}
