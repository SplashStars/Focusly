// ---------------------------------------------------------------------------
// DND Service - Strict Mode support
//
// Android only permits silencing calls/messages via Do Not Disturb, and only
// after the user grants "Do Not Disturb access" in system Settings. We ask for
// that permission ONLY when the user actually turns Strict Mode on, never at
// launch, and we restore their previous interruption filter afterwards.
// ---------------------------------------------------------------------------

import 'package:flutter/services.dart';

class DndService {
  static const _channel = MethodChannel('focusly/dnd');

  /// True when the user has already granted Do Not Disturb access.
  static Future<bool> hasAccess() async {
    try {
      return await _channel.invokeMethod<bool>('hasAccess') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Opens the system screen where DND access is granted.
  static Future<void> openAccessSettings() async {
    try {
      await _channel.invokeMethod('openSettings');
    } on PlatformException {
      // Caller shows guidance text instead.
    }
  }

  /// Turn Do Not Disturb on, remembering the previous filter.
  static Future<bool> enable() async {
    try {
      return await _channel.invokeMethod<bool>('enable') ?? false;
    } on PlatformException {
      return false;
    }
  }

  /// Restore whatever interruption filter was active before we changed it.
  static Future<void> disable() async {
    try {
      await _channel.invokeMethod('disable');
    } on PlatformException {
      // Recoverable by the user.
    }
  }
}
