import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class DesktopMinerUtil {
  String? _minerAddress;
  String? _poolHost;
  int? _poolPort;
  String? _coinAlgo;
  Process? _minerProcess;
  bool initialized = false;
  static final DesktopMinerUtil instance = DesktopMinerUtil._internal();
  final StreamController<String> _logStream =
      StreamController<String>.broadcast();

  DesktopMinerUtil._internal();

  Stream<String> get logStream => _logStream.stream;

  void initialize(
      {required String minerAddress,
      required String poolHost,
      required int poolPort,
      required String coinAlgo}) {
    _minerAddress = minerAddress;
    _poolHost = poolHost;
    _poolPort = poolPort;
    _coinAlgo = coinAlgo;
    initialized = true;
  }

  void clean() {
    _minerAddress = null;
    _poolHost = null;
    _poolPort = null;
    _coinAlgo = null;
    initialized = false;
  }

  Future<bool> startMining() async {
    String executablePath = path.join(
        Directory.current.path, 'bin/xmrig${Platform.isWindows ? '.exe' : ""}');
    _minerProcess = await Process.start(executablePath, [
      "--url=$_poolHost:$_poolPort",
      "--algo=$_coinAlgo",
      "--user=$_minerAddress",
      "--http-host=127.0.0.1",
      "--http-port=45580",
      "--no-color",
      "--cpu-no-yield"
    ]);
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
