package net.androidgaming.millionaire2024;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.TextView;

public class TeamBattleGameActivity extends BaseGameActivity {

    private TextView txtTeamAHeroScore;
    private TextView txtTeamBHeroScore;
    private View cardTeamA;
    private View cardTeamB;

    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_team_battle;
    }

    @Override
    protected String getMatchModeId() {
        return "team_battle";
    }

    @Override
    protected boolean isTeamBattleMode() {
        return true;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        txtTeamAHeroScore = findViewById(R.id.txtTeamAHeroScore);
        txtTeamBHeroScore = findViewById(R.id.txtTeamBHeroScore);
        cardTeamA = findViewById(R.id.cardTeamA);
        cardTeamB = findViewById(R.id.cardTeamB);
        applyTeamIdentityVisuals();
        updateTeamScores();
    }

    private void applyTeamIdentityVisuals() {
        final boolean iAmA = "A".equals(myTeam);

        if (cardTeamA != null && cardTeamB != null) {
            cardTeamA.setAlpha(iAmA ? 1f : 0.78f);
            cardTeamB.setAlpha(iAmA ? 0.78f : 1f);
            cardTeamA.setScaleX(iAmA ? 1.04f : 1f);
            cardTeamA.setScaleY(iAmA ? 1.04f : 1f);
            cardTeamB.setScaleX(iAmA ? 1f : 1.04f);
            cardTeamB.setScaleY(iAmA ? 1f : 1.04f);
        }
    }

    protected int getMyTeamScore() {
        int total = gameScoreMe;
        for (MatchOpponent opponent : getOpponentsList()) {
            if (myTeam != null && myTeam.equals(opponent.teamId)) {
                total += opponent.gameScore;
            }
        }
        return total;
    }

    protected int getEnemyTeamScore() {
        int total = 0;
        for (MatchOpponent opponent : getOpponentsList()) {
            if (myTeam == null || !myTeam.equals(opponent.teamId)) {
                total += opponent.gameScore;
            }
        }
        return total;
    }

    protected void updateTeamScores() {
        final boolean iAmA = "A".equals(myTeam);
        final int myScore = getMyTeamScore();
        final int enemyScore = getEnemyTeamScore();
        runOnUiThread(() -> {
            if (txtTeamAHeroScore != null) {
                txtTeamAHeroScore.setText(String.valueOf(iAmA ? myScore : enemyScore));
            }
            if (txtTeamBHeroScore != null) {
                txtTeamBHeroScore.setText(String.valueOf(iAmA ? enemyScore : myScore));
            }
        });
    }

    @Override
    protected void onRoundMetricsApplied() {
        updateTeamScores();
    }

    private int getScoreForTeam(String teamId) {
        int total = teamId != null && teamId.equals(myTeam) ? gameScoreMe : 0;
        for (MatchOpponent opponent : getOpponentsList()) {
            if (teamId != null && teamId.equals(opponent.teamId)) {
                total += opponent.gameScore;
            }
        }
        return total;
    }

    @Override
    protected OnlineResultState buildOnlineResultState() {
        final int teamAScore = getScoreForTeam("A");
        final int teamBScore = getScoreForTeam("B");
        final String winnerTeamId = teamAScore > teamBScore
                ? "A"
                : (teamBScore > teamAScore ? "B" : "");
        final boolean didWin = !winnerTeamId.isEmpty() && winnerTeamId.equals(myTeam);
        final String winnerName = winnerTeamId.isEmpty()
                ? ""
                : ("الفريق " + ("A".equals(winnerTeamId) ? "أ" : "ب"));
        final int opponentBestScore = "A".equals(myTeam) ? teamBScore : teamAScore;
        return new OnlineResultState(didWin, winnerName, opponentBestScore);
    }

    @Override
    protected void applyModeSpecificResultIntent(Intent intent, OnlineResultState resultState) {
        final int teamAScore = getScoreForTeam("A");
        final int teamBScore = getScoreForTeam("B");
        final String winnerTeamId = teamAScore > teamBScore
                ? "A"
                : (teamBScore > teamAScore ? "B" : "");
        intent.putExtra("isTeamBattle", true);
        intent.putExtra("teamAScore", teamAScore);
        intent.putExtra("teamBScore", teamBScore);
        intent.putExtra("winnerTeamId", winnerTeamId);
    }

    @Override
    protected int getSeriesTarget() {
        // أفضل من 3 جولات: ينتهي عند 2-0 وتُلعب الجولة الثالثة فقط لكسر التعادل 1-1
        return 2;
    }
}
