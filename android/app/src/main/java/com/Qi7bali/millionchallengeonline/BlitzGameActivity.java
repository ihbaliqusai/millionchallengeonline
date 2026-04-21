package net.androidgaming.millionaire2024;

import android.graphics.Color;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.Handler;
import android.widget.TextView;

/**
 * Blitz — كل لاعب يتقدم بسرعته الخاصة دون انتظار الخصوم.
 *
 * قواعد العداد الكلي:
 *   - يبدأ العد مع ظهور أول سؤال (ليس عند فتح الشاشة)
 *   - يتوقف مؤقتاً عند إرسال الإجابة
 *   - يستأنف مع ظهور السؤال التالي
 *   - تنتهي المباراة عند نفاد الوقت أو نفاد الأسئلة
 *
 * الفوز/الخسارة:
 *   - الفائز = اللاعب الذي أجاب على أكثر الأسئلة بشكل صحيح
 *   - البوتات تُحاكى عبر مؤقت كلي: Very Smart=14 إجابة | Smart=11 | Normal=6 (في 60 ثانية)
 */
public class BlitzGameActivity extends BaseGameActivity {

    private TextView txtGlobalTimer;
    private CountDownTimer globalTimer;
    private int roundDurationSeconds = 60;
    private long globalMillisLeft;
    private boolean blitzFinished = false;
    private boolean timerEverStarted = false;

    private static final int COLOR_NORMAL  = Color.WHITE;
    private static final int COLOR_WARNING = Color.parseColor("#FFCC00"); // <= 20s
    private static final int COLOR_URGENT  = Color.parseColor("#FF3333"); // <= 10s

    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_blitz;
    }

    @Override
    protected boolean isBlitzMode() {
        return true;
    }

    @Override
    protected boolean shouldScheduleBotAnswers() {
        return false;
    }

    @Override
    protected int getBlitzRoundDurationSeconds() {
        return roundDurationSeconds;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        roundDurationSeconds = getIntent().getIntExtra("roundDurationSeconds", 60);
        globalMillisLeft = (long) roundDurationSeconds * 1000L;
        super.onCreate(savedInstanceState);

        txtGlobalTimer = findViewById(R.id.txtBlitzGlobalTimer);
        updateTimerText((int) (globalMillisLeft / 1000));
    }

    // ── هوكات BaseGameActivity ────────────────────────────────────────────────

    /** يُستدعى عند بدء مؤقت كل سؤال — نُشغّل أو نستأنف الوقت الكلي هنا */
    @Override
    protected void onQuestionTimerStarted() {
        timerEverStarted = true;
        resumeGlobalTimer();
    }

    /** يُستدعى عند إرسال اللاعب إجابته — نوقف الوقت الكلي مؤقتاً */
    @Override
    protected void onLocalAnswerSubmitted() {
        pauseGlobalTimer();
    }

    /** يُستدعى عند نفاد الأسئلة — ننهي المباراة فوراً */
    @Override
    protected void onQuestionsExhausted() {
        runOnUiThread(this::finishBlitzGame);
    }

    // ── منطق العداد الكلي ────────────────────────────────────────────────────

    private void resumeGlobalTimer() {
        if (blitzFinished || globalMillisLeft <= 0) return;
        cancelGlobalTimer();
        globalTimer = new CountDownTimer(globalMillisLeft, 100L) {
            @Override
            public void onTick(long millisUntilFinished) {
                globalMillisLeft = millisUntilFinished;
                int secsLeft = (int) (millisUntilFinished / 1000);
                runOnUiThread(() -> updateTimerText(secsLeft));
            }

            @Override
            public void onFinish() {
                globalMillisLeft = 0;
                runOnUiThread(() -> {
                    updateTimerText(0);
                    finishBlitzGame();
                });
            }
        };
        globalTimer.start();
    }

    private void pauseGlobalTimer() {
        cancelGlobalTimer();
        // globalMillisLeft was last updated in onTick — value is preserved
    }

    private void cancelGlobalTimer() {
        if (globalTimer != null) {
            globalTimer.cancel();
            globalTimer = null;
        }
    }

    private void updateTimerText(int secsLeft) {
        if (txtGlobalTimer == null) return;
        txtGlobalTimer.setText("\u23F1 " + secsLeft + "s");
        if (secsLeft <= 10) {
            txtGlobalTimer.setTextColor(COLOR_URGENT);
            txtGlobalTimer.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 22);
        } else if (secsLeft <= 20) {
            txtGlobalTimer.setTextColor(COLOR_WARNING);
            txtGlobalTimer.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 20);
        } else {
            txtGlobalTimer.setTextColor(COLOR_NORMAL);
            txtGlobalTimer.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, 18);
        }
    }

    // ── إنهاء المباراة ────────────────────────────────────────────────────────

    private void finishBlitzGame() {
        if (blitzFinished) return;
        blitzFinished = true;
        cancelGlobalTimer();
        cancelBlitzBotSimulation();
        new Handler().postDelayed(() -> openOnlineResultScreen(false), 300);
    }

    @Override
    protected void onDestroy() {
        cancelGlobalTimer();
        cancelBlitzBotSimulation();
        super.onDestroy();
    }
}
