class ComplaintModel {
  final String id;
  final String content;
  final bool isAnonymous;
  final String status;
  final String? labId;
  final String? teacherId;
  final String? adminNote;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;

  ComplaintModel({
    required this.id,
    required this.content,
    required this.isAnonymous,
    required this.status,
    this.labId,
    this.teacherId,
    this.adminNote,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      isAnonymous: json['isAnonymous'] == true,
      status: json['status']?.toString() ?? 'new',
      labId: json['labId']?.toString(),
      teacherId: json['teacherId']?.toString(),
      adminNote: json['adminNote']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      resolvedAt: json['resolvedAt'] != null
          ? DateTime.tryParse(json['resolvedAt'].toString())
          : null,
    );
  }
}
