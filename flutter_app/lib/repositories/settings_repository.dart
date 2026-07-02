import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/company_profile.dart';

final settingsRepositoryProvider = Provider((ref) {
  final dio = ref.watch(apiClientProvider);
  return SettingsRepository(dio);
});

final companyProfileProvider = FutureProvider<CompanyProfile>((ref) async {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.getCompanyProfile();
});

class SettingsRepository {
  final Dio _dio;

  SettingsRepository(this._dio);

  Future<CompanyProfile> getCompanyProfile() async {
    try {
      final response = await _dio.get('/settings/company-profile');
      return CompanyProfile.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to load company profile: $e');
    }
  }

  Future<CompanyProfile> saveCompanyProfile(CompanyProfile profile) async {
    try {
      final response = await _dio.post(
        '/settings/company-profile',
        data: profile.toJson(),
      );
      return CompanyProfile.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to save company profile: $e');
    }
  }
}
