import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../../core/constants/api_constants.dart';

/// User profile model
class UserProfile {
  final String id;
  final String email;
  final String? username;
  final String? skinType;
  final String? skinCondition;
  final List<String>? categories;  // 추가
  final int? age;
  final String? gender;

  UserProfile({
    required this.id,
    required this.email,
    this.username,
    this.skinType,
    this.skinCondition,
    this.categories,  // 추가
    this.age,
    this.gender,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    print('📋 UserProfile.fromJson: Parsing response');
    print('   Raw JSON: $json');

    final id = json['id'] as String? ?? json['user_id'] as String? ?? '';
    final email = json['email'] as String? ?? '';
    final username = json['username'] as String?;
    
    // skin_profile 객체 확인
    String? skinType;
    String? skinCondition;
    List<String>? categories;
    
    if (json['skin_profile'] != null && json['skin_profile'] is Map) {
      final skinProfile = json['skin_profile'] as Map<String, dynamic>;
      skinType = skinProfile['skin_type'] as String?;
      skinCondition = skinProfile['skin_condition'] as String?;
      categories = (skinProfile['categories'] as List<dynamic>?)?.cast<String>();
      print('   Found skin_profile object:');
      print('     skin_type: $skinType');
      print('     skin_condition: $skinCondition');
      print('     categories: $categories');
    } else {
      // fallback: 직접 필드에서 읽기
      skinType = json['skin_type'] as String? ?? json['skinType'] as String?;
      skinCondition = json['skin_condition'] as String? ?? json['skinCondition'] as String?;
      categories = (json['categories'] as List<dynamic>?)?.cast<String>();
    }
    
    final age = json['age'] as int?;
    final gender = json['gender'] as String?;

    print('   Parsed values:');
    print('     id: $id');
    print('     email: $email');
    print('     username: $username');
    print('     skinType: $skinType');
    print('     skinCondition: $skinCondition');
    print('     categories: $categories');
    print('     age: $age');
    print('     gender: $gender');

    return UserProfile(
      id: id,
      email: email,
      username: username,
      skinType: skinType,
      skinCondition: skinCondition,
      categories: categories,
      age: age,
      gender: gender,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {};
    
    // 서버가 email을 필수로 요구하므로 항상 포함
    json['email'] = email;
    
    if (username != null && username!.isNotEmpty) json['username'] = username;
    if (age != null && age! > 0) json['age'] = age;
    if (gender != null && gender!.isNotEmpty) json['gender'] = gender;
    
    // skin_profile 구조로 변경
    final Map<String, dynamic> skinProfile = {};
    bool hasSkinData = false;
    
    if (skinType != null && skinType!.isNotEmpty) {
      skinProfile['skin_type'] = skinType;
      hasSkinData = true;
    }
    if (skinCondition != null && skinCondition!.isNotEmpty) {
      skinProfile['skin_condition'] = skinCondition;
      hasSkinData = true;
    }
    if (categories != null && categories!.isNotEmpty) {
      skinProfile['categories'] = categories;
      hasSkinData = true;
    }
    
    // skin_profile에 데이터가 있을 때만 포함
    if (hasSkinData) {
      json['skin_profile'] = skinProfile;
    }
    
    print('📦 UserProfile.toJson():');
    print('   JSON to send: $json');
    
    return json;
  }
}

/// Provider for getting user profile
/// keepAlive: false로 설정하여 캐싱하지 않음 - 매번 새로 데이터 받아오기
final userProfileProvider = FutureProvider.autoDispose<UserProfile>((
  ref,
) async {
  const storage = FlutterSecureStorage();
  final accessToken = await storage.read(key: 'access_token');

  print(
    '📱 userProfileProvider: Fetching user profile (autoDispose - no cache)',
  );
  print(
    '📱 userProfileProvider: accessToken = ${accessToken?.substring(0, 20)}...',
  );

  if (accessToken == null || accessToken.isEmpty) {
    throw Exception('No access token found. Please login again.');
  }

  final dio = Dio();
  dio.options.baseUrl = ApiConstants.baseUrl;
  dio.options.headers = {
    'Authorization': 'Bearer $accessToken',
    'Content-Type': 'application/json',
  };

  print(
    '📱 userProfileProvider: Fetching from ${ApiConstants.baseUrl}${ApiConstants.userProfileEndpoint}',
  );

  try {
    final response = await dio.get(ApiConstants.userProfileEndpoint);

    print('📱 userProfileProvider: Response status = ${response.statusCode}');
    print('📱 userProfileProvider: Full response data = ${response.data}');
    print(
      '📱 userProfileProvider: Response data type = ${response.data.runtimeType}',
    );

    if (response.statusCode == 200) {
      // API 응답 구조 확인
      if (response.data is Map && response.data.containsKey('data')) {
        print('📱 userProfileProvider: Found "data" key, parsing data object');
        final profile = UserProfile.fromJson(response.data['data']);
        print(
          '📱 userProfileProvider: ✅ Profile loaded successfully: ${profile.username} (${profile.email})',
        );
        return profile;
      } else {
        print(
          '📱 userProfileProvider: No "data" key, parsing response directly',
        );
        final profile = UserProfile.fromJson(response.data);
        print(
          '📱 userProfileProvider: ✅ Profile loaded successfully: ${profile.username} (${profile.email})',
        );
        return profile;
      }
    } else {
      throw Exception('Failed to fetch user profile: ${response.statusCode}');
    }
  } on DioException catch (e) {
    print('❌ userProfileProvider: DioException: ${e.message}');
    print('❌ userProfileProvider: Status code: ${e.response?.statusCode}');
    print('❌ userProfileProvider: Response data: ${e.response?.data}');
    print('❌ userProfileProvider: Error type: ${e.type}');

    // 404 에러일 경우 더미 프로필 반환
    if (e.response?.statusCode == 404) {
      print(
        '⚠️ userProfileProvider: /users/user endpoint not found, using dummy profile',
      );
      final email = await storage.read(key: 'user_email') ?? 'user@example.com';
      return UserProfile(id: 'unknown', email: email, username: 'User');
    }

    // Connection refused 또는 네트워크 에러일 경우 더미 프로필 반환
    if (e.type == DioExceptionType.connectionError ||
        e.message?.contains('Connection refused') == true ||
        e.message?.contains('connection errored') == true) {
      print('⚠️ userProfileProvider: Connection error, using dummy profile');
      final email = await storage.read(key: 'user_email') ?? 'user@example.com';
      return UserProfile(id: 'unknown', email: email, username: 'User');
    }

    throw Exception('Error fetching user profile: ${e.message}');
  } catch (e) {
    print('❌ userProfileProvider: Exception: $e');
    throw Exception('Error fetching user profile: $e');
  }
});

/// Provider for updating user profile
final updateUserProfileProvider =
    FutureProvider.family<UserProfile, UserProfile>((ref, userProfile) async {
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');

      if (accessToken == null || accessToken.isEmpty) {
        throw Exception('No access token found');
      }

      final dio = Dio();
      dio.options.baseUrl = ApiConstants.baseUrl;
      dio.options.headers = {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

      try {
        print('🚀 Sending PUT request to: ${ApiConstants.updateUserProfileEndpoint}');
        print('📦 Request data: ${userProfile.toJson()}');
        
        final response = await dio.put(
          ApiConstants.updateUserProfileEndpoint,
          data: userProfile.toJson(),
        );

        print('✅ Response status: ${response.statusCode}');
        print('📦 Response data: ${response.data}');

        if (response.statusCode == 200 || response.statusCode == 201) {
          // 프로필 캠시 무효화
          ref.invalidate(userProfileProvider);
          return UserProfile.fromJson(response.data);
        } else {
          throw Exception(
            'Failed to update user profile: ${response.statusCode}',
          );
        }
      } on DioException catch (e) {
        print('❌ DioException occurred:');
        print('   Status code: ${e.response?.statusCode}');
        print('   Response data: ${e.response?.data}');
        print('   Error message: ${e.message}');
        throw Exception('Error updating user profile: ${e.response?.data ?? e.message}');
      } catch (e) {
        print('❌ General exception: $e');
        throw Exception('Error updating user profile: $e');
      }
    });
