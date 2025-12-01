import 'package:json_annotation/json_annotation.dart';

part 'lab_model.g.dart';

@JsonSerializable()
class LabModel {
  final String id;
  final String name;
  final String teacherName;
  final String? description;

  LabModel({
    required this.id,
    required this.name,
    required this.teacherName,
    this.description,
  });

  factory LabModel.fromJson(Map<String, dynamic> json) =>
      _$LabModelFromJson(json);

  Map<String, dynamic> toJson() => _$LabModelToJson(this);
}

