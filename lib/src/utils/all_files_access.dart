import 'dart:io';

import 'package:flutter/services.dart';

const _mediaChannel = MethodChannel('picquery/media');

/// Android 11+ needs all-files access before this app can copy images into a
/// folder the user picked. Other platforms can write the destination directly.
Future<bool> ensureAllFilesAccess() async {
  if (!Platform.isAndroid) return true;
  final granted = await _mediaChannel.invokeMethod<bool>('hasAllFilesAccess');
  if (granted == true) return true;
  await _mediaChannel.invokeMethod<void>('requestAllFilesAccess');
  return false;
}
