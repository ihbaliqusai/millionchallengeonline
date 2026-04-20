package net.androidgaming.millionaire2024;

import android.os.Bundle;
import android.widget.TextView;

public class SurvivalGameActivity extends BaseGameActivity {

    private TextView life1, life2, life3;

    private static final String HEART_FULL  = "♥";
    private static final String HEART_EMPTY = "♡";
    private static final int    COLOR_FULL  = 0xFFE53935; // أحمر
    private static final int    COLOR_EMPTY = 0xFF616161; // رمادي

    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_survival;
    }

    @Override
    protected boolean isSurvivalMode() {
        return true;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // تفعيل منطق الإقصاء المرحلي (نفس elimination لكن بـ 3 أرواح)
        eliminationMode = true;

        // ربط عناصر القلوب من الـ layout
        life1 = findViewById(R.id.imgLife1);
        life2 = findViewById(R.id.imgLife2);
        life3 = findViewById(R.id.imgLife3);

        refreshMyLives();
    }

    // ── تحديث القلوب عند خسارة اللاعب الحالي روحاً ─────────────────────────

    @Override
    protected void onMyLifeLost() {
        runOnUiThread(this::refreshMyLives);
    }

    private void refreshMyLives() {
        setHeart(life1, myLivesRemaining >= 1);
        setHeart(life2, myLivesRemaining >= 2);
        setHeart(life3, myLivesRemaining >= 3);
    }

    private void setHeart(TextView tv, boolean alive) {
        if (tv == null) return;
        tv.setText(alive ? HEART_FULL : HEART_EMPTY);
        tv.setTextColor(alive ? COLOR_FULL : COLOR_EMPTY);
    }

    // ── تحديث قلوب الخصوم (اختياري — يمكن توسيعه لاحقاً) ──────────────────

    @Override
    protected void onOpponentLifeLost(Object opponentObj) {
        // يمكن لاحقاً إضافة عرض الأرواح لكل خصم في لوحة النتائج
    }
}
