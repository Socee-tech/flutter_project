import 'package:get_it/get_it.dart';
import 'package:my_su_re/services/auth_service.dart';
import 'package:my_su_re/services/firestore_service.dart';
import 'package:my_su_re/services/navigation_service.dart';
import 'package:my_su_re/services/role_service.dart';
import 'package:my_su_re/services/storage_service.dart';

GetIt locator = GetIt.instance;

void setupLocator() {
  locator.registerLazySingleton(() => NavigationService());
  locator.registerLazySingleton(() => AuthService());
  locator.registerLazySingleton(() => RoleService());
  locator.registerLazySingleton(() => FirestoreService());
  locator.registerLazySingleton(() => StorageService());
}