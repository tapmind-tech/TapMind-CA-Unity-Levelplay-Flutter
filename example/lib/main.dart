import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:unity_levelplay_mediation/unity_levelplay_mediation.dart';

// App Keys
const String _appKeyAndroid = '2517ad13d';
const String _appKeyIos = '250e1c675';

// Ad Unit IDs - iOS
const String _bannerAdUnitIdIos = 'sv1nook45jrregtv';
const String _interstitialAdUnitIdIos = 'gsf0zyde1i609r9k';
const String _rewardedAdUnitIdIos = 'y8donjnjzexg8cmm';

// Ad Unit IDs - Android
const String _bannerAdUnitIdAndroid = 'z99pgob38ju6y3wh';
const String _interstitialAdUnitIdAndroid = 'uhqpizf13ghg479b';
const String _rewardedAdUnitIdAndroid = 'p8em4563fv6hu68t';

String get _appKey =>
    Platform.isAndroid ? _appKeyAndroid : Platform.isIOS ? _appKeyIos : '';

String get _bannerAdUnitId =>
    Platform.isAndroid ? _bannerAdUnitIdAndroid : _bannerAdUnitIdIos;

String get _interstitialAdUnitId =>
    Platform.isAndroid ? _interstitialAdUnitIdAndroid : _interstitialAdUnitIdIos;

String get _rewardedAdUnitId =>
    Platform.isAndroid ? _rewardedAdUnitIdAndroid : _rewardedAdUnitIdIos;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TapMind Ads Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const AdsScreen(),
    );
  }
}

class AdsScreen extends StatefulWidget {
  const AdsScreen({super.key});

  @override
  State<AdsScreen> createState() => _AdsScreenState();
}

