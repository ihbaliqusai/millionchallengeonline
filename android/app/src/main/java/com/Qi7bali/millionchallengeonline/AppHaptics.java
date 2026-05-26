package net.androidgaming.millionaire2024;

import android.content.Context;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;

public final class AppHaptics {
    private AppHaptics() {}

    public static boolean light(Context context) {
        return vibrate(context, "light");
    }

    public static boolean medium(Context context) {
        return vibrate(context, "medium");
    }

    public static boolean heavy(Context context) {
        return vibrate(context, "heavy");
    }

    public static boolean play(Context context, String style) {
        if ("heavy".equals(style)) {
            return heavy(context);
        }
        if ("medium".equals(style)) {
            return medium(context);
        }
        return light(context);
    }

    public static boolean hasVibrator(Context context) {
        if (context == null) return false;
        Vibrator vibrator = getVibrator(context);
        return vibrator != null && vibrator.hasVibrator();
    }

    private static boolean vibrate(Context context, String style) {
        if (context == null) return false;
        Vibrator vibrator = getVibrator(context);
        if (vibrator == null || !vibrator.hasVibrator()) return false;
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                vibrator.vibrate(effectFor(style));
            } else {
                vibrator.vibrate(patternFor(style), -1);
            }
            return true;
        } catch (Exception ignored) {
            return false;
        }
    }

    private static Vibrator getVibrator(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            VibratorManager manager =
                    (VibratorManager) context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE);
            return manager == null ? null : manager.getDefaultVibrator();
        }
        return (Vibrator) context.getSystemService(Context.VIBRATOR_SERVICE);
    }

    private static VibrationEffect effectFor(String style) {
        return VibrationEffect.createWaveform(
                patternFor(style),
                amplitudesFor(style),
                -1
        );
    }

    private static long[] patternFor(String style) {
        if ("heavy".equals(style)) {
            return new long[]{0, 90, 35, 90};
        }
        if ("medium".equals(style)) {
            return new long[]{0, 70};
        }
        return new long[]{0, 45};
    }

    private static int[] amplitudesFor(String style) {
        if ("heavy".equals(style)) {
            return new int[]{0, 255, 0, 255};
        }
        if ("medium".equals(style)) {
            return new int[]{0, 255};
        }
        return new int[]{0, 220};
    }
}
