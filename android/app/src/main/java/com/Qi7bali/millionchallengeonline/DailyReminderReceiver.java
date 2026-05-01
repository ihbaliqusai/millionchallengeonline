package net.androidgaming.millionaire2024;

import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.app.PendingIntent;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;

public class DailyReminderReceiver extends BroadcastReceiver {
    private static final String CHANNEL_ID = "daily_rewards";
    private static final int NOTIFICATION_ID = 7401;

    @Override
    public void onReceive(Context context, Intent intent) {
        String action = intent == null ? "" : intent.getAction();
        if (Intent.ACTION_BOOT_COMPLETED.equals(action)) {
            if (AppPrefs.isNotificationsEnabled(context)) {
                NotificationScheduler.scheduleDailyReminder(context);
            }
            return;
        }

        if (!AppPrefs.isNotificationsEnabled(context)) {
            return;
        }

        NotificationManager manager =
                (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
        if (manager == null) {
            return;
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationChannel channel = new NotificationChannel(
                    CHANNEL_ID,
                    "Daily rewards",
                    NotificationManager.IMPORTANCE_DEFAULT
            );
            channel.setDescription("Daily challenge and reward reminders");
            manager.createNotificationChannel(channel);
        }

        Intent launchIntent = new Intent(context, MainActivity.class);
        launchIntent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
        PendingIntent contentIntent = PendingIntent.getActivity(
                context,
                0,
                launchIntent,
                PendingIntent.FLAG_UPDATE_CURRENT | PendingIntent.FLAG_IMMUTABLE
        );

        Notification.Builder builder = Build.VERSION.SDK_INT >= Build.VERSION_CODES.O
                ? new Notification.Builder(context, CHANNEL_ID)
                : new Notification.Builder(context);

        Notification notification = builder
                .setSmallIcon(R.mipmap.ic_launcher)
                .setContentTitle("تحدي المليون")
                .setContentText("مكافأتك اليومية بانتظارك. ادخل وخذها قبل أن تضيع السلسلة.")
                .setContentIntent(contentIntent)
                .setAutoCancel(true)
                .setShowWhen(true)
                .build();

        manager.notify(NOTIFICATION_ID, notification);
        NotificationScheduler.scheduleDailyReminder(context);
    }
}
