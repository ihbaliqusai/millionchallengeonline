package net.androidgaming.millionaire2024;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.Handler;
import android.util.DisplayMetrics;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.view.animation.RotateAnimation;
import android.view.animation.ScaleAnimation;
import android.view.animation.TranslateAnimation;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;

import java.util.Random;

public class WinnerActivity extends AppCompatActivity {

    int width;
    int height;
    int interval;
    boolean animMoney = false;
    MediaPlayer mpSound;

    String amount;

    private InterstitialAd mInterstitialAd;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_winner);
        if (getSupportActionBar() != null) getSupportActionBar().hide();

        loadInterstitialAd();


        DisplayMetrics metrics = new DisplayMetrics();
        getWindowManager().getDefaultDisplay().getMetrics(metrics);

        width = metrics.widthPixels;
        height = metrics.heightPixels;
        interval = width / 10;

        amount = getIntent().getStringExtra("amount");

        mpSound = MediaPlayer.create(this, R.raw.main_theme_4);
        mpSound.start();
        showDialog("ألف مبروك\nأنت الفائز بمبلغ "+amount, "", 0, 3000, 0);
        animMoney = true;
        final Handler handler = new Handler();
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                newDollar();
                handler.postDelayed(this, 200);
            }
        }, 1000);

        (findViewById(R.id.imgHome)).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                showInterstitialAd();
            }
        });

    }

    private void loadInterstitialAd() {
        String adUnitId = getResources().getString(R.string.interstitial_ad_id);
        InterstitialAd.load(this, adUnitId, new AdRequest.Builder().build(),
            new InterstitialAdLoadCallback() {
                @Override
                public void onAdLoaded(InterstitialAd ad) {
                    mInterstitialAd = ad;
                    mInterstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                        @Override
                        public void onAdDismissedFullScreenContent() {
                            mInterstitialAd = null;
                            Intent intent = new Intent(WinnerActivity.this, MainActivity.class);
                            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                            startActivity(intent);
                        }
                    });
                }
                @Override
                public void onAdFailedToLoad(LoadAdError error) {
                    mInterstitialAd = null;
                }
            });
    }

    private void showInterstitialAd() {
        if (mInterstitialAd != null) {
            mInterstitialAd.show(this);
        } else {
            Intent intent = new Intent(WinnerActivity.this, MainActivity.class);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(intent);
        }
    }


    void newDollar() {
        int f = new Random().nextInt(10);
        int xPos = new Random().nextInt(interval)+(f * interval);
        final RelativeLayout rlyScreen = findViewById(R.id.rlyScreen);
        final ImageView imgDollar = new ImageView(this);

        int random = new Random().nextInt(2)+1;

        RelativeLayout.LayoutParams params = new RelativeLayout.LayoutParams(100, 50);
        params.leftMargin = xPos;
        params.topMargin = -50;
        imgDollar.setLayoutParams(params);
        imgDollar.setImageResource(R.drawable.dollar);
        rlyScreen.addView(imgDollar);

        AnimationSet animSet = new AnimationSet(false);
        TranslateAnimation tAnim;
        RotateAnimation rAnim;
        ScaleAnimation sAnim;

        tAnim = new TranslateAnimation(0, 0,0,height);
        tAnim.setDuration(5000);
        //tAnim.setFillAfter(true);
        animSet.addAnimation(tAnim);


        //////////////////////////////////////////////////////////////////////////////////////////
        if(random==1) {
            sAnim = new ScaleAnimation(1.0f, 0.5f, 1, 1, Animation.RELATIVE_TO_SELF,0.5f,Animation.RELATIVE_TO_SELF, 0.5f);
            sAnim.setDuration(1000);
            sAnim.setStartOffset(1000);
            animSet.addAnimation(sAnim);

            rAnim = new RotateAnimation(0, -5, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            rAnim.setDuration(1000);
            rAnim.setStartOffset(1000);
            animSet.addAnimation(rAnim);

            sAnim = new ScaleAnimation(1.0f, 2.0f, 1, 1, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            sAnim.setDuration(1000);
            sAnim.setStartOffset(2000);
            animSet.addAnimation(sAnim);

            rAnim = new RotateAnimation(-5, 0, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            rAnim.setDuration(1000);
            rAnim.setStartOffset(2000);
            animSet.addAnimation(rAnim);

            //////////////////////////////////////////////////////////////////////////////////////////

            sAnim = new ScaleAnimation(1.0f, 0.5f, 1, 1, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            sAnim.setDuration(1000);
            sAnim.setStartOffset(3000);
            animSet.addAnimation(sAnim);

            rAnim = new RotateAnimation(0, 5, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            rAnim.setDuration(1000);
            rAnim.setStartOffset(3000);
            animSet.addAnimation(rAnim);

            sAnim = new ScaleAnimation(1.0f, 2.0f, 1, 1, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            sAnim.setDuration(1000);
            sAnim.setStartOffset(4000);
            animSet.addAnimation(sAnim);

            rAnim = new RotateAnimation(5, 0, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            rAnim.setDuration(1000);
            rAnim.setStartOffset(4000);
            animSet.addAnimation(rAnim);


        } else {
            sAnim = new ScaleAnimation(1.0f, 0.5f, 1, 1, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            sAnim.setDuration(1000);
            sAnim.setStartOffset(1000);
            animSet.addAnimation(sAnim);

            rAnim = new RotateAnimation(0, 5, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            rAnim.setDuration(1000);
            rAnim.setStartOffset(1000);
            animSet.addAnimation(rAnim);

            sAnim = new ScaleAnimation(1.0f, 2.0f, 1, 1, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            sAnim.setDuration(1000);
            sAnim.setStartOffset(2000);
            animSet.addAnimation(sAnim);

            rAnim = new RotateAnimation(5, 0, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            rAnim.setDuration(1000);
            rAnim.setStartOffset(2000);
            animSet.addAnimation(rAnim);


            sAnim = new ScaleAnimation(1.0f, 0.5f, 1, 1, Animation.RELATIVE_TO_SELF,0.5f,Animation.RELATIVE_TO_SELF, 0.5f);
            sAnim.setDuration(1000);
            sAnim.setStartOffset(3000);
            animSet.addAnimation(sAnim);

            rAnim = new RotateAnimation(0, -5, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            rAnim.setDuration(1000);
            rAnim.setStartOffset(3000);
            animSet.addAnimation(rAnim);

            sAnim = new ScaleAnimation(1.0f, 2.0f, 1, 1, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            sAnim.setDuration(1000);
            sAnim.setStartOffset(4000);
            animSet.addAnimation(sAnim);

            rAnim = new RotateAnimation(-5, 0, Animation.RELATIVE_TO_SELF, 0.5f, Animation.RELATIVE_TO_SELF, 0.5f);
            rAnim.setDuration(1000);
            rAnim.setStartOffset(4000);
            animSet.addAnimation(rAnim);

        }

        animSet.setFillAfter(true);

        imgDollar.startAnimation(animSet);

        (new Handler()).postDelayed(new Runnable() {
            @Override
            public void run() {
                rlyScreen.removeView(imgDollar);
            }
        }, 5000);

    }

    private void showDialog(final String message, final String tag, final int timeTalk, final int timeDialog, final int nextMouthId) {
        final RelativeLayout rlyDialog = findViewById(R.id.rlyDialog);
        final Typewriter txtDialog = findViewById(R.id.txtDialog);
        final Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            boolean firstRun = true;
            @Override
            public void run() {
                if(firstRun) {
                    firstRun=false;
                    txtDialog.setCharacterDelay(18);
                    txtDialog.animateText(message);
                    rlyDialog.setVisibility(View.VISIBLE);
                    Animations.dialogZoom(rlyDialog, 4, 150, 1.05f);
                    handler.postDelayed(this, timeDialog);
                } else {
                    rlyDialog.setVisibility(View.INVISIBLE);
                }

            }
        };
        handler.postDelayed(runnable, 0);
    }


    @Override
    protected void onPause() {
        animMoney=false;
        if (mpSound != null) mpSound.stop();
        super.onPause();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }

    @Override
    public void onBackPressed() {
        showInterstitialAd();
    }

}