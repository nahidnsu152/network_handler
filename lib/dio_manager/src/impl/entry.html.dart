import '../../api_manager.dart';
import 'api_manager_impl_web.dart';

ApiManager createApiManager(BaseOptions? baseOptions) =>
    ApiManagerImplWeb(baseOptions: baseOptions);
