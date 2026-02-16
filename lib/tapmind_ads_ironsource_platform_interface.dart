import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'tapmind_ads_ironsource_method_channel.dart';

abstract class TapmindAdsIronsourcePlatform extends PlatformInterface {
  /// Constructs a TapmindAdsIronsourcePlatform.
  TapmindAdsIronsourcePlatform() : super(token: _token);

  static final Object _token = Object();

  static TapmindAdsIronsourcePlatform _instance = MethodChannelTapmindAdsIronsource();

  /// The default instance of [TapmindAdsIronsourcePlatform] to use.
  ///
  /// Defaults to [MethodChannelTapmindAdsIronsource].
  static TapmindAdsIronsourcePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [TapmindAdsIronsourcePlatform] when
  /// they register themselves.
  static set instance(TapmindAdsIronsourcePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
