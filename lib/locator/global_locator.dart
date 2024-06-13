import 'package:get_it/get_it.dart';
import 'package:kharcha_graph/dbcontext/db_context.dart';

GetIt globalLocator = GetIt.instance;

void setupGlobalLocator() {
  globalLocator.registerLazySingleton<DbContext>(() => DbContext());
}
