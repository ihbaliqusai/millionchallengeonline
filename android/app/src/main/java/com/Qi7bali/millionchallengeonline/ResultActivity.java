package net.androidgaming.millionaire2024;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import org.json.JSONArray;
import org.json.JSONObject;

import de.hdodenhof.circleimageview.CircleImageView;

public class ResultActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN
        );
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_result);
        if (getSupportActionBar() != null) getSupportActionBar().hide();

        String myName = getIntent().getStringExtra("myName");
        String myPhoto = getIntent().getStringExtra("myPhoto");
        String opponentName = getIntent().getStringExtra("opponentName");
        String opponentPhoto = getIntent().getStringExtra("opponentPhoto");
        int myScore = getIntent().getIntExtra("myScore", 0);
        int myNewScore = getIntent().getIntExtra("myNewScore", 0);
        int opponentScore = getIntent().getIntExtra("opponentScore", 0);
        int mySets = getIntent().getIntExtra("mySets", 0);
        int opponentSets = getIntent().getIntExtra("opponentSets", 0);
        boolean opponentLeft = getIntent().getBooleanExtra("opponentLeft", false);
        boolean didWin = getIntent().getBooleanExtra("didWin", false);
        String winnerName = getIntent().getStringExtra("winnerName");
        String opponentsJson = getIntent().getStringExtra("opponentsJson");
        String matchMode = getIntent().getStringExtra("matchMode");
        String myTeam = getIntent().getStringExtra("myTeam");
        String winnerTeamId = getIntent().getStringExtra("winnerTeamId");
        int teamAScore = getIntent().getIntExtra("teamAScore", 0);
        int teamBScore = getIntent().getIntExtra("teamBScore", 0);
        boolean isTeamBattle = getIntent().getBooleanExtra("isTeamBattle", false)
                || "team_battle".equals(matchMode);

        CircleImageView imgMe = findViewById(R.id.imgMe);
        CircleImageView imgOpponent = findViewById(R.id.imgOpponent);
        TextView txtMyName = findViewById(R.id.txtMyName);
        TextView txtMyScore = findViewById(R.id.txtMyScore);
        TextView txtOpponentName = findViewById(R.id.txtOpponentName);
        TextView txtOpponentScore = findViewById(R.id.txtOpponentScore);
        TextView txtResult = findViewById(R.id.txtResult);
        TextView txtScore = findViewById(R.id.txtScore);
        TextView txtMySets = findViewById(R.id.txtMySets);
        TextView txtOpponentSets = findViewById(R.id.txtOpponentSets);
        LinearLayout llyOpponentsSummary = findViewById(R.id.llyOpponentsSummary);

        JSONArray opponents = new JSONArray();
        try {
            if (opponentsJson != null && !opponentsJson.trim().isEmpty()) {
                opponents = new JSONArray(opponentsJson);
            }
        } catch (Exception ignored) {
        }

        JSONObject primaryOpponent = selectPrimaryOpponent(opponents, isTeamBattle, myTeam);
        if (primaryOpponent != null) {
            opponentName = primaryOpponent.optString("name", opponentName);
            opponentPhoto = primaryOpponent.optString("photo", opponentPhoto);
            opponentScore = primaryOpponent.optInt("score", opponentScore);
            opponentSets = primaryOpponent.optInt("sets", opponentSets);
        }

        Data.setImageSource(this, imgMe, myPhoto);
        Data.setImageSource(this, imgOpponent, opponentPhoto);
        txtMyName.setText(myName);
        txtMyScore.setText(String.valueOf(myScore));
        txtMySets.setText(String.valueOf(mySets));
        txtOpponentName.setText(opponentName);
        txtOpponentScore.setText(String.valueOf(opponentScore));
        txtOpponentSets.setText(String.valueOf(opponentSets));

        if (isTeamBattle) {
            txtMyName.setText(
                    myName + "  |  Team " + safeTeamLabel(myTeam)
            );
            if (primaryOpponent != null) {
                txtOpponentName.setText(
                        primaryOpponent.optString("name", opponentName)
                                + "  |  Team "
                                + safeTeamLabel(primaryOpponent.optString("teamId", ""))
                );
            }
        }

        if (mySets == 0 && opponentSets == 0) {
            txtMySets.setVisibility(View.GONE);
            txtOpponentSets.setVisibility(View.GONE);
        }

        PlayerProgress.onOnlineMatchFinished(this, didWin || opponentLeft, mySets);
        PlayerStats.recordGameEnd(this, didWin || opponentLeft, myScore * 1000);

        if (opponentLeft) {
            txtResult.setText("الخصم غادر المباراة");
            txtScore.setText("رصيدك الجديد: " + myNewScore);
        } else if (isTeamBattle) {
            if (winnerTeamId == null || winnerTeamId.trim().isEmpty()) {
                txtResult.setText("انتهت مباراة الفرق بتعادل");
            } else {
                txtResult.setText("الفريق " + winnerTeamId + " فاز بالمباراة");
            }
            txtScore.setText(
                    "Team A: " + teamAScore
                            + "  |  Team B: " + teamBScore
                            + "  |  فريقك: " + safeTeamLabel(myTeam)
            );
        } else if (didWin) {
            txtResult.setText("مبروك، لقد فزت بالمباراة");
            txtScore.setText("رصيدك الجديد: " + myNewScore);
        } else {
            txtResult.setText("للأسف لقد خسرت المباراة");
            String resolvedWinner = winnerName == null || winnerName.trim().isEmpty()
                    ? opponentName
                    : winnerName;
            txtScore.setText("الفائز: " + resolvedWinner);
        }

        final boolean anySetsNonZero = hasAnySets(opponents, mySets);
        if (isTeamBattle) {
            llyOpponentsSummary.addView(buildSummaryTextView(
                    myName + "  |  Team " + safeTeamLabel(myTeam) + "  |  النقاط: " + myScore
            ));
        }

        for (int i = 0; i < opponents.length(); i++) {
            JSONObject opponent = opponents.optJSONObject(i);
            if (opponent == null) {
                continue;
            }
            StringBuilder builder = new StringBuilder();
            builder.append(opponent.optString("name", "لاعب"));
            if (isTeamBattle) {
                builder.append("  |  Team ").append(safeTeamLabel(opponent.optString("teamId", "")));
            }
            if (anySetsNonZero) {
                builder.append("  |  الجولات: ").append(opponent.optInt("sets", 0));
            }
            int score = opponent.optInt("score", 0);
            int correct = opponent.optInt("correctAnswers", score / 10);
            builder.append("  |  ").append(correct).append(" إجابة صحيحة");
            builder.append("  |  النقاط: ").append(score);
            if (opponent.optBoolean("bot", false)) {
                builder.append("  |  ذكاء: ").append(opponent.optInt("intelligence", 0)).append('%');
            }
            llyOpponentsSummary.addView(buildSummaryTextView(builder.toString()));
        }

        findViewById(R.id.btnNewGame).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                if (Data.isNetworkAvailable(ResultActivity.this)) {
                    Intent intent = new Intent(ResultActivity.this, OpponentActivity.class);
                    intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                    startActivity(intent);
                } else {
                    Toast.makeText(ResultActivity.this, "لا يوجد اتصال بالإنترنت", Toast.LENGTH_SHORT).show();
                }
            }
        });
        findViewById(R.id.btnHome).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                Intent intent = new Intent(ResultActivity.this, MainActivity.class);
                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                startActivity(intent);
            }
        });
    }

    private JSONObject selectPrimaryOpponent(
            JSONArray opponents,
            boolean isTeamBattle,
            String myTeam
    ) {
        JSONObject bestOverall = null;
        JSONObject bestEnemy = null;
        for (int i = 0; i < opponents.length(); i++) {
            JSONObject candidate = opponents.optJSONObject(i);
            if (candidate == null) {
                continue;
            }
            if (bestOverall == null
                    || candidate.optInt("score", 0) > bestOverall.optInt("score", 0)) {
                bestOverall = candidate;
            }
            if (isTeamBattle
                    && myTeam != null
                    && !myTeam.trim().isEmpty()
                    && !myTeam.equals(candidate.optString("teamId", ""))
                    && (bestEnemy == null
                    || candidate.optInt("score", 0) > bestEnemy.optInt("score", 0))) {
                bestEnemy = candidate;
            }
        }
        return bestEnemy != null ? bestEnemy : bestOverall;
    }

    private boolean hasAnySets(JSONArray opponents, int mySets) {
        if (mySets > 0) {
            return true;
        }
        for (int i = 0; i < opponents.length(); i++) {
            JSONObject opponent = opponents.optJSONObject(i);
            if (opponent != null && opponent.optInt("sets", 0) > 0) {
                return true;
            }
        }
        return false;
    }

    private TextView buildSummaryTextView(String text) {
        TextView summary = new TextView(this);
        summary.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        ));
        summary.setTextColor(getResources().getColor(android.R.color.white));
        summary.setTextSize(18);
        summary.setPadding(16, 8, 16, 8);
        summary.setText(text);
        return summary;
    }

    private String safeTeamLabel(String teamId) {
        return teamId == null || teamId.trim().isEmpty() ? "-" : teamId.trim();
    }
}
