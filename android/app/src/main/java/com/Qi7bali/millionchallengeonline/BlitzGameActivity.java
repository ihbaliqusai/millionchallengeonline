package net.androidgaming.millionaire2024;

import android.os.Bundle;
import android.os.CountDownTimer;
import android.widget.TextView;

/**
 * Blitz — كل لاعب يتقدم بسرعته الخاصة دون انتظار الخصوم.
 * عداد عام للمباراة بالكامل (roundDurationSeconds)؛ عند انتهائه تنتهي المباراة.
 */
public class BlitzGameActivity extends BaseGameActivity {

    private TextView txtGlobalTimer;
    private CountDownTimer globalTimer;
    private int roundDurationSeconds = 60; // قيمة افتراضية

    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_blitz;
    }

    @Override
    protected boolean isBlitzMode() {
        return true;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        roundDurationSeconds = getIntent().getIntExtra("roundDurationSeconds", 60);
        super.onCreate(savedInstanceState);

        txtGlobalTimer = findViewById(R.id.txtBlitzGlobalTimer);
        startGlobalTimer();
    }

    // ── عداد وقت المباراة الكلي ───────────────────────────────────────────────

    private void startGlobalTimer() {
        if (globalTimer != null) globalTimer.cancel();
        globalTimer = new CountDownTimer((long) roundDurationSeconds * 1000L, 1000L) {
            @Override
            public void onTick(long millisUntilFinished) {
                int secsLeft = (int) (millisUntilFinished / 1000);
                if (txtGlobalTimer != null) {
                    runOnUiThread(() -> txtGlobalTimer.setText(secsLeft + "s"));
                }
            }

            @Override
            public void onFinish() {
                if (txtGlobalTimer != null) {
                    runOnUiThread(() -> txtGlobalTimer.setText("0s"));
                }
                // انتهى الوقت — اذهب لشاشة النتيجة
                runOnUiThread(() -> openOnlineResultScreen(false));
            }
        };
        globalTimer.start();
    }

    @Override
    protected void onDestroy() {
        if (globalTimer != null) {
            globalTimer.cancel();
            globalTimer = null;
        }
        super.onDestroy();
    }
}
