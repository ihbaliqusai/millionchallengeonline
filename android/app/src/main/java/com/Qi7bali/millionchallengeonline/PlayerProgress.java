package net.androidgaming.millionaire2024;

import android.content.Context;
import android.content.SharedPreferences;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class PlayerProgress {
    private static final String PREF = "PlayerProgress";
    private static final int MATCH_COMPLETION_BONUS = 200;

    public static final String ACH_FIRST_GAME = "ACH_FIRST_GAME";
    public static final String ACH_FIRST_WIN = "ACH_FIRST_WIN";
    public static final String ACH_STREAK_5 = "ACH_STREAK_5";
    public static final String ACH_STREAK_10 = "ACH_STREAK_10";
    public static final String ACH_PRIZE_1000 = "ACH_PRIZE_1000";
    public static final String ACH_PRIZE_32000 = "ACH_PRIZE_32000";
    public static final String ACH_PRIZE_1000000 = "ACH_PRIZE_1000000";
    public static final String ACH_USE_ALL_HELPS = "ACH_USE_ALL_HELPS";
    public static final String ACH_COINS_5000 = "ACH_COINS_5000";
    public static final String ACH_LEVEL_5 = "ACH_LEVEL_5";

    public static final String ACH_FIRST_ONLINE = "ACH_FIRST_ONLINE";
    public static final String ACH_BUY_POWERUP = "ACH_BUY_POWERUP";

    public static final String ACH_LEVEL_10 = "ACH_LEVEL_10";
    public static final String ACH_LEVEL_20 = "ACH_LEVEL_20";
    public static final String ACH_LEVEL_30 = "ACH_LEVEL_30";
    public static final String ACH_LEVEL_50 = "ACH_LEVEL_50";

    public static final String ACH_WIN_5 = "ACH_WIN_5";
    public static final String ACH_WIN_10 = "ACH_WIN_10";
    public static final String ACH_WIN_25 = "ACH_WIN_25";
    public static final String ACH_WIN_50 = "ACH_WIN_50";
    public static final String ACH_WIN_100 = "ACH_WIN_100";

    public static final String ACH_CORRECT_50 = "ACH_CORRECT_50";
    public static final String ACH_CORRECT_100 = "ACH_CORRECT_100";
    public static final String ACH_CORRECT_500 = "ACH_CORRECT_500";
    public static final String ACH_CORRECT_1000 = "ACH_CORRECT_1000";
    public static final String ACH_CORRECT_5000 = "ACH_CORRECT_5000";

    public static final String ACH_PRIZE_500000 = "ACH_PRIZE_500000";

    public static final String ACH_STREAK_3 = "ACH_STREAK_3";
    public static final String ACH_STREAK_15 = "ACH_STREAK_15";

    public static final String ACH_GAMES_10 = "ACH_GAMES_10";
    public static final String ACH_GAMES_25 = "ACH_GAMES_25";
    public static final String ACH_GAMES_50 = "ACH_GAMES_50";
    public static final String ACH_GAMES_100 = "ACH_GAMES_100";

    public static final String ACH_COINS_1000 = "ACH_COINS_1000";
    public static final String ACH_COINS_10000 = "ACH_COINS_10000";
    public static final String ACH_GEMS_50 = "ACH_GEMS_50";
    public static final String ACH_GEMS_500 = "ACH_GEMS_500";

    public static final String ACH_USE_5050 = "ACH_USE_5050";
    public static final String ACH_USE_AUDIENCE = "ACH_USE_AUDIENCE";
    public static final String ACH_USE_CALL = "ACH_USE_CALL";

    public static final String ACH_PERFECT_GAME = "ACH_PERFECT_GAME";
    public static final String ACH_ONLINE_WIN_5 = "ACH_ONLINE_WIN_5";
    public static final String ACH_ONLINE_WIN_10 = "ACH_ONLINE_WIN_10";
    public static final String ACH_BLITZ_FINISH_5 = "ACH_BLITZ_FINISH_5";
    public static final String ACH_ELIMINATION_WIN_3 = "ACH_ELIMINATION_WIN_3";
    public static final String ACH_SURVIVAL_WIN_3 = "ACH_SURVIVAL_WIN_3";
    public static final String ACH_SERIES_WIN_3 = "ACH_SERIES_WIN_3";
    public static final String ACH_TEAM_BATTLE_WIN_5 = "ACH_TEAM_BATTLE_WIN_5";
    public static final String ACH_ALL_DONE = "ACH_ALL_DONE";

    private static final String[] ALL_ACHIEVEMENTS = {
        ACH_FIRST_GAME, ACH_FIRST_WIN, ACH_FIRST_ONLINE, ACH_BUY_POWERUP,
        ACH_LEVEL_5, ACH_LEVEL_10, ACH_LEVEL_20, ACH_LEVEL_30, ACH_LEVEL_50,
        ACH_WIN_5, ACH_WIN_10, ACH_WIN_25, ACH_WIN_50, ACH_WIN_100,
        ACH_CORRECT_50, ACH_CORRECT_100, ACH_CORRECT_500, ACH_CORRECT_1000, ACH_CORRECT_5000,
        ACH_PRIZE_1000, ACH_PRIZE_32000, ACH_PRIZE_500000, ACH_PRIZE_1000000,
        ACH_STREAK_3, ACH_STREAK_5, ACH_STREAK_10, ACH_STREAK_15,
        ACH_GAMES_10, ACH_GAMES_25, ACH_GAMES_50, ACH_GAMES_100,
        ACH_COINS_1000, ACH_COINS_5000, ACH_COINS_10000, ACH_GEMS_50, ACH_GEMS_500,
        ACH_USE_5050, ACH_USE_AUDIENCE, ACH_USE_CALL, ACH_USE_ALL_HELPS,
        ACH_PERFECT_GAME, ACH_ONLINE_WIN_5, ACH_ONLINE_WIN_10,
        ACH_BLITZ_FINISH_5, ACH_ELIMINATION_WIN_3, ACH_SURVIVAL_WIN_3,
        ACH_SERIES_WIN_3, ACH_TEAM_BATTLE_WIN_5,
    };

    private static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences(PREF, Context.MODE_PRIVATE);
    }

    public static int getXp(Context c) { return prefs(c).getInt("xp", 0); }
    public static int getCoins(Context c) { return prefs(c).getInt("coins", 0); }
    public static int getGems(Context c) { return prefs(c).getInt("gems", 0); }
    public static int getDailyClaimCount(Context c) { return prefs(c).getInt("dailyCount", 0); }
    public static int getInventory5050(Context c) { return prefs(c).getInt("inv5050", 0); }
    public static int getInventoryAudience(Context c) { return prefs(c).getInt("invAudience", 0); }
    public static int getInventoryCall(Context c) { return prefs(c).getInt("invCall", 0); }
    public static int getOnlineWins(Context c) { return prefs(c).getInt("onlineWins", 0); }
    public static int getBlitzFinishes(Context c) { return prefs(c).getInt("blitzFinishes", 0); }
    public static int getEliminationWins(Context c) { return prefs(c).getInt("eliminationWins", 0); }
    public static int getSurvivalWins(Context c) { return prefs(c).getInt("survivalWins", 0); }
    public static int getSeriesWins(Context c) { return prefs(c).getInt("seriesWins", 0); }
    public static int getTeamBattleWins(Context c) { return prefs(c).getInt("teamBattleWins", 0); }

    public static void addXp(Context c, int amount) {
        if (amount <= 0) return;
        SharedPreferences p = prefs(c);
        int newXp = p.getInt("xp", 0) + amount;
        p.edit().putInt("xp", newXp).apply();
        int lv = getLevel(c);
        if (lv >= 5) unlockAchievement(c, ACH_LEVEL_5);
        if (lv >= 10) unlockAchievement(c, ACH_LEVEL_10);
        if (lv >= 20) unlockAchievement(c, ACH_LEVEL_20);
        if (lv >= 30) unlockAchievement(c, ACH_LEVEL_30);
        if (lv >= 50) unlockAchievement(c, ACH_LEVEL_50);
    }

    public static void addCoins(Context c, int amount) {
        if (amount == 0) return;
        SharedPreferences p = prefs(c);
        int newCoins = Math.max(0, p.getInt("coins", 0) + amount);
        p.edit().putInt("coins", newCoins).apply();
        if (newCoins >= 1000) unlockAchievement(c, ACH_COINS_1000);
        if (newCoins >= 5000) unlockAchievement(c, ACH_COINS_5000);
        if (newCoins >= 10000) unlockAchievement(c, ACH_COINS_10000);
    }

    public static boolean spendCoins(Context c, int amount) {
        if (getCoins(c) < amount) return false;
        addCoins(c, -amount);
        return true;
    }

    public static void addGems(Context c, int amount) {
        if (amount == 0) return;
        SharedPreferences p = prefs(c);
        int newGems = Math.max(0, p.getInt("gems", 0) + amount);
        p.edit().putInt("gems", newGems).apply();
        if (newGems >= 50) unlockAchievement(c, ACH_GEMS_50);
        if (newGems >= 500) unlockAchievement(c, ACH_GEMS_500);
    }

    public static boolean spendGems(Context c, int amount) {
        if (getGems(c) < amount) return false;
        addGems(c, -amount);
        return true;
    }

    public static int getLevel(Context c) {
        int xp = getXp(c);
        int lv = 1;
        while (xp >= lv * 100) {
            xp -= lv * 100;
            lv++;
        }
        return lv;
    }

    public static int getXpIntoLevel(Context c) {
        int xp = getXp(c);
        int lv = 1;
        while (xp >= lv * 100) {
            xp -= lv * 100;
            lv++;
        }
        return xp;
    }

    public static int getXpNeededForNextLevel(Context c) {
        return getLevel(c) * 100;
    }

    public static String getRankTitle(int level) {
        if (level >= 60) return "Legend";
        if (level >= 45) return "Master";
        if (level >= 30) return "Diamond";
        if (level >= 20) return "Gold";
        if (level >= 10) return "Silver";
        if (level >= 5) return "Bronze";
        return "Rookie";
    }

    public static void addInventory(Context c, String type, int amount) {
        SharedPreferences p = prefs(c);
        String key = inventoryKey(type);
        int next = Math.max(0, p.getInt(key, 0) + amount);
        p.edit().putInt(key, next).apply();
        if (amount > 0) unlockAchievement(c, ACH_BUY_POWERUP);
    }

    public static boolean consumeInventory(Context c, String type) {
        String key = inventoryKey(type);
        SharedPreferences p = prefs(c);
        int current = p.getInt(key, 0);
        if (current <= 0) return false;
        p.edit().putInt(key, current - 1).apply();
        if ("5050".equals(type)) unlockAchievement(c, ACH_USE_5050);
        if ("audience".equals(type)) unlockAchievement(c, ACH_USE_AUDIENCE);
        if ("call".equals(type)) unlockAchievement(c, ACH_USE_CALL);
        return true;
    }

    private static String inventoryKey(String type) {
        if ("5050".equals(type)) return "inv5050";
        if ("audience".equals(type)) return "invAudience";
        return "invCall";
    }

    public static boolean isAchievementUnlocked(Context c, String key) {
        return prefs(c).getBoolean(key, false);
    }

    public static void unlockAchievement(Context c, String key) {
        SharedPreferences p = prefs(c);
        if (!p.getBoolean(key, false)) {
            p.edit().putBoolean(key, true).apply();
            addCoins(c, 250);
            addXp(c, 80);
        }
    }

    public static void checkAllDone(Context c) {
        for (String key : ALL_ACHIEVEMENTS) {
            if (!isAchievementUnlocked(c, key)) return;
        }
        unlockAchievement(c, ACH_ALL_DONE);
    }

    public static void onGameFinished(
            Context c,
            boolean won,
            int prizeMoney,
            int bestStreak,
            boolean usedAllHelps
    ) {
        unlockAchievement(c, ACH_FIRST_GAME);
        if (won) unlockAchievement(c, ACH_FIRST_WIN);

        if (bestStreak >= 3) unlockAchievement(c, ACH_STREAK_3);
        if (bestStreak >= 5) unlockAchievement(c, ACH_STREAK_5);
        if (bestStreak >= 10) unlockAchievement(c, ACH_STREAK_10);
        if (bestStreak >= 15) unlockAchievement(c, ACH_STREAK_15);

        if (prizeMoney >= 1000) unlockAchievement(c, ACH_PRIZE_1000);
        if (prizeMoney >= 32000) unlockAchievement(c, ACH_PRIZE_32000);
        if (prizeMoney >= 500000) unlockAchievement(c, ACH_PRIZE_500000);
        if (prizeMoney >= 1000000) unlockAchievement(c, ACH_PRIZE_1000000);

        if (usedAllHelps) unlockAchievement(c, ACH_USE_ALL_HELPS);
        if (won && !usedAllHelps) unlockAchievement(c, ACH_PERFECT_GAME);

        int games = PlayerStats.getGamesPlayed(c);
        if (games >= 10) unlockAchievement(c, ACH_GAMES_10);
        if (games >= 25) unlockAchievement(c, ACH_GAMES_25);
        if (games >= 50) unlockAchievement(c, ACH_GAMES_50);
        if (games >= 100) unlockAchievement(c, ACH_GAMES_100);

        int wins = PlayerStats.getWins(c);
        if (wins >= 5) unlockAchievement(c, ACH_WIN_5);
        if (wins >= 10) unlockAchievement(c, ACH_WIN_10);
        if (wins >= 25) unlockAchievement(c, ACH_WIN_25);
        if (wins >= 50) unlockAchievement(c, ACH_WIN_50);
        if (wins >= 100) unlockAchievement(c, ACH_WIN_100);

        grantCompletedMatchBonus(c, null);
        addCoins(c, Math.max(50, prizeMoney / 40));
        addXp(c, won ? XP_OFFLINE_WIN : XP_OFFLINE_LOSS);
    }

    public static void onOnlineMatchFinished(Context c, boolean won, int roundsWon) {
        onOnlineMatchFinished(c, won, roundsWon, "battle", false, null);
    }

    public static void onOnlineMatchFinished(
            Context c,
            boolean won,
            int roundsWon,
            String matchMode,
            boolean completedToEnd,
            String completionKey
    ) {
        unlockAchievement(c, ACH_FIRST_GAME);
        unlockAchievement(c, ACH_FIRST_ONLINE);
        if (won) unlockAchievement(c, ACH_FIRST_WIN);

        int xp = won ? XP_ONLINE_WIN : XP_ONLINE_LOSS;
        xp += Math.max(0, roundsWon) * XP_ONLINE_ROUND_WON;
        addXp(c, xp);

        if (completedToEnd) {
            grantCompletedMatchBonus(c, completionKey);
        }

        if (won) {
            int onlineWins = incrementCounter(c, "onlineWins", 1);
            if (onlineWins >= 5) unlockAchievement(c, ACH_ONLINE_WIN_5);
            if (onlineWins >= 10) unlockAchievement(c, ACH_ONLINE_WIN_10);
        }

        final String normalizedMode = normalizeMode(matchMode);
        if (completedToEnd && "blitz".equals(normalizedMode)) {
            int blitzFinishes = incrementCounter(c, "blitzFinishes", 1);
            if (blitzFinishes >= 5) unlockAchievement(c, ACH_BLITZ_FINISH_5);
        }

        if (!won) {
            return;
        }

        if ("elimination".equals(normalizedMode)) {
            int total = incrementCounter(c, "eliminationWins", 1);
            if (total >= 3) unlockAchievement(c, ACH_ELIMINATION_WIN_3);
            return;
        }
        if ("survival".equals(normalizedMode)) {
            int total = incrementCounter(c, "survivalWins", 1);
            if (total >= 3) unlockAchievement(c, ACH_SURVIVAL_WIN_3);
            return;
        }
        if ("series".equals(normalizedMode)) {
            int total = incrementCounter(c, "seriesWins", 1);
            if (total >= 3) unlockAchievement(c, ACH_SERIES_WIN_3);
            return;
        }
        if ("team_battle".equals(normalizedMode)) {
            int total = incrementCounter(c, "teamBattleWins", 1);
            if (total >= 5) unlockAchievement(c, ACH_TEAM_BATTLE_WIN_5);
        }
    }

    private static int incrementCounter(Context c, String key, int amount) {
        SharedPreferences p = prefs(c);
        int next = p.getInt(key, 0) + amount;
        p.edit().putInt(key, next).apply();
        return next;
    }

    private static void grantCompletedMatchBonus(Context c, String completionKey) {
        if (completionKey != null && !completionKey.trim().isEmpty()) {
            String normalizedKey = "bonusMatch:" + completionKey.trim();
            SharedPreferences p = prefs(c);
            if (p.getBoolean(normalizedKey, false)) {
                return;
            }
            p.edit().putBoolean(normalizedKey, true).apply();
        }
        addCoins(c, MATCH_COMPLETION_BONUS);
    }

    private static String normalizeMode(String matchMode) {
        if (matchMode == null) {
            return "";
        }
        return matchMode.trim().toLowerCase(Locale.US);
    }

    public static boolean canClaimDailyReward(Context c) {
        String today = new SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(new Date());
        return !today.equals(prefs(c).getString("lastDailyDate", ""));
    }

    public static DailyReward claimDailyReward(Context c) {
        SharedPreferences p = prefs(c);
        String today = new SimpleDateFormat("yyyyMMdd", Locale.getDefault()).format(new Date());
        String yesterday = p.getString("lastDailyDate", "");
        int streak = p.getInt("dailyCount", 0);
        if (!today.equals(yesterday)) {
            streak += 1;
        }
        int coins = 500 + Math.min(streak, 7) * 50;
        int gems = streak % 3 == 0 ? 2 : 1;
        addCoins(c, coins);
        addGems(c, gems);
        p.edit().putString("lastDailyDate", today).putInt("dailyCount", streak).apply();
        return new DailyReward(coins, gems, streak);
    }

    public static final int XP_ONLINE_WIN = 100;
    public static final int XP_ONLINE_LOSS = 30;
    public static final int XP_ONLINE_ROUND_WON = 15;
    public static final int XP_OFFLINE_WIN = 80;
    public static final int XP_OFFLINE_LOSS = 20;

    public static void resetAll(Context c) {
        prefs(c).edit().clear().apply();
    }

    public static class DailyReward {
        public final int coins;
        public final int gems;
        public final int streak;

        public DailyReward(int coins, int gems, int streak) {
            this.coins = coins;
            this.gems = gems;
            this.streak = streak;
        }
    }
}