class _AdsScreenState extends State<AdsScreen>
    implements LevelPlayInitListener, LevelPlayBannerAdViewListener {
  bool _isInitialized = false;
  bool _showBanner = false;
  bool _isLoading = false;
  bool _isBannerLoading = false;
  bool _isInterstitialLoading = false;
  bool _isRewardedLoading = false;
  String _statusMessage = 'Initializing SDK...';

  // ignore: prefer_final_fields - recreated when showing banner after hide
  GlobalKey<LevelPlayBannerAdViewState> _bannerKey =
      GlobalKey<LevelPlayBannerAdViewState>();
  final LevelPlayAdSize _adSize = LevelPlayAdSize.BANNER;

  LevelPlayRewardedAd? _rewardedAd;
  LevelPlayInterstitialAd? _interstitialAd;
  bool _interstitialListenerSetup = false;
  bool _rewardedListenerSetup = false;
  bool _shouldShowInterstitialAfterLoad = false;
  bool _shouldShowRewardedAfterLoad = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLevelPlay());
  }

  Future<void> _initLevelPlay() async {
    if (_appKey.isEmpty) {
      setState(() {
        _statusMessage = 'Unsupported platform';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Initializing...';
    });

    try {
      if (Platform.isIOS) {
        final status =
            await ATTrackingManager.getTrackingAuthorizationStatus();
        if (status == ATTStatus.NotDetermined) {
          await ATTrackingManager.requestTrackingAuthorization();
        }
      }

      await LevelPlay.setAdaptersDebug(true);
      await LevelPlay.validateIntegration();

      final initRequest = LevelPlayInitRequest.builder(_appKey)
          .withUserId('tapmind_user')
          .build();

      await LevelPlay.init(initRequest: initRequest, initListener: this);

      // Initialize ad instances after SDK init
      _rewardedAd = LevelPlayRewardedAd(adUnitId: _rewardedAdUnitId);
      _interstitialAd = LevelPlayInterstitialAd(adUnitId: _interstitialAdUnitId);

      if (mounted) {
        setState(() {
          _statusMessage = 'Ready';
          _isInitialized = true;
          _isLoading = false;
        });
      }
    } on PlatformException catch (e) {
      if (mounted) {
        setState(() {
          _statusMessage = 'Init failed: ${e.message}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void onInitSuccess(LevelPlayConfiguration configuration) {
    debugPrint('LevelPlay init success: $configuration');
    // Don't load ads automatically - wait for user to click buttons
  }

  @override
  void onInitFailed(LevelPlayInitError error) {
    debugPrint('LevelPlay init failed: $error');
  }

  void _showBannerAd() {
    setState(() {
      _isBannerLoading = true;
      _showBanner = true;
      _bannerKey = GlobalKey<LevelPlayBannerAdViewState>();
    });
  }

  void _hideBannerAd() {
    _bannerKey.currentState?.destroy();
    setState(() {
      _showBanner = false;
      _isBannerLoading = false;
    });
  }


  Future<void> _showInterstitialAd() async {
    if (_interstitialAd == null) return;
    
    // Set up listener on first call
    if (!_interstitialListenerSetup) {
      _interstitialAd!.setListener(_InterstitialListener(
        onLoaded: () async {
          if (mounted) {
            setState(() => _isInterstitialLoading = false);
          }
          // Automatically show ad if user requested it
          if (_shouldShowInterstitialAfterLoad) {
            _shouldShowInterstitialAfterLoad = false;
            _interstitialAd?.showAd(placementName: 'Default');
          }
        },
        onLoadFailed: (_) {
          if (mounted) {
            setState(() {
              _isInterstitialLoading = false;
              _shouldShowInterstitialAfterLoad = false;
            });
          }
          _showNonAutoDismissSnackBar('Interstitial load failed');
        },
        onDisplayed: () => _showSnackBar('Interstitial displayed'),
        onClosed: () {
          _showSnackBar('Interstitial closed');
          _interstitialAd?.loadAd();
        },
      ));
      _interstitialListenerSetup = true;
    }
    
    setState(() => _isInterstitialLoading = true);
    
    if (await _interstitialAd!.isAdReady()) {
      setState(() => _isInterstitialLoading = false);
      _interstitialAd!.showAd(placementName: 'Default');
    } else {
      _shouldShowInterstitialAfterLoad = true;
      _showSnackBar('Loading interstitial ad...');
      _interstitialAd!.loadAd();
      // Ad will show automatically when loaded via onLoaded callback
    }
  }

  Future<void> _showRewardedAd() async {
    if (_rewardedAd == null) return;
    
    // Set up listener on first call
    if (!_rewardedListenerSetup) {
      _rewardedAd!.setListener(_RewardedListener(
        onRewarded: (r, _) => _showSnackBar('Rewarded! ${r.name}: ${r.amount}'),
        onLoaded: () async {
          if (mounted) {
            setState(() => _isRewardedLoading = false);
          }
          // Automatically show ad if user requested it
          if (_shouldShowRewardedAfterLoad) {
            _shouldShowRewardedAfterLoad = false;
            _rewardedAd?.showAd(placementName: 'Default');
          }
        },
        onLoadFailed: (_) {
          if (mounted) {
            setState(() {
              _isRewardedLoading = false;
              _shouldShowRewardedAfterLoad = false;
            });
          }
          _showNonAutoDismissSnackBar('Rewarded load failed');
        },
        onClosed: () => _rewardedAd?.loadAd(),
      ));
      _rewardedListenerSetup = true;
    }
    
    setState(() => _isRewardedLoading = true);
    
    if (await _rewardedAd!.isAdReady()) {
      setState(() => _isRewardedLoading = false);
      _rewardedAd!.showAd(placementName: 'Default');
    } else {
      _shouldShowRewardedAfterLoad = true;
      _showSnackBar('Loading rewarded ad...');
      _rewardedAd!.loadAd();
      // Ad will show automatically when loaded via onLoaded callback
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showNonAutoDismissSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(hours: 1),
        action: SnackBarAction(
          label: 'DISMISS',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TapMind Ironsource Example'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: _buildAdInterface(),
      ),
    );
  }

  Widget _buildAdInterface() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading) ...[
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                _statusMessage,
                style: TextStyle(
                  color: _isInitialized ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _AdButton(
                  label: 'Show Banner Ad',
                  icon: Icons.view_agenda,
                  onPressed: _isInitialized ? _showBannerAd : null,
                  isLoading: _isBannerLoading,
                ),
                const SizedBox(height: 16),
                _AdButton(
                  label: 'Show Interstitial Ad',
                  icon: Icons.fullscreen,
                  onPressed: _isInitialized ? _showInterstitialAd : null,
                  isLoading: _isInterstitialLoading,
                ),
                const SizedBox(height: 16),
                _AdButton(
                  label: 'Show Rewarded Ad',
                  icon: Icons.star,
                  onPressed: _isInitialized ? _showRewardedAd : null,
                  isLoading: _isRewardedLoading,
                ),
                if (_showBanner) ...[
                  const SizedBox(height: 24),
                  _AdButton(
                    label: 'Hide Banner',
                    icon: Icons.close,
                    onPressed: _hideBannerAd,
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_showBanner)
          Container(
            width: _adSize.width.toDouble(),
            height: _adSize.height.toDouble(),
            alignment: Alignment.center,
            color: Colors.grey[200],
            child: LevelPlayBannerAdView(
              key: _bannerKey,
              adUnitId: _bannerAdUnitId,
              adSize: _adSize,
              listener: this,
              placementName: 'DefaultBanner',
              onPlatformViewCreated: () {
                _bannerKey.currentState?.loadAd();
              },
            ),
          ),
      ],
    );
  }

  // LevelPlayBannerAdViewListener
  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) {
    debugPrint('Banner onAdLoaded: $adInfo');
    if (mounted) {
      setState(() => _isBannerLoading = false);
    }
  }

  @override
  void onAdLoadFailed(LevelPlayAdError error) {
    debugPrint('Banner onAdLoadFailed: $error');
    if (mounted) {
      setState(() => _isBannerLoading = false);
    }
    _showNonAutoDismissSnackBar('Banner load failed');
  }

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdInfo adInfo, LevelPlayAdError error) {}

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdExpanded(LevelPlayAdInfo adInfo) {}

  @override
  void onAdCollapsed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdLeftApplication(LevelPlayAdInfo adInfo) {}
}

class _AdButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const _AdButton({
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(isLoading ? 'Loading...' : label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _InterstitialListener with LevelPlayInterstitialAdListener {
  final VoidCallback? onLoaded;
  final void Function(LevelPlayAdError)? onLoadFailed;
  final VoidCallback? onDisplayed;
  final VoidCallback? onClosed;

  _InterstitialListener({
    this.onLoaded,
    this.onLoadFailed,
    this.onDisplayed,
    this.onClosed,
  });

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) => onLoaded?.call();

  @override
  void onAdLoadFailed(LevelPlayAdError error) => onLoadFailed?.call(error);

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) => onDisplayed?.call();

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) => onClosed?.call();

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {}

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}

class _RewardedListener with LevelPlayRewardedAdListener {
  final void Function(LevelPlayReward, LevelPlayAdInfo)? onRewarded;
  final VoidCallback? onLoaded;
  final void Function(LevelPlayAdError)? onLoadFailed;
  final VoidCallback? onClosed;

  _RewardedListener({
    this.onRewarded,
    this.onLoaded,
    this.onLoadFailed,
    this.onClosed,
  });

  @override
  void onAdRewarded(LevelPlayReward reward, LevelPlayAdInfo adInfo) =>
      onRewarded?.call(reward, adInfo);

  @override
  void onAdLoaded(LevelPlayAdInfo adInfo) => onLoaded?.call();

  @override
  void onAdLoadFailed(LevelPlayAdError error) => onLoadFailed?.call(error);

  @override
  void onAdClosed(LevelPlayAdInfo adInfo) => onClosed?.call();

  @override
  void onAdClicked(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayed(LevelPlayAdInfo adInfo) {}

  @override
  void onAdDisplayFailed(LevelPlayAdError error, LevelPlayAdInfo adInfo) {}

  @override
  void onAdInfoChanged(LevelPlayAdInfo adInfo) {}
}
