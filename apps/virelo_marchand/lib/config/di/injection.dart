import 'package:get_it/get_it.dart';
import 'package:virelo_core/network/api_client.dart';
import '../../core/services/offline_sync_service.dart';
import '../../core/services/auto_sync_manager.dart';

final GetIt sl = GetIt.instance;

Future<void> initDependencies() async {
  final apiClient = ApiClient();
  sl.registerLazySingleton(() => apiClient);
  
  final offlineSyncService = OfflineSyncService(apiClient);
  sl.registerLazySingleton(() => offlineSyncService);
  
  AutoSyncManager().initialize(offlineSyncService);
}
