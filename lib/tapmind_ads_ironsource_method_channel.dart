import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'tapmind_ads_ironsource_platform_interface.dart';

/// An implementation of [TapmindAdsIronsourcePlatform] that uses method channels.
class MethodChannelTapmindAdsIronsource extends TapmindAdsIronsourcePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('tapmind_ads_ironsource');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
