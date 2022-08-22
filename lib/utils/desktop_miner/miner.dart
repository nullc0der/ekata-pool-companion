import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

class DesktopMinerUtil {
  late final String _minerAddress;
  Process? _minerProcess;
  bool initialized = false;
  static final DesktopMinerUtil instance = DesktopMinerUtil._internal();
  final StreamController<String> _logStream =
      StreamController<String>.broadcast();

  DesktopMinerUtil._internal();

  Stream<String> get logStream => _logStream.stream;

  void initialize({required String minerAddress}) {
    _minerAddress = minerAddress;
    initialized = true;
  }

  Future<bool> startMining() async {
    String executablePath = path.join(Directory.current.path,
        'bin/bazadedicatedminer${Platform.isWindows ? '.exe' : ""}');
    _minerProcess = await Process.start(executablePath, [
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
