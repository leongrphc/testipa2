import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../api/api_client.dart';
import '../config/app_config.dart';

class RewardedAdResult {
  const RewardedAdResult({required this.completed, this.message});

  final bool completed;
  final String? message;
}

class AdService {
  Future<RewardedAdResult> showRewardedAd({required String placement}) async {
    final completer = Completer<RewardedAdResult>();

    await RewardedAd.load(
      adUnitId: AppConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          var earnedReward = false;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(
                  RewardedAdResult(
                    completed: earnedReward,
                    message: earnedReward ? null : 'Reklam tamamlanmadı.',
                  ),
                );
              }
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              if (!completer.isCompleted) {
                completer.complete(
                  RewardedAdResult(completed: false, message: error.message),
                );
              }
            },
          );
          ad.show(
            onUserEarnedReward: (_, __) {
              earnedReward = true;
            },
          );
        },
        onAdFailedToLoad: (error) {
          if (!completer.isCompleted) {
            completer.complete(
              RewardedAdResult(completed: false, message: error.message),
            );
          }
        },
      ),
    );

    return completer.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () => const RewardedAdResult(
        completed: false,
        message: 'Reklam zaman aşımına uğradı.',
      ),
    );
  }

  Future<Map<String, dynamic>> claimReward(String rewardType) async {
    final response = await apiClient.post(
      '/api/ads/reward',
      data: {'rewardType': rewardType},
    );
    return response.data['data'] as Map<String, dynamic>;
  }
}

final adService = AdService();
