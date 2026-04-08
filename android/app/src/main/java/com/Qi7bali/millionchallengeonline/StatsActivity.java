package com.Qi7bali.millionchallengeonline;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;

public class StatsActivity extends AppCompatActivity {
    @Override
    protected void onCreate(Bundle savedInstanceState) {
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_stats);
        if (getSupportActionBar() != null) getSupportActionBar().hide();

        bind();

        findViewById(R.id.btnStatsBack).setOnClickListener(v -> finish());
        findViewById(R.id.btnResetStats).setOnClickListener(v -> new AlertDialog.Builder(StatsActivity.this)
                .setTitle("تصفير الإحصائيات")
                .setMessage("هل تريد حذف الإحصائيات المحفوظة؟")
                .setPositiveButton("نعم", (d, i) -> {
                    PlayerStats.reset(StatsActivity.this);
                    bind();
                })
                .setNegativeButton("إلغاء", null)
                .show());
    }

    private void bind() {
        int games = PlayerStats.getGamesPlayed(this);
        int wins = PlayerStats.getWins(this);
        int losses = PlayerStats.getLosses(this);
        int highest = PlayerStats.getHighestMoney(this);
        int lastPrize = PlayerStats.getLastPrize(this);
        int correct = PlayerStats.getCorrectAnswers(this);
        int wrong = PlayerStats.getWrongAnswers(this);
        int total = PlayerStats.getTotalAnswered(this);
        int bestStreak = PlayerStats.getBestStreak(this);
        int accuracy = total == 0 ? 0 : Math.round((correct * 100f) / total);
        int level = PlayerProgress.getLevel(this);
        int coins = PlayerProgress.getCoins(this);
        int gems = PlayerProgress.getGems(this);

        setText(R.id.txtStatsGames, String.valueOf(games));
        setText(R.id.txtStatsWins, String.valueOf(wins));
        setText(R.id.txtStatsLosses, String.valueOf(losses));
        setText(R.id.txtStatsHighest, "$" + highest);
        setText(R.id.txtStatsLastPrize, "$" + lastPrize);
        setText(R.id.txtStatsCorrect, String.valueOf(correct));
        setText(R.id.txtStatsWrong, String.valueOf(wrong));
        setText(R.id.txtStatsAccuracy, accuracy + "%");
        setText(R.id.txtStatsBestStreak, String.valueOf(bestStreak));
        TextView extra = findViewById(R.id.txtStatsExtra);
        if (extra != null) {
            extra.setText("المستوى: " + level + "   |   القطع: " + coins + "   |   الجواهر: " + gems);
        }
    }

    private void setText(int id, String value) {
        ((TextView)findViewById(id)).setText(value);
    }
}
