import 'package:flutter/material.dart';

class Constants {
  static const threadCount = "io.ekata.ekatapoolcompanion.THREAD_COUNT";
  static const minerConfigPath =
      "io.ekata.ekatapoolcompanion.MINER_CONFIG_PATH";
  static const minerBinary = "io.ekata.ekatapoolcompanion.MINER_BINARY";
  static const xmrigCCServerUrl =
      "io.ekata.ekatapoolcompanion.XMRIGCC_SERVER_URL";
  static const xmrigCCServerToken =
      "io.ekata.ekatapoolcompanion.XMRIGCC_SERVER_TOKEN";
  static const xmrigCCWorkerId =
      "io.ekata.ekatapoolcompanion.XMRIGCC_WORKER_ID";
  static const ccMinerBinaryVariant =
      "io.ekata.ekatapoolcompanion.CC_MINER_BINARY_VARIANT";
  static const ccMinerAlgo = "io.ekata.ekatapoolcompanion.CC_MINER_ALGO";
  static const ccMinerPoolUrl = "io.ekata.ekatapoolcompanion.CC_MINER_POOL_URL";
  static const ccMinerUsername =
      "io.ekata.ekatapoolcompanion.CC_MINER_USERNAME";
  static const ccMinerRigId = "io.ekata.ekatapoolcompanion.CC_MINER_RIGID";
  static const ccMinerPassword =
      "io.ekata.ekatapoolcompanion.CC_MINER_PASSWORD";
  static const minerProcessStarted = "MINER_PROCESS_STARTED";
  static const minerProcessStopped = "MINER_PROCESS_STOPPED";
  static const walletAddressKeySharedPrefs = "WALLET_ADDRESS";
  static const walletAddressesKeySharedPrefs = "WALLET_ADDRESSES";
  static const userIdSharedPrefs = "USER_ID";
  static const currentAppVersionSharedPrefs = "CURRENT_APP_VERSION";
  static const poolCredentialsSharedPrefs = "POOL_CREDENTIALS";
  static const xmrigCCOptionsSharedPrefs = "XMRIGCC_OPTIONS";
  static const initialHeartBeatInSeconds = 60;
  static const supportedXmrigAlgo = [
    "gr",
    "ghostrider",
    "rx/graft",
    "cn/upx2",
    "argon2/chukwav2",
    "cn/ccx",
    "kawpow",
    "rx/keva",
    "cn-pico/tlo",
    "rx/sfx",
    "rx/arq",
    "rx/0",
    "argon2/chukwa",
    "argon2/ninja",
    "rx/wow",
    "cn/fast",
    "cn/rwz",
    "cn/zls",
    "cn/double",
    "cn/r",
    "cn-pico",
    "cn/half",
    "cn/2",
    "cn/xao",
    "cn/rto",
    "cn-heavy/tube",
    "cn-heavy/xhv",
    "cn-heavy/0",
    "cn/1",
    "cn-lite/1",
    "cn-lite/0",
    "cn/0"
  ];
  static const supportedCCMinerAlgo = [
    'hmq1725',
    'jackpot',
    'keccak',
    'keccakc',
    'lbry',
    'luffa',
    'lyra2',
    'lyra2v2',
    'lyra2z',
    'myr-gr',
    'monero',
    'neoscrypt',
    'nist5',
    'penta',
    'phi1612',
    'phi2',
    'polytimos',
    'quark',
    'qubit',
    'sha256d',
    'sha256t',
    'sia',
    'sib',
    'scrypt',
    'scrypt-jane',
    'skein',
    'skein2',
    'skunk',
    'sonoa',
    'stellite',
    's3',
    'timetravel',
    'tribus',
    'vanilla',
    'veltor',
    'whirlcoin',
    'whirlpool',
    'x11evo',
    'x11',
    'x12',
    'x13',
    'x14',
    'x15',
    'x16r',
    'x16s',
    'x17',
    'wildkeccak',
    'zr5',
    'heavy',
    'allium',
    'bastion',
    'bitcore',
    'blake',
    'blake2s',
    'blakecoin',
    'bmw',
    'cryptolight',
    'cryptonight',
    'c11/flax',
    'decred',
    'deep',
    'verus',
    'dmd-gr',
    'fresh',
    'fugue256',
    'graft',
    'groestl'
  ];
  static const ansiColorMapping = {
    "0;90m": {"color": Colors.grey, "isBg": false, "isBold": false},
    "0;30m": {
      "color": Colors.white,
      "isBg": false,
      "isBold": false
    }, // Actually black, because of widget color inverted
    "1;30m": {
      "color": Colors.white,
      "isBg": false,
      "isBold": true
    }, // Actually black, because of widget color inverted
    "0;31m": {"color": Colors.red, "isBg": false, "isBold": false},
    "1;31m": {"color": Colors.red, "isBg": false, "isBold": true},
    "0;32m": {"color": Colors.green, "isBg": false, "isBold": false},
    "1;32m": {"color": Colors.green, "isBg": false, "isBold": true},
    "0;33m": {"color": Colors.yellow, "isBg": false, "isBold": false},
    "1;33m": {"color": Colors.yellow, "isBg": false, "isBold": true},
    "0;34m": {"color": Colors.blue, "isBg": false, "isBold": false},
    "1;34m": {"color": Colors.blue, "isBg": false, "isBold": true},
    "0;35m": {"color": Color(0xFFFF00FF), "isBg": false, "isBold": false},
    "1;35m": {"color": Color(0xFFFF00FF), "isBg": false, "isBold": true},
    "0;36m": {"color": Colors.cyan, "isBg": false, "isBold": false},
    "1;36m": {"color": Colors.cyan, "isBg": false, "isBold": true},
    "0;37m": {"color": Colors.white, "isBg": false, "isBold": false},
    "1;37m": {"color": Colors.white, "isBg": false, "isBold": true},
    "41;1m": {"color": Colors.red, "isBg": true, "isBold": true},
    "42;1m": {"color": Colors.green, "isBg": true, "isBold": true},
    "43;1m": {"color": Colors.yellow, "isBg": true, "isBold": true},
    "44m": {"color": Colors.blue, "isBg": true, "isBold": false},
    "44;1m": {"color": Colors.blue, "isBg": true, "isBold": true},
    "45m": {"color": Color(0xFFFF00FF), "isBg": true, "isBold": false},
    "45;1m": {"color": Color(0xFFFF00FF), "isBg": true, "isBold": true},
    "46m": {"color": Colors.cyan, "isBg": true, "isBold": false},
    "46;1m": {"color": Colors.cyan, "isBg": true, "isBold": true},
    "31m": {"color": Colors.red, "isBg": false, "isBold": false},
    "32m": {"color": Colors.green, "isBg": false, "isBold": false},
    "33m": {"color": Colors.yellow, "isBg": false, "isBold": false},
    "34m": {"color": Colors.blue, "isBg": false, "isBold": false},
    "35m": {"color": Color(0xFFFF00FF), "isBg": false, "isBold": false},
    "36m": {"color": Colors.cyan, "isBg": false, "isBold": false},
  };
}
