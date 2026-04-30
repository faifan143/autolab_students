import '../models/user_model.dart';
import '../constants/api_endpoints.dart';
import 'api_service.dart';

class UserService {
  /// Get user details by ID (can be used for teachers or students)
  static Future<UserModel> getUserById(String userId) async {
    final dio = await ApiService.dio;
    final response = await dio.get(ApiEndpoints.user(userId));

    return UserModel.fromJson(response.data);
  }
}
