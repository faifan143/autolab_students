import '../constants/api_endpoints.dart';
import '../models/complaint_model.dart';
import 'api_service.dart';

class ComplaintsService {
  static Future<List<ComplaintModel>> getMyComplaints() async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.myComplaints);
    final data = response.data as List<dynamic>;
    return data
        .map((item) => ComplaintModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static Future<ComplaintModel> createComplaint({
    required String content,
    bool isAnonymous = false,
    String? labId,
    String? teacherId,
  }) async {
    final dio = await ApiService.dio;
    final payload = <String, dynamic>{
      'content': content.trim(),
      'isAnonymous': isAnonymous,
      if (labId != null && labId.isNotEmpty) 'labId': labId,
      if (teacherId != null && teacherId.isNotEmpty) 'teacherId': teacherId,
    };
    final response = await dio.post(ApiEndpoints.complaints, data: payload);
    return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
  }
}
