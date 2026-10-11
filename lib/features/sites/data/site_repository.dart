import '../../../core/database/site_dao.dart';
import '../../../core/services/connectivity_service.dart';
import '../models/site_model.dart';
import 'site_remote_data_source.dart';

class SiteRepository {
  final SiteDao _siteDao;
  final SiteRemoteDataSource _remoteDataSource;
  final ConnectivityService _connectivityService;

  SiteRepository({
    required SiteDao siteDao,
    required SiteRemoteDataSource remoteDataSource,
    required ConnectivityService connectivityService,
  })  : _siteDao = siteDao,
        _remoteDataSource = remoteDataSource,
        _connectivityService = connectivityService;

  Future<List<SiteModel>> getSites({String? customerId, bool refreshRemote = false}) async {
    final localList = customerId != null
        ? await _siteDao.getSitesForCustomer(customerId)
        : await _siteDao.getAllActiveSites();

    if (refreshRemote || localList.isEmpty) {
      final isOnline = await _connectivityService.isOnline;
      if (isOnline) {
        try {
          final remoteList = await _remoteDataSource.getSites(customerId: customerId);
          for (final s in remoteList) {
            await _siteDao.insertSite(s.copyWith(syncStatus: 'synced'));
          }
          return customerId != null
              ? await _siteDao.getSitesForCustomer(customerId)
              : await _siteDao.getAllActiveSites();
        } catch (e) {
          // Keep local
        }
      }
    }
    return localList;
  }

  Future<void> saveSite(SiteModel site) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        await _remoteDataSource.createSite(site);
        await _siteDao.insertSite(site.copyWith(syncStatus: 'synced'));
        return;
      } catch (e) {
        // Fall back to offline
      }
    }
    await _siteDao.insertSite(site.copyWith(syncStatus: 'pending'));
  }

  Future<void> updateSite(SiteModel site) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        await _remoteDataSource.updateSite(site);
        await _siteDao.updateSite(site.copyWith(syncStatus: 'synced'));
        return;
      } catch (e) {
        // Fall back to offline
      }
    }
    await _siteDao.updateSite(site.copyWith(syncStatus: 'pending'));
  }

  Future<void> deleteSite(String id) async {
    final isOnline = await _connectivityService.isOnline;
    if (isOnline) {
      try {
        await _remoteDataSource.deleteSite(id);
      } catch (e) {
        // Fall back to offline
      }
    }
    await _siteDao.softDeleteSite(id);
  }
}
