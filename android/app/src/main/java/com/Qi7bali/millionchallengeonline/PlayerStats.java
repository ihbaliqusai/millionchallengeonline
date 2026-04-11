package com.Qi7bali.millionchallengeonline;

import android.content.Context;
import android.content.SharedPreferences;

public class PlayerStats {
    private static final String PREF = "PlayerStats";

    public static int getGamesPlayed(Context c) { return prefs(c).getInt("gamesPlayed", 0); }
    public static int getWins(Context c) { return prefs(c).getInt("wins", 0); }
    public static int getLosses(Context c) { return prefs(c).getInt("losses", 0); }
    public static int getHighestMoney(Context c) { return prefs(c).getInt("highestMoney", 0); }
    public static int getLastPrize(Context c) { return prefs(c).getInt("lastPrize", 0); }
    public static int getCorrectAnswers(Context c) { return prefs(c).getInt("correctAnswers", 0); }
    public static int getWrongAnswers(Context c) { return prefs(c).getInt("wrongAnswers", 0); }
    public static int getTotalAnswered(Context c) { return getCorrectAnswers(c) + getWrongAnswers(c); }
    public static int getBestStreak(Context c) { return prefs(c).getInt("bestStreak", 0); }
    public static int getCurrentStreak(Context c) { return prefs(c).getInt("currentStreak", 0); }

    private static SharedPreferences prefs(Context c) {
        return c.getSharedPreferences(PREF, Context.MODE_PRIVATE);
    }

    public static void recordCorrectAnswer(Context c) {
        SharedPreferences p = prefs(c);
        int current = p.getInt("currentStreak", 0) + 1;
        int best = Math.max(current, p.getInt("bestStreak", 0));
        p.edit()
                .putInt("correctAnswers", p.getInt("correctAnswers", 0) + 1)
                .putInt("currentStreak", current)
                .putInt("bestStreak", best)
                .apply();
        PlayerProgress.addXp(c, 10);
        PlayerProgress.addCoins(c, 20);
        if (best >= 5) PlayerProgress.unlockAchievement(c, PlayerProgress.ACH_STREAK_5);
        if (best >= 10) PlayerProgress.unlockAchievement(c, PlayerProgress.ACH_STREAK_10);
    }

    public static void recordWrongAnswer(Context c) {
        SharedPreferences p = prefs(c);
        p.edit()
                .putInt("wrongAnswers", p.getInt("wrongAnswers", 0) + 1)
                .putInt("currentStreak", 0)
                .apply();
        PlayerProgress.addXp(c, 3);
    }

    public static void recordGameEnd(Context c, boolean won, int prizeMoney) {
        SharedPreferences p = prefs(c);
        int highest = Math.max(prizeMoney, p.getInt("highestMoney", 0));
        SharedPreferences.Editor e = p.edit()
                .putInt("gamesPlayed", p.getInt("gamesPlayed", 0) + 1)
                .putInt("lastPrize", prizeMoney)
                .putInt("highestMoney", highest)
                .putInt("currentStreak", 0);
        if (won) {
            e.putInt("wins", p.getInt("wins", 0) + 1);
        } else {
            e.putInt("losses", p.getInt("losses", 0) + 1);
        }
        e.apply();
    }

    public static void reset(Context c) {
        prefs(c).edit().clear().apply();
    }
}
