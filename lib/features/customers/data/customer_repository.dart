import '../../../core/database/customer_dao.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/customer_model.dart';
import 'customer_remote_data_source.dart';

class CustomerRepository {
  final CustomerDao _customerDao;
  final CustomerRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;

  CustomerRepository({
    required CustomerDao customerDao,
    required CustomerRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
  })  : _customerDao = customerDao,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService;

  Future<List<CustomerModel>> getCustomers({bool refreshRemote = false}) async {
    var localList = <CustomerModel>[];
    try {
      localList = await _customerDao.getAllActiveCustomers();
    } catch (_) {}

    if (refreshRemote || localList.isEmpty) {
      final isOnline = await _connectivityService.isOnline;
      if (isOnline) {
        try {
          final remoteList = await _remoteDataSource.getCustomers();
          for (final c in remoteList) {
            try {
              await _customerDao.insertCustomer(c.copyWith(syncStatus: 'synced'));
            } catch (_) {}
          }
          try {
            return await _customerDao.getAllActiveCustomers();
          } catch (_) {
            return remoteList;
          }
        } catch (e) {
          // If remote fails, local is returned
        }
      }
    }
    return localList;
  }

  Future<void> saveCustomer(CustomerModel customer) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        await _remoteDataSource.createCustomer(customer);
        await _customerDao.insertCustomer(customer.copyWith(syncStatus: 'synced'));
        return;
      } catch (e) {
        // Fall back to offline save
      }
    }
    // Save locally as pending
    await _customerDao.insertCustomer(customer.copyWith(syncStatus: 'pending'));
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        await _remoteDataSource.updateCustomer(customer);
        await _customerDao.updateCustomer(customer.copyWith(syncStatus: 'synced'));
        return;
      } catch (e) {
        // Fall back to offline
      }
    }
    await _customerDao.updateCustomer(customer.copyWith(syncStatus: 'pending'));
  }

  Future<void> deleteCustomer(String id) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        await _remoteDataSource.deleteCustomer(id);
      } catch (e) {
        // Fall back to offline soft delete
      }
    }
    await _customerDao.softDeleteCustomer(id);
  }
}
