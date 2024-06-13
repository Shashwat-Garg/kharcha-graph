import 'package:get_it/get_it.dart';
import 'package:kharcha_graph/dbcontext/db_context.dart';
import 'package:kharcha_graph/services/transaction_info_service.dart';

GetIt globalLocator = GetIt.instance;

void setupGlobalLocator() {
  globalLocator.registerLazySingleton<DbContext>(() => DbContext());
  globalLocator.registerLazySingleton<TransactionInfoService>(() => TransactionInfoService());
}
