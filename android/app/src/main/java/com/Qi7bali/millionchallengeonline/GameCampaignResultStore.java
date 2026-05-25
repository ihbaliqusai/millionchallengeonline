package net.androidgaming.millionaire2024;

import android.util.Log;

import org.json.JSONObject;

final class GameCampaignResultStore {
    private final GameActivity activity;

    GameCampaignResultStore(GameActivity activity) {
        this.activity = activity;
    }

    void persistPendingStageResult(boolean completed, int money, int wrongAnswers) {
        if (!activity.campaignMode || activity.campaignResultPersisted) {
            return;
        }
        activity.campaignResultPersisted = true;
        activity.stopCampaignStageTimer();
        try {
            JSONObject payload = new JSONObject();
            int targetCount = activity.getCampaignTargetQuestionCount();
            int answeredCorrect = Math.max(0, Math.min(targetCount, activity.campaignCorrectAnswers));
            payload.put("mode", "campaign");
            payload.put("campaignId", activity.campaignId);
            payload.put("stageId", activity.campaignStageId);
            payload.put("stageType", activity.campaignStageType);
            boolean bossDefeated = activity.campaignBossBattle && activity.isCampaignBossDefeated();
            boolean effectiveCompleted = activity.campaignBossBattle ? bossDefeated : completed;
            int playerScore = activity.getCampaignPlayerScore();
            payload.put("completed", effectiveCompleted);
            payload.put("score", playerScore);
            payload.put("money", Math.max(0, money));
            payload.put("correctAnswers", answeredCorrect);
            payload.put("wrongAnswers", Math.max(activity.campaignWrongAnswers, Math.max(0, wrongAnswers)));
            payload.put("timeMs", Math.max(0L, System.currentTimeMillis() - activity.campaignStartedAtMs));
            payload.put("used5050", Math.max(0, activity.campaignUsed5050));
            payload.put("usedAudience", Math.max(0, activity.campaignUsedAudience));
            payload.put("usedCall", Math.max(0, activity.campaignUsedCall));
            payload.put("campaignMode", activity.campaignStageMode);
            payload.put("winCondition", activity.campaignWinCondition);
            payload.put("failureReason", effectiveCompleted ? "" : activity.safeString(activity.campaignFailureReason));
            payload.put("lives", Math.max(0, activity.campaignLives));
            payload.put("livesRemaining", Math.max(0, activity.campaignLivesRemaining));
            payload.put("maxWrongAnswers", Math.max(0, activity.campaignMaxWrongAnswers));
            payload.put("targetScore", Math.max(0, activity.campaignTargetScore));
            payload.put("playerScore", Math.max(0, playerScore));
            payload.put("opponentName", activity.safeString(activity.campaignOpponentName));
            payload.put("opponentAccuracy", Math.max(0, activity.campaignOpponentAccuracy));
            payload.put("opponentScore", Math.max(0, activity.campaignOpponentScore));
            payload.put("opponentCorrectAnswers", Math.max(0, activity.campaignOpponentCorrectAnswers));
            payload.put("opponentWrongAnswers", Math.max(0, activity.campaignOpponentWrongAnswers));
            payload.put("bossName", activity.campaignBossOpponent != null ? activity.campaignBossOpponent.name : activity.safeString(activity.campaignBossBotName));
            payload.put("bossDefeated", bossDefeated);
            payload.put("bossBattleWon", bossDefeated);
            payload.put("bossScore", activity.campaignBossOpponent != null ? Math.max(0, activity.campaignBossOpponent.gameScore) : 0);
            payload.put("bossCorrectAnswers", activity.campaignBossOpponent != null ? Math.max(0, activity.campaignBossOpponent.totalCorrectAnswers) : 0);
            payload.put("bossWrongAnswers", activity.campaignBossOpponent != null ? Math.max(0, targetCount - activity.campaignBossOpponent.totalCorrectAnswers) : 0);
            payload.put("seriesRounds", Math.max(0, activity.campaignSeriesRounds));
            payload.put("seriesWinsRequired", Math.max(0, activity.campaignSeriesWinsRequired));
            payload.put("playerSeriesWins", Math.max(0, activity.campaignPlayerSeriesWins));
            payload.put("opponentSeriesWins", Math.max(0, activity.campaignOpponentSeriesWins));
            payload.put("teamAllyName", activity.safeString(activity.campaignTeamAllyName));
            payload.put("teamEnemyName", activity.safeString(activity.campaignTeamEnemyName));
            payload.put("allyScore", Math.max(0, activity.campaignAllyScore));
            payload.put("teamScore", Math.max(0, activity.campaignTeamScore));
            payload.put("enemyTeamScore", Math.max(0, activity.campaignEnemyTeamScore));
            if (activity.campaignBossBattle && activity.campaignBossOpponent != null) {
                payload.put("bossName", activity.campaignBossOpponent.name);
                payload.put("bossIntelligence", activity.campaignBossOpponent.intelligence);
                payload.put("bossDefeated", bossDefeated);
                payload.put("bossBattleWon", bossDefeated);
                payload.put("playerScore", Math.max(0, activity.gameScoreMe));
                payload.put("bossScore", Math.max(0, activity.campaignBossOpponent.gameScore));
                payload.put("bossCorrectAnswers", Math.max(0, activity.campaignBossOpponent.totalCorrectAnswers));
                payload.put("bossWrongAnswers", Math.max(0, targetCount - activity.campaignBossOpponent.totalCorrectAnswers));
            }
            AppPrefs.setPendingCampaignStageResult(activity, payload.toString());
            Log.d("CampaignStage", "CAMP_RESULT_SAVED stageId=" + activity.campaignStageId
                    + " completed=" + effectiveCompleted
                    + " correct=" + answeredCorrect
                    + " wrong=" + Math.max(activity.campaignWrongAnswers, Math.max(0, wrongAnswers)));
        } catch (Exception ignored) {
        }
    }
}
