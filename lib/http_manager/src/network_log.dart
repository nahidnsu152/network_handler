// import 'package:flutter_easylogger/flutter_logger.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class NetworkLog {
  // init() => Logger.init(
  //       true,
  //       isShowFile: false,
  //       isShowTime: false,
  //       isShowNavigation: true,
  //       levelVerbose: 247,
  //       levelDebug: 15,
  //       levelInfo: 10,
  //       levelWarn: 5,
  //       levelError: 9,
  //       phoneVerbose: Colors.white,
  //       phoneDebug: Colors.lightBlue,
  //       phoneInfo: Colors.greenAccent,
  //       phoneWarn: Colors.orange,
  //       phoneError: Colors.redAccent,
  //     );

  printResponse({required String json, required bool canPrint}) {
    if (canPrint) {
      // Logger.json(json, tag: '');
      PrettyDioLogger(
        responseBody: true,
      );
    }
  }

  printError({required String error, required bool canPrint}) {
    if (canPrint) {
      // Logger.e(error, tag: '');
      PrettyDioLogger(
        error: true,
      );
    }
  }

  printSuccess({required String msg, required bool canPrint}) {
    if (canPrint) {
      // Logger.i(msg, tag: '');
      PrettyDioLogger(
        responseBody: true,
      );
    }
  }

  printWarning({required String warn, required bool canPrint}) {
    if (canPrint) {
      // Logger.w(warn, tag: '');
      PrettyDioLogger(
        error: true,
      );
    }
  }

  printInfo({required String info, required bool canPrint}) {
    if (canPrint) {
      // Logger.d(info, tag: '');
      PrettyDioLogger(
        responseBody: true,
      );
    }
  }
}
