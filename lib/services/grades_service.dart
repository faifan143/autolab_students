import '../models/grade_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class GradesService {
  /// Get all grades for the authenticated user (current student)
  /// Optionally filter by labId
  static Future<List<GradeModel>> getMyGrades({String? labId}) async {
    final dio = await ApiService.dio;
    final queryParams = labId != null ? {'labId': labId} : null;

    final response = await dio.get(
      ApiEndpoints.myGrades,
      queryParameters: queryParams,
    );

    final List<dynamic> data = _extractGradesList(response.data);
    return data
        .whereType<Map>()
        .map((json) => _normalizeGradeJson(Map<String, dynamic>.from(json)))
        .map((json) => GradeModel.fromJson(json))
        .toList();
  }

  /// Get all grades for the current student (legacy method)
  @Deprecated('Use getMyGrades() instead')
  static Future<List<GradeModel>> getStudentGrades() async {
    return getMyGrades();
  }

  /// Get grades for a specific lab (legacy method)
  @Deprecated('Use getMyGrades(labId: labId) instead')
  static Future<List<GradeModel>> getLabGrades(String labId) async {
    return getMyGrades(labId: labId);
  }

  static List<dynamic> _extractGradesList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is Map) {
      final map = Map<String, dynamic>.from(payload);
      final candidates = [map['data'], map['grades'], map['items']];
      for (final candidate in candidates) {
        if (candidate is List) return candidate;
      }
    }
    return const [];
  }

  static Map<String, dynamic> _normalizeGradeJson(Map<String, dynamic> json) {
    final normalized = Map<String, dynamic>.from(json);

    final labValue = normalized['labId'];
    if (labValue is Map) {
      normalized['labId'] = labValue['_id']?.toString() ?? '';
    } else if (labValue != null) {
      normalized['labId'] = labValue.toString();
    } else {
      normalized['labId'] = '';
    }

    final studentValue = normalized['studentId'];
    if (studentValue is String) {
      normalized['studentId'] = {
        '_id': studentValue,
        'name': '',
        'email': '',
        'role': 'student',
      };
    } else if (studentValue is Map) {
      final studentMap = Map<String, dynamic>.from(studentValue);
      normalized['studentId'] = {
        '_id': (studentMap['_id'] ?? '').toString(),
        'name': (studentMap['name'] ?? '').toString(),
        'email': (studentMap['email'] ?? '').toString(),
        'role': (studentMap['role'] ?? 'student').toString(),
      };
    }

    if (normalized['category'] == null || normalized['category'] == '') {
      normalized['category'] = 'Grade';
    }

    normalized['score'] = (normalized['score'] as num?)?.toDouble() ?? 0.0;
    normalized['maxScore'] = (normalized['maxScore'] as num?)?.toDouble();

    return normalized;
  }
}
