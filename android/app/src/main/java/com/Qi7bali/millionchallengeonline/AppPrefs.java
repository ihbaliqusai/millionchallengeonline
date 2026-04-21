package net.androidgaming.millionaire2024;

import android.content.Context;
import android.content.SharedPreferences;

public final class AppPrefs {
    public static final String PREF_USER = "UserInfo";
    public static final String PREF_SETTINGS = "AppSettings";
    public static final String PREF_ROOM = "RoomBridge";
    private static final String KEY_PENDING_ROOM_MATCH_RESULT = "pendingRoomMatchResult";

    private AppPrefs() {}

    private static SharedPreferences userPrefs(Context c) {
        return c.getSharedPreferences(PREF_USER, Context.MODE_PRIVATE);
    }

    private static SharedPreferences settingsPrefs(Context c) {
        return c.getSharedPreferences(PREF_SETTINGS, Context.MODE_PRIVATE);
    }

    private static SharedPreferences roomPrefs(Context c) {
        return c.getSharedPreferences(PREF_ROOM, Context.MODE_PRIVATE);
    }

    public static void ensureGuestUser(Context c) {
        SharedPreferences p = userPrefs(c);
        if (p.getString("userID", "").isEmpty()) {
            setUser(c, "guest_local", "ضيف", "", 1, 0);
        }
    }

    public static void setUser(Context c, String id, String name, String photo, int level, int score) {
        userPrefs(c).edit()
                .putString("userID", id)
                .putString("userName", name)
                .putString("userPhoto", photo)
                .putInt("userLevel", level)
                .putInt("userScore", score)
                .apply();
    }

    public static void setGuestUser(Context c) {
        setUser(c, "guest_local", "ضيف", "", 1, 0);
    }

    public static String getUserId(Context c) { return userPrefs(c).getString("userID", ""); }
    public static String getUserName(Context c) { return userPrefs(c).getString("userName", "ضيف"); }
    public static String getUserPhoto(Context c) { return userPrefs(c).getString("userPhoto", ""); }
    public static int getUserLevel(Context c) { return userPrefs(c).getInt("userLevel", 1); }
    public static int getUserScore(Context c) { return userPrefs(c).getInt("userScore", 0); }

    public static void setSoundEnabled(Context c, boolean enabled) {
        settingsPrefs(c).edit().putBoolean("soundEnabled", enabled).apply();
    }

    public static boolean isSoundEnabled(Context c) {
        return settingsPrefs(c).getBoolean("soundEnabled", true);
    }

    public static void setMusicEnabled(Context c, boolean enabled) {
        settingsPrefs(c).edit().putBoolean("musicEnabled", enabled).apply();
    }

    public static boolean isMusicEnabled(Context c) {
        return settingsPrefs(c).getBoolean("musicEnabled", true);
    }

    public static void setHapticEnabled(Context c, boolean enabled) {
        settingsPrefs(c).edit().putBoolean("hapticEnabled", enabled).apply();
    }

    public static boolean isHapticEnabled(Context c) {
        return settingsPrefs(c).getBoolean("hapticEnabled", true);
    }

    public static void setDialogsEnabled(Context c, boolean enabled) {
        settingsPrefs(c).edit().putBoolean("dialogsEnabled", enabled).apply();
    }

    public static boolean isDialogsEnabled(Context c) {
        return settingsPrefs(c).getBoolean("dialogsEnabled", true);
    }

    public static int getCoins(Context c) { return PlayerProgress.getCoins(c); }
    public static int getGems(Context c) { return PlayerProgress.getGems(c); }
    public static int getXp(Context c) { return PlayerProgress.getXp(c); }
    public static int getLevel(Context c) { return PlayerProgress.getLevel(c); }
    public static int getInventory5050(Context c) { return PlayerProgress.getInventory5050(c); }
    public static int getInventoryAudience(Context c) { return PlayerProgress.getInventoryAudience(c); }
    public static int getInventoryCall(Context c) { return PlayerProgress.getInventoryCall(c); }

    public static void setPendingRoomMatchResult(Context c, String payload) {
        roomPrefs(c).edit().putString(KEY_PENDING_ROOM_MATCH_RESULT, payload).apply();
    }

    public static String consumePendingRoomMatchResult(Context c) {
        SharedPreferences prefs = roomPrefs(c);
        String payload = prefs.getString(KEY_PENDING_ROOM_MATCH_RESULT, "");
        prefs.edit().remove(KEY_PENDING_ROOM_MATCH_RESULT).apply();
        return payload == null ? "" : payload;
    }

    public static void resetLocalProgress(Context c) {
        PlayerStats.reset(c);
        PlayerProgress.resetAll(c);
        setGuestUser(c);
    }
}
