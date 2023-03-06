import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

enum MinerBinary { xmrig, xmrigCC }

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
          'bin/${_currentMinerBinary == MinerBinary.xmrig ? "xmrig" : "xmrigDaemon"}}');
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
