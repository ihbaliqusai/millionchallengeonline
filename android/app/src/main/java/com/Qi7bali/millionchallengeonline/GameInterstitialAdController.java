package net.androidgaming.millionaire2024;

import android.util.Log;

import androidx.appcompat.app.AppCompatActivity;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

final class GameInterstitialAdController {
    private final AppCompatActivity activity;
    private InterstitialAd interstitialAd;

    GameInterstitialAdController(AppCompatActivity activity) {
        this.activity = activity;
    }

    void loadIfNeeded(Runnable onDismissed) {
        try {
            if (interstitialAd != null) return;
            MobileAds.initialize(activity, initializationStatus -> {});
            InterstitialAd.load(activity,
                    activity.getResources().getString(R.string.interstitial_ad_id),
                    new AdRequest.Builder().build(),
                    new InterstitialAdLoadCallback() {
                        @Override
                        public void onAdLoaded(InterstitialAd ad) {
                            interstitialAd = ad;
                            interstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                                @Override
                                public void onAdDismissedFullScreenContent() {
                                    interstitialAd = null;
                                    if (onDismissed != null) {
                                        onDismissed.run();
                                    }
                                }
                            });
                        }

                        @Override
                        public void onAdFailedToLoad(LoadAdError error) {
                            interstitialAd = null;
                        }
                    });
        } catch (Exception e) {
            Log.w("GameActivity", "initAdsIfNeeded failed", e);
        }
    }

    void showOrRun(Runnable fallback) {
        AppPrefs.recordInterstitialOpportunity(activity);
        if (interstitialAd != null && AppPrefs.canShowInterstitialNow(activity)) {
            AppPrefs.markInterstitialShown(activity);
            interstitialAd.show(activity);
        } else if (fallback != null) {
            fallback.run();
        }
    }
}
