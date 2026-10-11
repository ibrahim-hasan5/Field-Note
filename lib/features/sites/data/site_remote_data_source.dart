import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/site_model.dart';

class SiteRemoteDataSource {
  final ApiClient _apiClient;

  SiteRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<SiteModel>> getSites({String? customerId}) async {
    final url = customerId != null
        ? '${ApiConstants.customers}/$customerId/sites'
        : ApiConstants.sites;
    final response = await _apiClient.dio.get(url);
    final data = response.data;
    List list = [];
    if (data is Map && data.containsKey('content')) {
      list = data['content'] as List;
    } else if (data is List) {
      list = data;
    }
    return list
        .map((item) => SiteModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<SiteModel> createSite(SiteModel site) async {
    final response = await _apiClient.dio.post(
      ApiConstants.sites,
      data: site.toJson(),
    );
    return SiteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<SiteModel> updateSite(SiteModel site) async {
    final response = await _apiClient.dio.put(
      '${ApiConstants.sites}/${site.id}',
      data: site.toJson(),
    );
    return SiteModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteSite(String id) async {
    await _apiClient.dio.delete('${ApiConstants.sites}/$id');
  }
}
