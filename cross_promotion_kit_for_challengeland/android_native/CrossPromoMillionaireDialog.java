package com.qi7bali.landchallengeonline;

import android.app.Dialog;
import android.content.Context;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.net.Uri;
import android.os.Bundle;
import android.view.Window;
import android.view.WindowManager;
import android.widget.Button;
import android.widget.ImageButton;

public class CrossPromoMillionaireDialog extends Dialog {

    public static final String MILLIONAIRE_PACKAGE = "net.androidgaming.millionaire2024";
    public static final String PLAY_STORE_URL = "https://play.google.com/store/apps/details?id=net.androidgaming.millionaire2024";

    public CrossPromoMillionaireDialog(Context context) {
        super(context);
    }

    public static void show(Context context) {
        CrossPromoMillionaireDialog dialog = new CrossPromoMillionaireDialog(context);
        dialog.show();
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        requestWindowFeature(Window.FEATURE_NO_TITLE);
        setContentView(R.layout.dialog_cross_promo_millionaire);

        if (getWindow() != null) {
            getWindow().setBackgroundDrawable(new ColorDrawable(Color.TRANSPARENT));
            getWindow().setLayout(
                WindowManager.LayoutParams.WRAP_CONTENT,
                WindowManager.LayoutParams.WRAP_CONTENT
            );
        }

        final boolean isInstalled = isAppInstalled(getContext(), MILLIONAIRE_PACKAGE);
        Button btnAction = findViewById(R.id.btn_promo_action);
        ImageButton btnClose = findViewById(R.id.btn_close_promo);

        if (btnAction != null) {
            if (isInstalled) {
                btnAction.setText("فتح اللعبة واللعب الآن 🎮");
            } else {
                btnAction.setText("تثبيت مجاناً من Google Play 🚀");
            }

            btnAction.setOnClickListener(v -> {
                launchMillionaireOrStore(getContext());
                dismiss();
            });
        }

        if (btnClose != null) {
            btnClose.setOnClickListener(v -> dismiss());
        }
    }

    public static boolean isAppInstalled(Context context, String packageName) {
        try {
            context.getPackageManager().getPackageInfo(packageName, 0);
            return true;
        } catch (Exception e) {
            return false;
        }
    }

    public static void launchMillionaireOrStore(Context context) {
        boolean launched = false;
        try {
            Intent launchIntent = context.getPackageManager().getLaunchIntentForPackage(MILLIONAIRE_PACKAGE);
            if (launchIntent != null) {
                launchIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(launchIntent);
                launched = true;
            }
        } catch (Exception ignored) {}

        if (!launched) {
            try {
                Intent marketIntent = new Intent(Intent.ACTION_VIEW, Uri.parse("market://details?id=" + MILLIONAIRE_PACKAGE));
                marketIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(marketIntent);
            } catch (Exception e) {
                try {
                    Intent webIntent = new Intent(Intent.ACTION_VIEW, Uri.parse(PLAY_STORE_URL));
                    webIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                    context.startActivity(webIntent);
                } catch (Exception ignored) {}
            }
        }
    }
}
