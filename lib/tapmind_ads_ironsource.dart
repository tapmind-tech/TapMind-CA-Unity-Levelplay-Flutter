
import 'tapmind_ads_ironsource_platform_interface.dart';

class TapmindAdsIronsource {
  Future<String?> getPlatformVersion() {
    return TapmindAdsIronsourcePlatform.instance.getPlatformVersion();
  }
}
