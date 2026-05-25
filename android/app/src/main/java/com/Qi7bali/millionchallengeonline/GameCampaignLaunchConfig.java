package net.androidgaming.millionaire2024;

import android.util.Log;

import java.util.ArrayList;

final class GameCampaignLaunchConfig {
    private GameCampaignLaunchConfig() {
    }

    static void load(GameActivity activity, String modeExtra, String matchModeExtra) {
        activity.campaignMode = "campaign".equals(modeExtra);
        activity.campaignStartedAtMs = System.currentTimeMillis();
        activity.campaignId = activity.safeIntentString("campaignId", "main_campaign");
        activity.campaignStageId = activity.safeIntentString("stageId", "");
        activity.campaignStageType = activity.safeIntentString("stageType", "classic");
        activity.campaignStageMode = activity.normalizeCampaignMode(activity.safeIntentString("campaignMode", activity.campaignStageType));
        activity.campaignWinCondition = activity.safeIntentString("winCondition", activity.defaultCampaignWinCondition(activity.campaignStageMode));
        activity.campaignQuestionCount = Math.max(0, activity.getIntent().getIntExtra("questionCount", 10));
        activity.campaignTimeLimitSeconds = Math.max(0, activity.getIntent().getIntExtra("timeLimitSeconds", 0));
        activity.campaignAllow5050 = activity.getIntent().getBooleanExtra("allow5050", true);
        activity.campaignAllowAudience = activity.getIntent().getBooleanExtra("allowAudience", true);
        activity.campaignAllowCall = activity.getIntent().getBooleanExtra("allowCall", true);
        activity.campaignLives = Math.max(0, activity.getIntent().getIntExtra("lives", 0));
        activity.campaignMaxWrongAnswers = Math.max(0, activity.getIntent().getIntExtra("maxWrongAnswers", 0));
        activity.campaignTargetScore = Math.max(0, activity.getIntent().getIntExtra("targetScore", 0));
        activity.campaignOpponentName = activity.safeIntentString("opponentName", "");
        activity.campaignOpponentAccuracy = Math.max(0, activity.getIntent().getIntExtra("opponentAccuracy", 0));
        activity.campaignOpponentStartScore = Math.max(0, activity.getIntent().getIntExtra("opponentStartScore", 0));
        activity.campaignSeriesRounds = Math.max(0, activity.getIntent().getIntExtra("seriesRounds", 0));
        activity.campaignSeriesWinsRequired = Math.max(0, activity.getIntent().getIntExtra("seriesWinsRequired", 0));
        activity.campaignTeamAllyName = activity.safeIntentString("teamAllyName", "");
        activity.campaignTeamEnemyName = activity.safeIntentString("teamEnemyName", "");
        activity.campaignBossBotName = activity.safeIntentString("bossBotName", "");
        activity.campaignBossBotIntelligence = Math.max(0, activity.getIntent().getIntExtra("bossBotIntelligence", 0));

        ArrayList<Integer> stageQuestionIds = activity.getIntent().getIntegerArrayListExtra("questionIds");
        if (stageQuestionIds != null) {
            activity.campaignQuestionIds.addAll(stageQuestionIds);
        }
        ArrayList<String> stageAllowedLevels = activity.getIntent().getStringArrayListExtra("allowedLevels");
        if (stageAllowedLevels != null) {
            for (String level : stageAllowedLevels) {
                if (level != null && !level.trim().isEmpty()) {
                    activity.campaignAllowedLevels.add(level.trim());
                }
            }
        }
        if (activity.campaignMode && activity.isDebuggableBuild()) {
            Log.d("CampaignStage", "launch stageId=" + activity.campaignStageId
                    + " questionIds=" + activity.campaignQuestionIds.size()
                    + " allowedLevels=" + activity.campaignAllowedLevels);
        }
        activity.applyCampaignStageTypeDefaults();
        activity.modeOnline = "online".equals(modeExtra);
        activity.eliminationMode = "elimination".equals(matchModeExtra);
        activity.meOwner = activity.getIntent().getBooleanExtra("meOwner", true);
        activity.campaignBossBattle = activity.campaignMode && activity.isCampaignBossMode();
    }
}
