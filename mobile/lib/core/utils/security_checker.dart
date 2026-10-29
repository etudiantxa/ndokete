import 'dart:io';
import 'package:flutter/foundation.dart';

class SecurityChecker {
  static Future<bool> isDeviceCompromised() async {
    if (kIsWeb) return false;
    try {
      if (Platform.isAndroid) {
        final paths = [
          '/system/app/Superuser.apk',
          '/sbin/su',
          '/system/bin/su',
          '/system/xbin/su',
          '/data/local/xbin/su',
          '/data/local/bin/su',
          '/system/sd/xbin/su',
          '/system/bin/failsafe/su',
          '/data/local/su',
        ];
        for (final path in paths) {
          if (await File(path).exists()) {
            return true;
          }
        }
      } else if (Platform.isIOS) {
        final paths = [
          '/Applications/Cydia.app',
          '/Library/MobileSubstrate/MobileSubstrate.dylib',
          '/bin/bash',
          '/usr/sbin/sshd',
          '/etc/apt',
          '/private/var/lib/apt/',
        ];
        for (final path in paths) {
          if (await File(path).exists()) {
            return true;
          }
        }
      }
    } catch (_) {}
    return false;
  }
}
