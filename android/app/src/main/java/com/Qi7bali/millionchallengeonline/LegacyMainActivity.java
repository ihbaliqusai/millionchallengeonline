package net.androidgaming.millionaire2024;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import android.content.ClipData;
import android.content.ClipboardManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.text.InputType;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import java.util.Random;

public class LegacyMainActivity extends AppCompatActivity {

    int T_LIGHTS = 0;
    ImageView imgClosedEyes;
    LinearLayout llyCredit;
    ImageView imgPhoto;
    TextView txtName, txtLevel, txtCoins, txtGems;
    ProgressBar pbLevel;

    String userID = "";
    String userName = "";
    String userPhoto = "";
    int userLevel = 1;
    int userScore = 0;

    private final Handler lightsHandler = new Handler();
    private final Handler blinkHandler = new Handler();
    private Runnable lightsRunnable;
    private Runnable blinkRunnable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_main);

        imgPhoto = findViewById(R.id.imgPhoto);
        txtName = findViewById(R.id.txtName);
        txtLevel = findViewById(R.id.txtLevel);
        txtCoins = findViewById(R.id.txtCoins);
        txtGems = findViewById(R.id.txtGems);
        pbLevel = findViewById(R.id.pbLevel);

        refreshLocalUser();
        applyLocalUserInfo();
        if (!userID.equals("guest_local")) {
            Data.syncUserProfile(userID, userName, userPhoto, userLevel, userScore);
            Data.setUserActive(userID);
        }
        if (!Data.isNetworkAvailable(this) && !userID.equals("guest_local")) {
            Toast.makeText(this, getString(R.string.msg_no_internet), Toast.LENGTH_SHORT).show();
        }

        findViewById(android.R.id.content).postDelayed(new Runnable() {
            @Override
            public void run() {
                showDailyRewardIfAvailable();
            }
        }, 350);

        imgClosedEyes = findViewById(R.id.imgClosedEyes);
        llyCredit = findViewById(R.id.llyCredit);

        findViewById(R.id.btnPlay).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                confirmNewGame();
            }
        });

        findViewById(R.id.btnPlayOnline).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                openOnlineOptions();
            }
        });

        findViewById(R.id.btnStats).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startActivity(new Intent(LegacyMainActivity.this, StatsActivity.class));
            }
        });

        findViewById(R.id.btnAchievements).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startActivity(new Intent(LegacyMainActivity.this, AchievementsActivity.class));
            }
        });

        findViewById(R.id.btnStore).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startActivity(new Intent(LegacyMainActivity.this, StoreActivity.class));
            }
        });

        findViewById(R.id.btnSettings).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startActivity(new Intent(LegacyMainActivity.this, SettingsActivity.class));
            }
        });

        findViewById(R.id.btnPolicy).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(LegacyMainActivity.this, PrivacyPolicyActivity.class));
            }
        });

        findViewById(R.id.imgShare).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                final String appPackageName = getPackageName();
                Intent intent = new Intent(Intent.ACTION_SEND);
                intent.setType("text/plain");
                intent.putExtra(Intent.EXTRA_TEXT, "https://play.google.com/store/apps/details?id=" + appPackageName);
                intent.putExtra(Intent.EXTRA_SUBJECT, getString(R.string.share_subject));
                startActivity(Intent.createChooser(intent, getString(R.string.share_chooser)));
            }
        });

        findViewById(R.id.imgRate).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                final String appPackageName = getPackageName();
                try {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + appPackageName)));
                } catch (android.content.ActivityNotFoundException anfe) {
                    startActivity(new Intent(Intent.ACTION_VIEW, Uri.parse("https://play.google.com/store/apps/details?id=" + appPackageName)));
                }
            }
        });

        findViewById(R.id.btnExit).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                confirmExitApp();
            }
        });

    }

    private void refreshLocalUser() {
        AppPrefs.ensureGuestUser(this);
        userID = AppPrefs.getUserId(this);
        userName = AppPrefs.getUserName(this);
        userPhoto = AppPrefs.getUserPhoto(this);
        userLevel = AppPrefs.getUserLevel(this);
        userScore = AppPrefs.getUserScore(this);
    }

    private void applyLocalUserInfo() {
        txtName.setText(userName.equals("") ? getString(R.string.player_guest) : userName);
        if (userPhoto == null || userPhoto.equals("")) {
            imgPhoto.setImageResource(R.drawable.user);
        } else {
            Data.setImageSource(LegacyMainActivity.this, imgPhoto, userPhoto);
        }

        int level = PlayerProgress.getLevel(this);
        int xpIntoLevel = PlayerProgress.getXpIntoLevel(this);
        int xpNeeded = PlayerProgress.getXpNeededForNextLevel(this);
        txtLevel.setText(getString(R.string.player_level_status, level, xpIntoLevel, xpNeeded));
        txtCoins.setText(getString(R.string.currency_coins_value, PlayerProgress.getCoins(this)));
        txtGems.setText(getString(R.string.currency_gems_value, PlayerProgress.getGems(this)));

        int progressValue = (xpIntoLevel * 100) / Math.max(1, xpNeeded);
        pbLevel.setProgress(progressValue);
    }

    private void showDailyRewardIfAvailable() {
        if (PlayerProgress.canClaimDailyReward(this)) {
            PlayerProgress.DailyReward reward = PlayerProgress.claimDailyReward(this);
            applyLocalUserInfo();
            new androidx.appcompat.app.AlertDialog.Builder(this)
                    .setTitle(R.string.daily_reward_title)
                    .setMessage(getString(R.string.daily_reward_message, reward.coins, reward.gems, reward.streak))
                    .setPositiveButton(R.string.daily_reward_positive, null)
                    .show();
        }
    }

    private void animLights() {
        final ImageView imgLight1 = findViewById(R.id.imgLight1);
        final ImageView imgLight2 = findViewById(R.id.imgLight2);
        lightsRunnable = new Runnable() {
            boolean toLeft = true;

            @Override
            public void run() {
                if (toLeft) {
                    Animations.rotateLight(imgLight1, -20f, 20f, 1000);
                    Animations.rotateLight(imgLight2, 20f, -20f, 1000);
                    toLeft = false;
                } else {
                    Animations.rotateLight(imgLight1, 20f, -20f, 1000);
                    Animations.rotateLight(imgLight2, -20f, 20f, 1000);
                    toLeft = true;
                }
                lightsHandler.postDelayed(this, 1000);
            }
        };
        lightsHandler.post(lightsRunnable);
    }

    public void personBlinkEyes(final int times) {
        final Handler handler = new Handler();
        final Runnable runnable = new Runnable() {
            int t = 0;
            boolean opened = true;

            @Override
            public void run() {
                if (opened) {
                    opened = false;
                    t++;
                    imgClosedEyes.setVisibility(View.VISIBLE);
                    handler.postDelayed(this, 50);
                } else {
                    opened = true;
                    imgClosedEyes.setVisibility(View.INVISIBLE);
                    if (t < times) {
                        handler.postDelayed(this, 300);
                    }
                }
            }
        };
        handler.postDelayed(runnable, 1);
    }

    private void goBlinking() {
        blinkRunnable = new Runnable() {
            @Override
            public void run() {
                int times = (new Random()).nextInt(2) + 1;
                int delay = (new Random()).nextInt(5) + 3;
                personBlinkEyes(times);
                blinkHandler.postDelayed(this, delay * 1000L);
            }
        };
        blinkHandler.postDelayed(blinkRunnable, 1000);
    }

    @Override
    protected void onPause() {
        lightsHandler.removeCallbacksAndMessages(null);
        blinkHandler.removeCallbacksAndMessages(null);
        super.onPause();
    }

    @Override
    protected void onResume() {
        super.onResume();
        refreshLocalUser();
        applyLocalUserInfo();
        if (!userID.equals("guest_local")) {
            Data.syncUserProfile(userID, userName, userPhoto, userLevel, userScore);
            Data.setUserActive(userID);
        }
        animLights();
        goBlinking();
    }

    @Override
    protected void onDestroy() {
        lightsHandler.removeCallbacksAndMessages(null);
        blinkHandler.removeCallbacksAndMessages(null);
        super.onDestroy();
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
        confirmExitApp();
    }

    private void safeStartGame() {
        try {
            Intent intent = new Intent(LegacyMainActivity.this, GameActivity.class);
            intent.putExtra("mode", "mono");
            startActivity(intent);
        } catch (Exception e) {
            Toast.makeText(this, getString(R.string.msg_open_game_failed), Toast.LENGTH_SHORT).show();
        }
    }

    private void confirmNewGame() {
        if (!AppPrefs.isDialogsEnabled(this)) {
            safeStartGame();
            return;
        }
        new androidx.appcompat.app.AlertDialog.Builder(this)
                .setTitle(getString(R.string.dialog_new_game_title))
                .setMessage(getString(R.string.dialog_new_game_message))
                .setPositiveButton(getString(R.string.yes), (dialog, which) -> safeStartGame())
                .setNegativeButton(getString(R.string.no), null)
                .show();
    }

    private void openOnlineOptions() {
        if (userID.equals("guest_local")) {
            Toast.makeText(this, "سجل الدخول أولاً للعب عبر الإنترنت", Toast.LENGTH_SHORT).show();
            return;
        }
        if (!Data.isNetworkAvailable(this)) {
            Toast.makeText(this, getString(R.string.msg_no_internet), Toast.LENGTH_SHORT).show();
            return;
        }

        final String myFriendCode = Data.buildFriendCode(userID);
        final EditText friendCodeInput = new EditText(this);
        friendCodeInput.setHint("أدخل كود صديقك");
        friendCodeInput.setInputType(InputType.TYPE_CLASS_TEXT);
        friendCodeInput.setSingleLine(true);
        friendCodeInput.setTextDirection(View.TEXT_DIRECTION_LTR);
        friendCodeInput.setHintTextColor(0x99FFFFFF);
        friendCodeInput.setTextColor(0xFFFFFFFF);
        int horizontalPadding = (int) (16 * getResources().getDisplayMetrics().density);
        int verticalPadding = (int) (12 * getResources().getDisplayMetrics().density);
        friendCodeInput.setPadding(horizontalPadding, verticalPadding, horizontalPadding, verticalPadding);

        final AlertDialog dialog = new AlertDialog.Builder(this)
                .setTitle("اللعب أونلاين")
                .setMessage("كودك: " + myFriendCode + "\nيمكنك بدء تحدي صديق أو البحث عن منافس عشوائي.")
                .setView(friendCodeInput)
                .setPositiveButton("مع صديق", null)
                .setNegativeButton("منافس عشوائي", (d, which) -> launchOnlineMatch(""))
                .setNeutralButton("نسخ كودي", null)
                .create();

        dialog.setOnShowListener(dialogInterface -> {
            dialog.getButton(AlertDialog.BUTTON_NEUTRAL).setOnClickListener(v -> {
                ClipboardManager clipboard = (ClipboardManager) getSystemService(Context.CLIPBOARD_SERVICE);
                if (clipboard != null) {
                    clipboard.setPrimaryClip(ClipData.newPlainText("friend_code", myFriendCode));
                }
                Toast.makeText(LegacyMainActivity.this, "تم نسخ كود الصديق", Toast.LENGTH_SHORT).show();
            });

            dialog.getButton(AlertDialog.BUTTON_POSITIVE).setOnClickListener(v -> {
                String friendCode = friendCodeInput.getText() == null
                        ? ""
                        : friendCodeInput.getText().toString().trim().toUpperCase();
                if (friendCode.isEmpty()) {
                    friendCodeInput.setError("أدخل كود الصديق");
                    return;
                }
                launchOnlineMatch(friendCode);
                dialog.dismiss();
            });
        });
        dialog.show();
    }

    private void launchOnlineMatch(String friendCode) {
        Intent intent = new Intent(LegacyMainActivity.this, OpponentActivity.class);
        if (friendCode != null && !friendCode.trim().isEmpty()) {
            intent.putExtra("matchMode", "friend");
            intent.putExtra("friendCode", friendCode.trim().toUpperCase());
        }
        startActivity(intent);
    }

    private void confirmExitApp() {
        if (!AppPrefs.isDialogsEnabled(this)) {
            if (!userID.equals("guest_local")) {
                Data.setUserInactive(userID);
            }
            finishAffinity();
            moveTaskToBack(true);
            return;
        }
        new androidx.appcompat.app.AlertDialog.Builder(this)
                .setTitle(getString(R.string.dialog_exit_title))
                .setMessage(getString(R.string.dialog_exit_message))
                .setPositiveButton(getString(R.string.yes), (dialog, which) -> {
                    if (!userID.equals("guest_local")) {
                        Data.setUserInactive(userID);
                    }
                    finishAffinity();
                    moveTaskToBack(true);
                })
                .setNegativeButton(getString(R.string.no), null)
                .show();
    }

}
