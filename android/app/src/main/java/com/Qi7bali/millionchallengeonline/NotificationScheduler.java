package net.androidgaming.millionaire2024;

import android.app.AlarmManager;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;

import java.util.Calendar;

public final class NotificationScheduler {
    private static final int DAILY_REMINDER_REQUEST = 7401;

    private NotificationScheduler() {}

    public static void scheduleDailyReminder(Context context) {
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager == null) {
            return;
        }

        Calendar trigger = Calendar.getInstance();
        trigger.set(Calendar.HOUR_OF_DAY, 20);
        trigger.set(Calendar.MINUTE, 0);
        trigger.set(Calendar.SECOND, 0);
        trigger.set(Calendar.MILLISECOND, 0);
        if (trigger.getTimeInMillis() <= System.currentTimeMillis()) {
            trigger.add(Calendar.DAY_OF_YEAR, 1);
        }

        alarmManager.setInexactRepeating(
                AlarmManager.RTC_WAKEUP,
                trigger.getTimeInMillis(),
                AlarmManager.INTERVAL_DAY,
                reminderIntent(context)
        );
    }

    public static void cancelDailyReminder(Context context) {
        AlarmManager alarmManager = (AlarmManager) context.getSystemService(Context.ALARM_SERVICE);
        if (alarmManager != null) {
            alarmManager.cancel(reminderIntent(context));
        }
    }

    private static PendingIntent reminderIntent(Context context) {
        Intent intent = new Intent(context, DailyReminderReceiver.class);
        intent.setAction("net.androidgaming.millionaire2024.DAILY_REWARD_REMINDER");
        return PendingIntent.getBroadcast(
                context,
                DAILY_REMINDER_REQUEST,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );
    }
}
