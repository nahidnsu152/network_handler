import '../../api_manager.dart';
import 'api_manager_impl.dart';

ApiManager createApiManager(BaseOptions? baseOptions) =>
    ApiManagerImpl(baseOptions: baseOptions);
