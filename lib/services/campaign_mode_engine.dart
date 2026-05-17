import '../models/campaign_stage.dart';

class CampaignModeEngine {
  const CampaignModeEngine();

  String modeLabelArabic(CampaignMode mode) {
    switch (mode) {
      case CampaignMode.classic:
        return 'كلاسيكي';
      case CampaignMode.blitz:
        return 'سباق ضد الوقت';
      case CampaignMode.elimination:
        return 'إقصاء';
      case CampaignMode.survival:
        return 'نجاة';
      case CampaignMode.noLifeline:
        return 'بدون مساعدات';
      case CampaignMode.battle:
        return 'تنافسي';
      case CampaignMode.rival:
        return 'مطاردة';
      case CampaignMode.series:
        return 'سلسلة جولات';
      case CampaignMode.teamBattle:
        return 'معركة فريق';
      case CampaignMode.bossBattle:
        return 'مواجهة زعيم';
    }
  }

  String winConditionLabelArabic(CampaignWinCondition condition) {
    switch (condition) {
      case CampaignWinCondition.completeQuestions:
        return 'إنهاء الأسئلة';
      case CampaignWinCondition.finishBeforeTime:
        return 'الإنهاء قبل انتهاء الوقت';
      case CampaignWinCondition.survive:
        return 'النجاة حتى النهاية';
      case CampaignWinCondition.noMistakes:
        return 'تجنب الإقصاء';
      case CampaignWinCondition.beatOpponent:
        return 'هزيمة الخصم';
      case CampaignWinCondition.beatTargetScore:
        return 'تجاوز نتيجة الهدف';
      case CampaignWinCondition.winSeries:
        return 'الفوز بالسلسلة';
      case CampaignWinCondition.teamScore:
        return 'تفوق نتيجة الفريق';
      case CampaignWinCondition.defeatBoss:
        return 'هزيمة الزعيم';
    }
  }

  String objectiveText(CampaignStage stage) {
    switch (stage.campaignMode) {
      case CampaignMode.classic:
      case CampaignMode.noLifeline:
        return 'أجب عن ${stage.questionCount} أسئلة';
      case CampaignMode.blitz:
        return 'أنهِ ${stage.questionCount} أسئلة قبل انتهاء الوقت';
      case CampaignMode.elimination:
        return 'لا تتجاوز عدد الأخطاء المسموح';
      case CampaignMode.survival:
        final lives = stage.lives ?? 3;
        return 'لديك $lives أرواح';
      case CampaignMode.battle:
        return 'اجمع نقاطًا أكثر من الخصم';
      case CampaignMode.rival:
        return 'تجاوز نتيجة الهدف';
      case CampaignMode.series:
        return 'اربح السلسلة';
      case CampaignMode.teamBattle:
        return 'اجعل فريقك يتفوق بالنقاط';
      case CampaignMode.bossBattle:
        return 'اهزم الزعيم لفتح الطريق التالي';
    }
  }

  CampaignWinCondition defaultWinConditionForMode(CampaignMode mode) {
    return defaultWinConditionForCampaignMode(mode);
  }

  CampaignMode inferCampaignModeFromLegacyType(CampaignStageType type) {
    return campaignModeFromLegacyType(type);
  }

  bool shouldRequireOpponent(CampaignMode mode) {
    switch (mode) {
      case CampaignMode.battle:
      case CampaignMode.series:
      case CampaignMode.bossBattle:
        return true;
      case CampaignMode.classic:
      case CampaignMode.blitz:
      case CampaignMode.elimination:
      case CampaignMode.survival:
      case CampaignMode.noLifeline:
      case CampaignMode.rival:
      case CampaignMode.teamBattle:
        return false;
    }
  }

  bool isCompetitiveMode(CampaignMode mode) {
    switch (mode) {
      case CampaignMode.battle:
      case CampaignMode.rival:
      case CampaignMode.series:
      case CampaignMode.teamBattle:
      case CampaignMode.bossBattle:
        return true;
      case CampaignMode.classic:
      case CampaignMode.blitz:
      case CampaignMode.elimination:
      case CampaignMode.survival:
      case CampaignMode.noLifeline:
        return false;
    }
  }

  bool isBossMode(CampaignMode mode) => mode == CampaignMode.bossBattle;

  Map<String, dynamic> buildLaunchConfig(CampaignStage stage) {
    return <String, dynamic>{
      'campaignId': stage.campaignId,
      'stageId': stage.id,
      'stageType': stage.type.value,
      'campaignMode': stage.campaignMode.value,
      'winCondition': stage.winCondition.value,
      'questionCount': stage.questionCount,
      'timeLimitSeconds': stage.timeLimitSeconds,
      'allowedLevels': stage.allowedLevels,
      'allow5050': stage.allow5050,
      'allowAudience': stage.allowAudience,
      'allowCall': stage.allowCall,
      'lives': stage.lives,
      'maxWrongAnswers': stage.maxWrongAnswers,
      'targetScore': stage.targetScore,
      'opponentName': stage.opponentName,
      'opponentAccuracy': stage.opponentAccuracy,
      'opponentStartScore': stage.opponentStartScore,
      'bossBotName': stage.bossBotName,
      'bossBotIntelligence': stage.bossBotIntelligence,
      'seriesRounds': stage.seriesRounds,
      'seriesWinsRequired': stage.seriesWinsRequired,
      'teamAllyName': stage.teamAllyName,
      'teamEnemyName': stage.teamEnemyName,
    };
  }
}
