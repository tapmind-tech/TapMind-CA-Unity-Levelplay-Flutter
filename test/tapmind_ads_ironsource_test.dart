import 'package:flutter_test/flutter_test.dart';
import 'package:tapmind_ads_ironsource/tapmind_ads_ironsource.dart';
import 'package:tapmind_ads_ironsource/tapmind_ads_ironsource_platform_interface.dart';
import 'package:tapmind_ads_ironsource/tapmind_ads_ironsource_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockTapmindAdsIronsourcePlatform
    with MockPlatformInterfaceMixin
    implements TapmindAdsIronsourcePlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final TapmindAdsIronsourcePlatform initialPlatform = TapmindAdsIronsourcePlatform.instance;

  test('$MethodChannelTapmindAdsIronsource is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelTapmindAdsIronsource>());
  });

  test('getPlatformVersion', () async {
    TapmindAdsIronsource tapmindAdsIronsourcePlugin = TapmindAdsIronsource();
    MockTapmindAdsIronsourcePlatform fakePlatform = MockTapmindAdsIronsourcePlatform();
    TapmindAdsIronsourcePlatform.instance = fakePlatform;

    expect(await tapmindAdsIronsourcePlugin.getPlatformVersion(), '42');
  });
}
