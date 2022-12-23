import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class DesktopMinerUtil {
  String? _minerConfigPath;
  int? _threadCount;
  Process? _minerProcess;
  bool initialized = false;
  static final DesktopMinerUtil instance = DesktopMinerUtil._internal();
  final StreamController<String> _logStream =
      StreamController<String>.broadcast();

  DesktopMinerUtil._internal();

  Stream<String> get logStream => _logStream.stream;

  void initialize({required String? minerConfigPath, int? threadCount}) {
    _minerConfigPath = minerConfigPath;
    _threadCount = threadCount;
    initialized = true;
  }

  void clean() {
    _minerConfigPath = null;
    _threadCount = null;
    initialized = false;
  }

  Future<bool> startMining() async {
    String executablePath = path.join(
        Directory.current.path, 'bin/xmrig${Platform.isWindows ? '.exe' : ""}');
    final minerProcessArgs = [
      "--config=$_minerConfigPath",
      "--http-host=127.0.0.1",
      "--http-port=45580",
      "--cpu-no-yield"
    ];
    if (_threadCount != null) {
      minerProcessArgs.add("--threads=${_threadCount.toString()}");
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
