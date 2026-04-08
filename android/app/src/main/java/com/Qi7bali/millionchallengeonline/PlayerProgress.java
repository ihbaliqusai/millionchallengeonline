package com.Qi7bali.millionchallengeonline;

import android.content.Context;
import android.content.SharedPreferences;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class PlayerProgress {
    private static final String PREF = "PlayerProgress";

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

    public static void addXp(Context c, int amount) {
        if (amount <= 0) return;
        SharedPreferences p = prefs(c);
        int newXp = p.getInt("xp", 0) + amount;
        p.edit().putInt("xp", newXp).apply();
        if (getLevel(c) >= 5) unlockAchievement(c, ACH_LEVEL_5);
    }

    public static void addCoins(Context c, int amount) {
        if (amount == 0) return;
        SharedPreferences p = prefs(c);
        int newCoins = Math.max(0, p.getInt("coins", 0) + amount);
        p.edit().putInt("coins", newCoins).apply();
        if (newCoins >= 5000) unlockAchievement(c, ACH_COINS_5000);
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
    }

    public static boolean spendGems(Context c, int amount) {
        if (getGems(c) < amount) return false;
        addGems(c, -amount);
        return true;
    }

    public static int getLevel(Context c) {
        int xp = getXp(c);
        return Math.max(1, (xp / 300) + 1);
    }

    public static int getXpIntoLevel(Context c) {
        return getXp(c) % 300;
    }

    public static int getXpNeededForNextLevel(Context c) {
        return 300;
    }

    public static void addInventory(Context c, String type, int amount) {
        SharedPreferences p = prefs(c);
        String key = inventoryKey(type);
        int next = Math.max(0, p.getInt(key, 0) + amount);
        p.edit().putInt(key, next).apply();
    }

    public static boolean consumeInventory(Context c, String type) {
        String key = inventoryKey(type);
        SharedPreferences p = prefs(c);
        int current = p.getInt(key, 0);
        if (current <= 0) return false;
        p.edit().putInt(key, current - 1).apply();
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

    public static void onGameFinished(Context c, boolean won, int prizeMoney, int bestStreak, boolean usedAllHelps) {
        unlockAchievement(c, ACH_FIRST_GAME);
        if (won) unlockAchievement(c, ACH_FIRST_WIN);
        if (bestStreak >= 5) unlockAchievement(c, ACH_STREAK_5);
        if (bestStreak >= 10) unlockAchievement(c, ACH_STREAK_10);
        if (prizeMoney >= 1000) unlockAchievement(c, ACH_PRIZE_1000);
        if (prizeMoney >= 32000) unlockAchievement(c, ACH_PRIZE_32000);
        if (prizeMoney >= 1000000) unlockAchievement(c, ACH_PRIZE_1000000);
        if (usedAllHelps) unlockAchievement(c, ACH_USE_ALL_HELPS);
        addCoins(c, Math.max(50, prizeMoney / 40));
        addXp(c, won ? 180 : 90);
    }

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
