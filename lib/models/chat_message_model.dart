import 'package:json_annotation/json_annotation.dart';
import 'user_model.dart';
import 'file_model.dart';

part 'chat_message_model.g.dart';

@JsonSerializable()
class ChatMessageModel {
  final String id;
  final String channel;
  @JsonKey(includeIfNull: false)
  final String? labId;
  final String senderId;
  @JsonKey(includeIfNull: false)
  final UserModel? sender;
  @JsonKey(includeIfNull: false, defaultValue: [])
  final List<String> recipientIds;
  @JsonKey(includeIfNull: false, defaultValue: [])
  final List<UserModel> recipients;
  @JsonKey(includeIfNull: false)
  final String? content;
  @JsonKey(includeIfNull: false, defaultValue: [])
  final List<String> fileIds;
  @JsonKey(includeIfNull: false, defaultValue: [])
  final List<FileModel> files;
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.channel,
    this.labId,
    required this.senderId,
    this.sender,
    List<String>? recipientIds,
    List<UserModel>? recipients,
    this.content,
    List<String>? fileIds,
    List<FileModel>? files,
    required this.createdAt,
  })  : recipientIds = recipientIds ?? [],
        recipients = recipients ?? [],
        fileIds = fileIds ?? [],
        files = files ?? [];

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageModelFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageModelToJson(this);

  // Helper getter for backward compatibility
  String get senderName => sender?.name ?? 'Unknown';
  
  // Helper getter for backward compatibility
  DateTime get timestamp => createdAt;
}
