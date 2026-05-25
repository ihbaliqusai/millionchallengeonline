package net.androidgaming.millionaire2024;

import android.app.Activity;
import android.view.View;
import android.widget.TextView;

final class InventoryBadgeUpdater {
    private InventoryBadgeUpdater() {
    }

    static void update(Activity activity) {
        updateBadge(activity, R.id.badge5050, PlayerProgress.getInventory5050(activity));
        updateBadge(activity, R.id.badgeCall, PlayerProgress.getInventoryCall(activity));
        updateBadge(activity, R.id.badgeAudience, PlayerProgress.getInventoryAudience(activity));
    }

    private static void updateBadge(Activity activity, int badgeId, int count) {
        TextView badge = activity.findViewById(badgeId);
        if (badge == null) return;
        if (count > 0) {
            badge.setText(String.valueOf(count));
            badge.setVisibility(View.VISIBLE);
        } else {
            badge.setVisibility(View.GONE);
        }
    }
}
