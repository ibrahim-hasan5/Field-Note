import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/customer_model.dart';

class CustomerRemoteDataSource {
  final ApiClient _apiClient;

  CustomerRemoteDataSource({required ApiClient apiClient})
      : _apiClient = apiClient;

  Future<List<CustomerModel>> getCustomers() async {
    final response = await _apiClient.dio.get(ApiConstants.customers);
    final data = response.data;
    List list = [];
    if (data is Map && data.containsKey('content')) {
      list = data['content'] as List;
    } else if (data is List) {
      list = data;
    }
    return list
        .map((item) => CustomerModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<CustomerModel> createCustomer(CustomerModel customer) async {
    final response = await _apiClient.dio.post(
      ApiConstants.customers,
      data: customer.toJson(),
    );
    return CustomerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<CustomerModel> updateCustomer(CustomerModel customer) async {
    final response = await _apiClient.dio.put(
      '${ApiConstants.customers}/${customer.id}',
      data: customer.toJson(),
    );
    return CustomerModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> deleteCustomer(String id) async {
    await _apiClient.dio.delete('${ApiConstants.customers}/$id');
  }
}
