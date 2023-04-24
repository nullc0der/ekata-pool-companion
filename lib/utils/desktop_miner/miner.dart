import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

enum MinerBinary { xmrig, xmrigCC, ccminer }

enum CCMinerBinaryVariant { ccminer, ccminerVerus }

class MinerService {
  bool _initialized = false;
  Process? _minerProcess;
  String? _executablePath;
  List<String>? _minerProcessArgs;
  final StreamController<String> _logStream =
      StreamController<String>.broadcast();
  static final MinerService _instance = MinerService._();

  MinerService._();

  static MinerService get instance => _instance;

  Stream<String> get logStream => _logStream.stream;

  bool get initialized => _initialized;

  void _checkInitArgsExist(List<String> args, Map<String, dynamic> initArgs) {
    for (final arg in args) {
      if (initArgs[arg] == null) {
        throw Exception("$arg can't be null");
      }
      if (initArgs[arg] is String && initArgs[arg].isEmpty) {
        throw Exception("$arg can't be empty");
      }
    }
  }

  void _initializeXmrigMiner(Map<String, dynamic> initArgs) {
    _checkInitArgsExist(["minerConfigPath"], initArgs);
    _executablePath = path.join(
        Directory.current.path, 'bin/xmrig${Platform.isWindows ? ".exe" : ""}');
    _minerProcessArgs = [
      "--config=${initArgs["minerConfigPath"]}",
      "--http-host=127.0.0.1",
      "--http-port=45580",
      "--cpu-no-yield"
    ];
    if (initArgs["threadCount"] != null) {
      _minerProcessArgs?.add("--threads=${initArgs["threadCount"].toString()}");
    }
  }

  void _initializeXmrigCCMiner(Map<String, dynamic> initArgs) {
    _checkInitArgsExist(
        ["minerConfigPath", "xmrigCCServerUrl", "xmrigCCServerToken"],
        initArgs);
    _executablePath = path.join(Directory.current.path,
        'bin/xmrigDaemon${Platform.isWindows ? ".exe" : ""}');
    _minerProcessArgs = [
      "--config=${initArgs["minerConfigPath"]}",
      "--http-host=127.0.0.1",
      "--http-port=45580",
      "--cc-url=${initArgs["xmrigCCServerUrl"]}",
      "--cc-access-token=${initArgs["xmrigCCServerToken"]}",
      "--cpu-no-yield"
    ];
    if (initArgs["threadCount"] != null) {
      _minerProcessArgs?.add("--threads=${initArgs["threadCount"].toString()}");
    }
    if (initArgs["xmrigCCWorkerId"]?.isNotEmpty ?? false) {
      _minerProcessArgs?.add("--cc-worker-id=${initArgs["xmrigCCWorkerId"]}");
    }
  }

  void _initializeCCMiner(Map<String, dynamic> initArgs) {
    _checkInitArgsExist(
        ["algo", "poolUrl", "userName", "ccMinerBinaryVariant"], initArgs);
    _executablePath = path.join(Directory.current.path,
        "bin/${initArgs["ccMinerBinaryVariant"] == CCMinerBinaryVariant.ccminer ? "ccminer" : "ccminer-verus"}${Platform.isWindows ? ".exe" : ""}");
    _minerProcessArgs = [
      "--algo=${initArgs["algo"]}",
      "--url=stratum+tcp://${initArgs["poolUrl"]}",
      "--user=${initArgs["userName"]}${initArgs["rigId"]?.isNotEmpty ?? false ? ".${initArgs["rigId"]}" : ""}",
      "--pass=${initArgs["passWord"]?.isNotEmpty ?? false ? initArgs["passWord"] : ""}",
      "--api-bind=127.0.0.1:44690",
      "--api-allow=127.0.0.1",
    ];
    if (initArgs["threadCount"] != null) {
      _minerProcessArgs?.add("--threads=${initArgs["threadCount"].toString()}");
    }
  }

  void initialize(Map<String, dynamic> initArgs, MinerBinary minerBinary) {
    switch (minerBinary) {
      case MinerBinary.xmrig:
        _initializeXmrigMiner(initArgs);
        break;
      case MinerBinary.xmrigCC:
        _initializeXmrigCCMiner(initArgs);
        break;
      case MinerBinary.ccminer:
        _initializeCCMiner(initArgs);
        break;
    }
    _initialized = true;
  }

