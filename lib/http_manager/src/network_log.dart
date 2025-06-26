import 'package:talker/talker.dart';

class NetworkLog {
  final Talker _talker = Talker();

  void init() {
    _talker.configure(
      settings: TalkerSettings(enabled: true, useConsoleLogs: true),
    );
  }

  void printResponse({required String json, required bool canPrint}) {
    if (canPrint) {
      _talker.info('[RESPONSE] $json');
    }
  }

  void printError({required String error, required bool canPrint}) {
    if (canPrint) {
      _talker.error('[ERROR] $error');
    }
  }

  void printSuccess({required String msg, required bool canPrint}) {
    if (canPrint) {
      _talker.info('[SUCCESS] $msg');
    }
  }

  void printWarning({required String warn, required bool canPrint}) {
    if (canPrint) {
      _talker.warning('[WARNING] $warn');
    }
  }

  void printInfo({required String info, required bool canPrint}) {
    if (canPrint) {
      _talker.debug('[INFO] $info');
    }
  }
}
