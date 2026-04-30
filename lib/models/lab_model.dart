import 'package:json_annotation/json_annotation.dart';

part 'lab_model.g.dart';

@JsonSerializable()
class LabModel {
  final String id;
  final String name;
  final String teacherName;
  final String? description;
  @JsonKey(name: 'teacherId')
  final String? teacherId;

  LabModel({
    required this.id,
    required this.name,
    required this.teacherName,
    this.description,
    this.teacherId,
  });

  factory LabModel.fromJson(Map<String, dynamic> json) {
    // Handle case where API returns teacherId but not teacherName
    final teacherName =
        json['teacherName'] as String? ??
        (json['teacherId'] != null
            ? 'Teacher ID: ${json['teacherId']}'
            : 'Unknown Teacher');

    return LabModel(
      id: json['id'] as String,
      name: json['name'] as String,
      teacherName: teacherName,
      description: json['description'] as String?,
      teacherId: json['teacherId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'teacherName': teacherName,
      if (description != null) 'description': description,
      if (teacherId != null) 'teacherId': teacherId,
    };
    return map;
  }
}
