package net.androidgaming.millionaire2024;

import androidx.appcompat.app.AppCompatActivity;

import android.animation.AnimatorSet;
import android.animation.ObjectAnimator;
import android.animation.ValueAnimator;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.Typeface;
import android.os.Bundle;
import android.text.TextUtils;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.OvershootInterpolator;
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
        int myCorrectAnswers = getIntent().getIntExtra("myCorrectAnswers", 0);
        int myLivesRemaining = getIntent().getIntExtra("myLivesRemaining", 0);
        int seriesTarget = getIntent().getIntExtra("seriesTarget", 0);
        int roundDurationSeconds = getIntent().getIntExtra("roundDurationSeconds", 0);
        boolean opponentLeft = getIntent().getBooleanExtra("opponentLeft", false);
        boolean didWin = getIntent().getBooleanExtra("didWin", false);
        boolean myEliminated = getIntent().getBooleanExtra("myEliminated", false);
        String winnerName = getIntent().getStringExtra("winnerName");
        String opponentsJson = getIntent().getStringExtra("opponentsJson");
        String matchMode = getIntent().getStringExtra("matchMode");
        String roomId = getIntent().getStringExtra("roomId");
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
        TextView txtModeTitle = findViewById(R.id.txtModeTitle);
        TextView txtModeSubtitle = findViewById(R.id.txtModeSubtitle);
        TextView txtResult = findViewById(R.id.txtResult);
        TextView txtScore = findViewById(R.id.txtScore);
        TextView txtResultDetails = findViewById(R.id.txtResultDetails);
        TextView txtMySets = findViewById(R.id.txtMySets);
        TextView txtOpponentSets = findViewById(R.id.txtOpponentSets);
        TextView txtOutcomeBadge = findViewById(R.id.txtOutcomeBadge);
        TextView txtMySetsLabel = findViewById(R.id.txtMySetsLabel);
        TextView txtOpponentSetsLabel = findViewById(R.id.txtOpponentSetsLabel);
        LinearLayout llyOpponentsSummary = findViewById(R.id.llyOpponentsSummary);
        View cardMe = findViewById(R.id.cardMe);
        View cardOpponent = findViewById(R.id.cardOpponent);
        View resultPanel = findViewById(R.id.resultPanel);
        View resultAura = findViewById(R.id.resultAura);
        View resultActions = findViewById(R.id.resultActions);

        JSONArray opponents = parseOpponents(opponentsJson);
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
        txtModeTitle.setText(resolveModeTitle(matchMode));
        txtModeSubtitle.setText(resolveModeSubtitle(matchMode, seriesTarget, roundDurationSeconds));

        if (isTeamBattle) {
            txtMyName.setText(myName + "  |  الفريق " + safeTeamLabel(myTeam));
            if (primaryOpponent != null) {
                txtOpponentName.setText(
                        primaryOpponent.optString("name", opponentName)
                                + "  |  الفريق "
                                + safeTeamLabel(primaryOpponent.optString("teamId", ""))
                );
            }
        }

        if (mySets == 0 && opponentSets == 0) {
            txtMySets.setText(String.valueOf(Math.max(0, myCorrectAnswers)));
            txtOpponentSets.setText(String.valueOf(Math.max(0, estimateOpponentCorrect(primaryOpponent, opponentScore))));
            txtMySetsLabel.setText("صحيحة");
            txtOpponentSetsLabel.setText("صحيحة");
        }

        final String completionKey = (roomId == null || roomId.trim().isEmpty())
                ? null
                : roomId.trim() + "|" + (matchMode == null ? "battle" : matchMode);
        PlayerProgress.onOnlineMatchFinished(
                this,
                didWin || opponentLeft,
                mySets,
                matchMode,
                true,
                completionKey
        );
        PlayerStats.recordGameEnd(this, didWin || opponentLeft, myScore * 1000);

        final String resolvedWinner = winnerName == null || winnerName.trim().isEmpty()
                ? opponentName
                : winnerName;
        final boolean isTie = isTieResult(matchMode, didWin, opponentLeft, myEliminated, winnerTeamId, myScore, opponentScore, mySets, opponentSets);
        final boolean positiveResult = isPositiveResult(matchMode, didWin, opponentLeft, myTeam, winnerTeamId);
        applyResultTheme(resultPanel, resultAura, txtOutcomeBadge, txtResult, positiveResult, isTie);

        txtResult.setText(resolveResultHeadline(matchMode, didWin, opponentLeft, myEliminated, winnerTeamId));
        txtScore.setText(resolvePerformanceLine(
                matchMode,
                myScore,
                myCorrectAnswers,
                mySets,
                opponentSets,
                myLivesRemaining,
                myEliminated,
                myTeam,
                roundDurationSeconds
        ));
        txtResultDetails.setText(resolveResultDetails(
                matchMode,
                didWin,
                opponentLeft,
                myNewScore,
                resolvedWinner,
                winnerTeamId,
                teamAScore,
                teamBScore,
                myTeam,
                seriesTarget
        ));

        final boolean anySetsNonZero = hasAnySets(opponents, mySets);
        llyOpponentsSummary.addView(buildSummaryTextView(
                buildSelfSummary(
                        matchMode,
                        myName,
                        myScore,
                        myCorrectAnswers,
                        mySets,
                        myTeam,
                        myEliminated,
                        myLivesRemaining,
                        anySetsNonZero
                ),
                true
        ));

        for (int i = 0; i < opponents.length(); i++) {
            JSONObject opponent = opponents.optJSONObject(i);
            if (opponent == null) {
                continue;
            }
            llyOpponentsSummary.addView(buildSummaryTextView(
                    buildOpponentSummary(matchMode, opponent, anySetsNonZero),
                    false
            ));
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

        runEntranceMotion(cardMe, cardOpponent, resultPanel, resultActions, resultAura);
    }

    private JSONArray parseOpponents(String opponentsJson) {
        try {
            if (opponentsJson != null && !opponentsJson.trim().isEmpty()) {
                return new JSONArray(opponentsJson);
            }
        } catch (Exception ignored) {
        }
        return new JSONArray();
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

    private TextView buildSummaryTextView(String text, boolean emphasize) {
        TextView summary = new TextView(this);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(34)
        );
        params.setMargins(0, emphasize ? dp(2) : dp(5), 0, 0);
        summary.setLayoutParams(params);
        summary.setBackgroundResource(R.drawable.result_summary_row);
        summary.setGravity(android.view.Gravity.CENTER_VERTICAL | android.view.Gravity.RIGHT);
        summary.setSingleLine(true);
        summary.setEllipsize(TextUtils.TruncateAt.END);
        summary.setIncludeFontPadding(false);
        summary.setTextColor(emphasize ? Color.rgb(56, 189, 248) : Color.WHITE);
        summary.setTextSize(emphasize ? 13 : 12);
        summary.setTypeface(summary.getTypeface(), emphasize ? Typeface.BOLD : Typeface.NORMAL);
        summary.setPadding(dp(12), 0, dp(12), 0);
        summary.setText(text);
        return summary;
    }

    private void applyResultTheme(
            View resultPanel,
            View resultAura,
            TextView txtOutcomeBadge,
            TextView txtResult,
            boolean positiveResult,
            boolean isTie
    ) {
        if (positiveResult) {
            resultPanel.setBackgroundResource(R.drawable.result_panel_win);
            resultAura.setBackgroundResource(R.drawable.result_panel_win);
            txtOutcomeBadge.setText("انتصار");
            txtOutcomeBadge.setTextColor(Color.rgb(167, 243, 208));
            txtResult.setTextColor(Color.WHITE);
            return;
        }
        if (isTie) {
            resultPanel.setBackgroundResource(R.drawable.result_panel_tie);
            resultAura.setBackgroundResource(R.drawable.result_panel_tie);
            txtOutcomeBadge.setText("تعادل");
            txtOutcomeBadge.setTextColor(Color.rgb(191, 219, 254));
            txtResult.setTextColor(Color.WHITE);
            return;
        }
        resultPanel.setBackgroundResource(R.drawable.result_panel_loss);
        resultAura.setBackgroundResource(R.drawable.result_panel_loss);
        txtOutcomeBadge.setText("خسارة");
        txtOutcomeBadge.setTextColor(Color.rgb(254, 202, 202));
        txtResult.setTextColor(Color.WHITE);
    }

    private void runEntranceMotion(
            View cardMe,
            View cardOpponent,
            View resultPanel,
            View resultActions,
            View resultAura
    ) {
        prepareForEntrance(cardMe, 42f);
        prepareForEntrance(cardOpponent, -42f);
        prepareForEntrance(resultPanel, 0f);
        resultPanel.setScaleX(0.94f);
        resultPanel.setScaleY(0.94f);
        resultActions.setAlpha(0f);
        resultActions.setTranslationY(dp(20));
        resultAura.setAlpha(0f);
        resultAura.setScaleX(0.7f);
        resultAura.setScaleY(0.7f);

        resultPanel.animate()
                .alpha(1f)
                .scaleX(1f)
                .scaleY(1f)
                .translationY(0f)
                .setDuration(520)
                .setStartDelay(80)
                .setInterpolator(new OvershootInterpolator(0.9f))
                .start();
        cardMe.animate()
                .alpha(1f)
                .translationX(0f)
                .translationY(0f)
                .setDuration(430)
                .setStartDelay(180)
                .setInterpolator(new DecelerateInterpolator())
                .start();
        cardOpponent.animate()
                .alpha(1f)
                .translationX(0f)
                .translationY(0f)
                .setDuration(430)
                .setStartDelay(220)
                .setInterpolator(new DecelerateInterpolator())
                .start();
        resultActions.animate()
                .alpha(1f)
                .translationY(0f)
                .setDuration(360)
                .setStartDelay(360)
                .setInterpolator(new DecelerateInterpolator())
                .start();

        AnimatorSet auraSet = new AnimatorSet();
        ObjectAnimator alpha = ObjectAnimator.ofFloat(resultAura, View.ALPHA, 0f, 0.30f, 0.16f);
        ObjectAnimator scaleX = ObjectAnimator.ofFloat(resultAura, View.SCALE_X, 0.7f, 1.08f);
        ObjectAnimator scaleY = ObjectAnimator.ofFloat(resultAura, View.SCALE_Y, 0.7f, 1.08f);
        alpha.setRepeatCount(ValueAnimator.INFINITE);
        alpha.setRepeatMode(ValueAnimator.REVERSE);
        scaleX.setRepeatCount(ValueAnimator.INFINITE);
        scaleX.setRepeatMode(ValueAnimator.REVERSE);
        scaleY.setRepeatCount(ValueAnimator.INFINITE);
        scaleY.setRepeatMode(ValueAnimator.REVERSE);
        auraSet.setDuration(1600);
        auraSet.playTogether(alpha, scaleX, scaleY);
        auraSet.setStartDelay(260);
        auraSet.start();
    }

    private void prepareForEntrance(View view, float translationX) {
        view.setAlpha(0f);
        view.setTranslationX(dpFloat(translationX));
        view.setTranslationY(dp(14));
    }

    private boolean isPositiveResult(
            String matchMode,
            boolean didWin,
            boolean opponentLeft,
            String myTeam,
            String winnerTeamId
    ) {
        if (opponentLeft || didWin) {
            return true;
        }
        return "team_battle".equals(matchMode)
                && winnerTeamId != null
                && myTeam != null
                && winnerTeamId.trim().equalsIgnoreCase(myTeam.trim());
    }

    private boolean isTieResult(
            String matchMode,
            boolean didWin,
            boolean opponentLeft,
            boolean myEliminated,
            String winnerTeamId,
            int myScore,
            int opponentScore,
            int mySets,
            int opponentSets
    ) {
        if (opponentLeft || didWin || myEliminated) {
            return false;
        }
        if ("team_battle".equals(matchMode)) {
            return winnerTeamId == null || winnerTeamId.trim().isEmpty();
        }
        if (mySets > 0 || opponentSets > 0) {
            return mySets == opponentSets;
        }
        return myScore == opponentScore;
    }

    private int estimateOpponentCorrect(JSONObject primaryOpponent, int opponentScore) {
        if (primaryOpponent != null) {
            return primaryOpponent.optInt(
                    "correctAnswers",
                    primaryOpponent.optInt("answeredCount", Math.max(0, opponentScore / 10))
            );
        }
        return Math.max(0, opponentScore / 10);
    }

    private int dp(int value) {
        return Math.round(value * getResources().getDisplayMetrics().density);
    }

    private float dpFloat(float value) {
        return value * getResources().getDisplayMetrics().density;
    }

    private String resolveModeTitle(String matchMode) {
        if ("series".equals(matchMode)) {
            return "طور السلسلة";
        }
        if ("team_battle".equals(matchMode)) {
            return "طور المعركة الجماعية";
        }
        if ("blitz".equals(matchMode)) {
            return "طور بلتز";
        }
        if ("elimination".equals(matchMode)) {
            return "طور الإقصاء";
        }
        if ("survival".equals(matchMode)) {
            return "طور البقاء";
        }
        return "طور المواجهة";
    }

    private String resolveModeSubtitle(String matchMode, int seriesTarget, int roundDurationSeconds) {
        if ("series".equals(matchMode) && seriesTarget > 0) {
            return "أول لاعب يصل إلى " + seriesTarget + " جولات يحسم السلسلة";
        }
        if ("team_battle".equals(matchMode)) {
            return "إجمالي نقاط الفريق هو الذي يحسم المباراة";
        }
        if ("blitz".equals(matchMode) && roundDurationSeconds > 0) {
            return "أجب بأسرع ما يمكن خلال " + roundDurationSeconds + " ثانية";
        }
        if ("elimination".equals(matchMode)) {
            return "خطأ واحد قد يخرج اللاعب من المنافسة";
        }
        if ("survival".equals(matchMode)) {
            return "ثلاث أرواح فقط.. وآخر لاعب صامد يفوز";
        }
        return "أفضل أداء عبر الجولات هو الذي يصنع الفارق";
    }

    private String resolveResultHeadline(
            String matchMode,
            boolean didWin,
            boolean opponentLeft,
            boolean myEliminated,
            String winnerTeamId
    ) {
        if (opponentLeft) {
            return "الخصم غادر المباراة";
        }
        if ("team_battle".equals(matchMode)) {
            if (winnerTeamId == null || winnerTeamId.trim().isEmpty()) {
                return "انتهت معركة الفرق بالتعادل";
            }
            return "الفريق " + safeTeamLabel(winnerTeamId) + " حسم المواجهة";
        }
        if ("blitz".equals(matchMode)) {
            return didWin ? "أنهيت بلتز في الصدارة" : "انتهت جولة بلتز";
        }
        if ("elimination".equals(matchMode)) {
            if (didWin) {
                return "نجوت حتى النهاية وتصدرت الإقصاء";
            }
            return myEliminated ? "تم إقصاؤك من المنافسة" : "انتهت مباراة الإقصاء";
        }
        if ("survival".equals(matchMode)) {
            if (didWin) {
                return "كنت آخر لاعب صامد";
            }
            return myEliminated ? "نفدت أرواحك في طور البقاء" : "انتهت جولة البقاء";
        }
        if ("series".equals(matchMode)) {
            return didWin ? "حسمت السلسلة لصالحك" : "انتهت السلسلة";
        }
        return didWin ? "مبروك، لقد فزت بالمباراة" : "للأسف، لقد خسرت المباراة";
    }

    private String resolvePerformanceLine(
            String matchMode,
            int myScore,
            int myCorrectAnswers,
            int mySets,
            int opponentSets,
            int myLivesRemaining,
            boolean myEliminated,
            String myTeam,
            int roundDurationSeconds
    ) {
        if ("team_battle".equals(matchMode)) {
            return "نقاطك: " + myScore + "  |  فريقك: " + safeTeamLabel(myTeam);
        }
        if ("blitz".equals(matchMode)) {
            String suffix = roundDurationSeconds > 0 ? "  |  الزمن: " + roundDurationSeconds + "ث" : "";
            return "إجاباتك الصحيحة: " + myCorrectAnswers + "  |  نقاطك: " + myScore + suffix;
        }
        if ("survival".equals(matchMode)) {
            String status = myEliminated ? "خارج" : ("الأرواح: " + Math.max(0, myLivesRemaining));
            return status + "  |  الصحيح: " + myCorrectAnswers + "  |  النقاط: " + myScore;
        }
        if ("elimination".equals(matchMode)) {
            return (myEliminated ? "الحالة: خرجت" : "الحالة: نجوت")
                    + "  |  الصحيح: " + myCorrectAnswers
                    + "  |  النقاط: " + myScore;
        }
        if (mySets > 0 || opponentSets > 0) {
            return "الجولات: " + mySets + " - " + opponentSets
                    + "  |  الصحيح: " + myCorrectAnswers
                    + "  |  النقاط: " + myScore;
        }
        return "إجاباتك الصحيحة: " + myCorrectAnswers + "  |  النقاط: " + myScore;
    }

    private String resolveResultDetails(
            String matchMode,
            boolean didWin,
            boolean opponentLeft,
            int myNewScore,
            String resolvedWinner,
            String winnerTeamId,
            int teamAScore,
            int teamBScore,
            String myTeam,
            int seriesTarget
    ) {
        if (opponentLeft) {
            return "تم احتساب الفوز لك. رصيدك الجديد: " + myNewScore;
        }
        if ("team_battle".equals(matchMode)) {
            String winnerLine = (winnerTeamId == null || winnerTeamId.trim().isEmpty())
                    ? "لا يوجد فريق فائز"
                    : "الفريق الفائز: " + safeTeamLabel(winnerTeamId);
            return winnerLine
                    + "  |  الفريق أ: " + teamAScore
                    + "  |  الفريق ب: " + teamBScore
                    + "  |  فريقك: " + safeTeamLabel(myTeam);
        }
        if (didWin) {
            if ("series".equals(matchMode) && seriesTarget > 0) {
                return "أنهيت السلسلة بنجاح. رصيدك الجديد: " + myNewScore;
            }
            return "رصيدك الجديد: " + myNewScore;
        }
        return "الفائز: " + resolvedWinner;
    }

    private String buildSelfSummary(
            String matchMode,
            String myName,
            int myScore,
            int myCorrectAnswers,
            int mySets,
            String myTeam,
            boolean myEliminated,
            int myLivesRemaining,
            boolean anySetsNonZero
    ) {
        StringBuilder builder = new StringBuilder();
        builder.append(myName == null || myName.trim().isEmpty() ? "أنت" : myName);
        if ("team_battle".equals(matchMode)) {
            builder.append("  |  الفريق ").append(safeTeamLabel(myTeam));
        }
        appendModeState(builder, matchMode, myEliminated, myLivesRemaining, mySets, anySetsNonZero);
        builder.append("  |  الصحيح: ").append(myCorrectAnswers);
        builder.append("  |  النقاط: ").append(myScore);
        return builder.toString();
    }

    private String buildOpponentSummary(String matchMode, JSONObject opponent, boolean anySetsNonZero) {
        StringBuilder builder = new StringBuilder();
        builder.append(opponent.optString("name", "لاعب"));
        if ("team_battle".equals(matchMode)) {
            builder.append("  |  الفريق ").append(safeTeamLabel(opponent.optString("teamId", "")));
        }
        appendModeState(
                builder,
                matchMode,
                opponent.optBoolean("eliminated", false),
                opponent.optInt("livesRemaining", 0),
                opponent.optInt("sets", 0),
                anySetsNonZero
        );
        int score = opponent.optInt("score", 0);
        int correct = opponent.optInt(
                "correctAnswers",
                opponent.optInt("answeredCount", score / 10)
        );
        builder.append("  |  الصحيح: ").append(correct);
        builder.append("  |  النقاط: ").append(score);
        if (opponent.optBoolean("bot", false)) {
            builder.append("  |  ذكاء: ").append(opponent.optInt("intelligence", 0)).append('%');
        }
        return builder.toString();
    }

    private void appendModeState(
            StringBuilder builder,
            String matchMode,
            boolean eliminated,
            int livesRemaining,
            int sets,
            boolean anySetsNonZero
    ) {
        if ("survival".equals(matchMode)) {
            builder.append("  |  ");
            builder.append(eliminated ? "خارج" : ("الأرواح: " + Math.max(0, livesRemaining)));
            return;
        }
        if ("elimination".equals(matchMode)) {
            builder.append("  |  ");
            builder.append(eliminated ? "خارج" : "مستمر");
            return;
        }
        if (anySetsNonZero) {
            builder.append("  |  الجولات: ").append(sets);
        }
    }

    private String safeTeamLabel(String teamId) {
        if (teamId == null || teamId.trim().isEmpty()) return "-";
        if ("A".equalsIgnoreCase(teamId.trim())) return "أ";
        if ("B".equalsIgnoreCase(teamId.trim())) return "ب";
        return teamId.trim();
    }
}
