package com.Qi7bali.millionchallengeonline;

import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;

public class AchievementsActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_achievements);
        if (getSupportActionBar() != null) getSupportActionBar().hide();

        findViewById(R.id.btnAchievementsBack).setOnClickListener(v -> finish());
        bind();
    }

    private void bind() {
        bindOne(R.id.txtAch1, PlayerProgress.ACH_FIRST_GAME, "🎮 أول لعبة", "ابدأ أول جولة");
        bindOne(R.id.txtAch2, PlayerProgress.ACH_FIRST_WIN, "🏆 أول فوز", "افز بجولة كاملة");
        bindOne(R.id.txtAch3, PlayerProgress.ACH_STREAK_5, "🔥 سلسلة 5", "أجب 5 إجابات صحيحة متتالية");
        bindOne(R.id.txtAch4, PlayerProgress.ACH_STREAK_10, "⚡ سلسلة 10", "أجب 10 إجابات صحيحة متتالية");
        bindOne(R.id.txtAch5, PlayerProgress.ACH_PRIZE_1000, "💵 مبلغ 1000", "احصل على 1000$");
        bindOne(R.id.txtAch6, PlayerProgress.ACH_PRIZE_32000, "💰 مبلغ 32000", "احصل على 32000$");
        bindOne(R.id.txtAch7, PlayerProgress.ACH_PRIZE_1000000, "👑 المليون", "اربح المليون");
        bindOne(R.id.txtAch8, PlayerProgress.ACH_USE_ALL_HELPS, "🧠 كل المساعدات", "استخدم كل وسائل المساعدة في جولة واحدة");
        bindOne(R.id.txtAch9, PlayerProgress.ACH_COINS_5000, "🪙 5000 قطعة", "اجمع 5000 قطعة");
        bindOne(R.id.txtAch10, PlayerProgress.ACH_LEVEL_5, "⭐ المستوى 5", "وصل إلى المستوى الخامس");

        int unlocked = 0;
        String[] keys = new String[]{
                PlayerProgress.ACH_FIRST_GAME,
                PlayerProgress.ACH_FIRST_WIN,
                PlayerProgress.ACH_STREAK_5,
                PlayerProgress.ACH_STREAK_10,
                PlayerProgress.ACH_PRIZE_1000,
                PlayerProgress.ACH_PRIZE_32000,
                PlayerProgress.ACH_PRIZE_1000000,
                PlayerProgress.ACH_USE_ALL_HELPS,
                PlayerProgress.ACH_COINS_5000,
                PlayerProgress.ACH_LEVEL_5
        };
        for (String k : keys) if (PlayerProgress.isAchievementUnlocked(this, k)) unlocked++;
        ((TextView)findViewById(R.id.txtAchievementsSummary)).setText("المنجز: " + unlocked + " / " + keys.length);
    }

    private void bindOne(int id, String key, String title, String desc) {
        TextView v = findViewById(id);
        boolean unlocked = PlayerProgress.isAchievementUnlocked(this, key);
        v.setText(title + "\n" + desc + "\n" + (unlocked ? "مفتوح ✅" : "مغلق 🔒"));
        v.setAlpha(unlocked ? 1f : 0.65f);
    }
}
