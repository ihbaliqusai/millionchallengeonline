package net.androidgaming.millionaire2024;

import android.os.Bundle;
import android.widget.TextView;

/**
 * TeamBattle — فريقان (A مقابل B)، المجموع الكلي لنقاط الفريق يحدد الفائز.
 * يُعاد تعريف منطق نهاية المباراة لجمع نقاط كل فريق ومقارنتهما.
 */
public class TeamBattleGameActivity extends BaseGameActivity {

    private TextView txtTeamAScore;
    private TextView txtTeamBScore;

    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_team_battle;
    }

    @Override
    protected boolean isTeamBattleMode() {
        return true;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        txtTeamAScore = findViewById(R.id.txtTeamAScore);
        txtTeamBScore = findViewById(R.id.txtTeamBScore);
        updateTeamScores();
    }

    // ── حساب مجموع نقاط كل فريق ─────────────────────────────────────────────

    /** نقاط فريقي: مجموع نقاط اللاعبين في نفس الفريق (أنا + زملائي). */
    protected int getMyTeamScore() {
        int total = gameScoreMe;
        for (MatchOpponent op : getOpponentsList()) {
            if (myTeam != null && myTeam.equals(op.teamId)) {
                total += op.gameScore;
            }
        }
        return total;
    }

    /** نقاط الفريق المنافس. */
    protected int getEnemyTeamScore() {
        int total = 0;
        for (MatchOpponent op : getOpponentsList()) {
            if (myTeam == null || !myTeam.equals(op.teamId)) {
                total += op.gameScore;
            }
        }
        return total;
    }

    /** تحديث عرض نقاط الفريقين في الشاشة. */
    protected void updateTeamScores() {
        if (txtTeamAScore == null || txtTeamBScore == null) return;
        final boolean iAmA = "A".equals(myTeam);
        final int myScore   = getMyTeamScore();
        final int eneScore  = getEnemyTeamScore();
        runOnUiThread(() -> {
            if (iAmA) {
                txtTeamAScore.setText(String.valueOf(myScore));
                txtTeamBScore.setText(String.valueOf(eneScore));
            } else {
                txtTeamBScore.setText(String.valueOf(myScore));
                txtTeamAScore.setText(String.valueOf(eneScore));
            }
        });
    }

    // ── تحديث نقاط الفريق بعد كل جولة ──────────────────────────────────────

    @Override
    protected void onRoundMetricsApplied() {
        updateTeamScores();
    }

    // ── منطق الفوز: نلعب جميع الجولات، الأعلى نقاطاً يفوز ──────────────────

    @Override
    protected int getSeriesTarget() {
        // seriesTarget = 99 → لن يُحقَّق أبداً بـ 3 جولات فقط
        // ∴ تنتهي المباراة دائماً بعد السؤال 14 بمقارنة مجموع النقاط الكلية
        return 99;
    }
}
