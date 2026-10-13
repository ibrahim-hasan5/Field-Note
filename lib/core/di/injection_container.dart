import 'package:get_it/get_it.dart';
import '../database/customer_dao.dart';
import '../database/database_helper.dart';
import '../database/field_note_dao.dart';
import '../database/site_dao.dart';
import '../network/api_client.dart';
import '../services/connectivity_service.dart';
import '../services/location_service.dart';
import '../services/sync_engine.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/customers/data/customer_remote_data_source.dart';
import '../../features/customers/data/customer_repository.dart';
import '../../features/sites/data/site_remote_data_source.dart';
import '../../features/sites/data/site_repository.dart';
import '../../features/field_notes/data/field_note_remote_data_source.dart';
import '../../features/field_notes/data/field_note_repository.dart';
import '../../features/settings/data/settings_repository.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<DatabaseHelper>(() => DatabaseHelper.instance);
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<ConnectivityService>(() => ConnectivityService());
  sl.registerLazySingleton<LocationService>(() => LocationService());

  // DAOs
  sl.registerLazySingleton<CustomerDao>(() => CustomerDao(dbHelper: sl()));
  sl.registerLazySingleton<SiteDao>(() => SiteDao(dbHelper: sl()));
  sl.registerLazySingleton<FieldNoteDao>(() => FieldNoteDao(dbHelper: sl()));

  // Data Sources
  sl.registerLazySingleton<CustomerRemoteDataSource>(
      () => CustomerRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<SiteRemoteDataSource>(
      () => SiteRemoteDataSource(apiClient: sl()));
  sl.registerLazySingleton<FieldNoteRemoteDataSource>(
      () => FieldNoteRemoteDataSource(apiClient: sl()));

  // Repositories
  sl.registerLazySingleton<AuthRepository>(
      () => AuthRepository(apiClient: sl()));
  sl.registerLazySingleton<CustomerRepository>(() => CustomerRepository(
        customerDao: sl(),
        remoteDataSource: sl(),
        connectivityService: sl(),
      ));
  sl.registerLazySingleton<SiteRepository>(() => SiteRepository(
        siteDao: sl(),
        remoteDataSource: sl(),
        connectivityService: sl(),
      ));
  sl.registerLazySingleton<FieldNoteRepository>(() => FieldNoteRepository(
        noteDao: sl(),
        remoteDataSource: sl(),
        connectivityService: sl(),
      ));
  sl.registerLazySingleton<SettingsRepository>(() => SettingsRepository.instance);

  // Sync Engine
  sl.registerLazySingleton<SyncEngine>(() => SyncEngine(
        apiClient: sl(),
        connectivityService: sl(),
        customerDao: sl(),
        siteDao: sl(),
        noteDao: sl(),
        noteRemoteSource: sl(),
      ));
}