  void clean() {
    _executablePath = null;
    _minerProcessArgs = null;
    _initialized = false;
  }

  Future<bool> startMining() async {
    if (_executablePath != null && _minerProcessArgs != null) {
      _minerProcess = await Process.start(_executablePath!, _minerProcessArgs!);
      if (_minerProcess != null) {
        _minerProcess!.stdout.transform(utf8.decoder).forEach((element) {
          _logStream.add(element);
        });
        return true;
      }
    }
    return false;
  }

  bool stopMining() {
    return _minerProcess?.kill() ?? false;
  }
}

class DesktopMinerUtil {
  String? _minerConfigPath;
  int? _threadCount;
  Process? _minerProcess;
  MinerBinary? _currentMinerBinary;
  String? _xmrigCCServerUrl;
  String? _xmrigCCServerToken;
  String? _xmrigCCWorkerId;
  bool initialized = false;
  static final DesktopMinerUtil instance = DesktopMinerUtil._internal();
  final StreamController<String> _logStream =
      StreamController<String>.broadcast();

  DesktopMinerUtil._internal();

  Stream<String> get logStream => _logStream.stream;

  void initialize(
      {required MinerBinary? currentMinerBinary,
      required String? minerConfigPath,
      int? threadCount,
      String? xmrigCCServerUrl,
      String? xmrigCCServerToken,
      String? xmrigCCWorkerId}) {
    _minerConfigPath = minerConfigPath;
    _threadCount = threadCount;
    _currentMinerBinary = currentMinerBinary;
    if (_currentMinerBinary == MinerBinary.xmrigCC) {
      if (xmrigCCServerUrl == null || xmrigCCServerToken == null) {
        throw Exception(
            "You must provide xmrigCCServerUrl and xmrigCCServerToken"
            " if miner binary is xmrigcc");
      }
      _xmrigCCServerUrl = xmrigCCServerUrl;
      _xmrigCCServerToken = xmrigCCServerToken;
      _xmrigCCWorkerId = xmrigCCWorkerId;
    }
    initialized = true;
  }

  void clean() {
    _minerConfigPath = null;
    _threadCount = null;
    _currentMinerBinary = null;
    _xmrigCCServerUrl = null;
    _xmrigCCServerToken = null;
    _xmrigCCWorkerId = null;
    initialized = false;
  }

  Future<bool> startMining() async {
    String executablePath = "";
    if (Platform.isLinux) {
      executablePath = path.join(Directory.current.path,
          'bin/${_currentMinerBinary == MinerBinary.xmrig ? "xmrig" : "xmrigDaemon"}');
    }
    if (Platform.isWindows) {
      executablePath = path.join(Directory.current.path,
          'bin\\${_currentMinerBinary == MinerBinary.xmrig ? "xmrig" : "xmrigDaemon"}.exe');
    }
    final minerProcessArgs = [
      "--config=$_minerConfigPath",
      "--http-host=127.0.0.1",
      "--http-port=45580",
      "--cpu-no-yield"
    ];
    if (_threadCount != null) {
      minerProcessArgs.add("--threads=${_threadCount.toString()}");
    }
    if (_currentMinerBinary == MinerBinary.xmrigCC) {
      minerProcessArgs.add("--cc-url=$_xmrigCCServerUrl");
      minerProcessArgs.add("--cc-access-token=$_xmrigCCServerToken");
      if (_xmrigCCWorkerId != null && _xmrigCCWorkerId!.isNotEmpty) {
        minerProcessArgs.add("--cc-worker-id=$_xmrigCCWorkerId");
      }
    }
    _minerProcess = await Process.start(executablePath, minerProcessArgs);
    if (_minerProcess != null) {
      _minerProcess!.stdout.transform(utf8.decoder).forEach((element) {
        _logStream.add(element);
      });
      return true;
    }
    return false;
  }

  bool stopMining() {
    return _minerProcess?.kill() ?? false;
  }
}
