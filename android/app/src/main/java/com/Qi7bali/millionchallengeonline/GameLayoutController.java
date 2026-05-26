package net.androidgaming.millionaire2024;

import android.util.DisplayMetrics;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.core.widget.TextViewCompat;

final class GameLayoutController {
    private final GameActivity activity;

    GameLayoutController(GameActivity activity) {
        this.activity = activity;
    }

    void configureAnswerTextSizing() {
        for (TextView answerView : new TextView[]{
                activity.txtA1,
                activity.txtA2,
                activity.txtA3,
                activity.txtA4
        }) {
            if (answerView == null) {
                continue;
            }
            TextViewCompat.setAutoSizeTextTypeWithDefaults(
                    answerView,
                    TextViewCompat.AUTO_SIZE_TEXT_TYPE_NONE
            );
            answerView.setHorizontallyScrolling(false);
            answerView.setSingleLine(false);
            answerView.setMaxLines(1);
            answerView.setIncludeFontPadding(false);
        }
    }

    void configureGameSurfaceLayout() {
        final DisplayMetrics metrics = activity.getResources().getDisplayMetrics();
        final float screenWidthDp = metrics.widthPixels / metrics.density;
        final float screenHeightDp = metrics.heightPixels / metrics.density;
        final boolean shortScreen = screenHeightDp < 390f;
        final boolean narrowScreen = screenWidthDp < 760f;

        if (activity.llyQA != null) {
            int targetWidthDp = activity.modeOnline
                    ? Math.round(screenWidthDp * (shortScreen ? 0.46f : 0.48f))
                    : Math.round(screenWidthDp * (shortScreen ? 0.50f : 0.54f));
            targetWidthDp = Math.max(shortScreen ? 360 : 390, Math.min(450, targetWidthDp));
            ViewGroup.LayoutParams params = activity.llyQA.getLayoutParams();
            params.width = activity.dp(targetWidthDp);
            activity.llyQA.setLayoutParams(params);
        }

        if (activity.txtQ != null) {
            activity.txtQ.setSingleLine(false);
            activity.txtQ.setMaxLines(2);
            activity.txtQ.setIncludeFontPadding(false);
            TextViewCompat.setAutoSizeTextTypeUniformWithConfiguration(
                    activity.txtQ,
                    10,
                    shortScreen ? 16 : 18,
                    1,
                    TypedValue.COMPLEX_UNIT_SP
            );
        }

        final int toolSizeDp = shortScreen || narrowScreen ? 42 : 50;
        resizeSquareView(activity.imgHelp5050, toolSizeDp);
        resizeSquareView(activity.imgHelpCall, toolSizeDp);
        resizeSquareView(activity.imgHelpAudience, toolSizeDp);
        resizeSquareView(activity.imgVolume, toolSizeDp);
        resizeSquareView(activity.imgHome, toolSizeDp);
        resizeSquareView(activity.rlyProgress, shortScreen ? 44 : 50);

        if (activity.txtProgress != null) {
            activity.txtProgress.setTextSize(TypedValue.COMPLEX_UNIT_SP, shortScreen ? 17 : 20);
            activity.txtProgress.setIncludeFontPadding(false);
        }
    }

    private void resizeSquareView(View view, int sizeDp) {
        if (view == null) {
            return;
        }
        ViewGroup.LayoutParams params = view.getLayoutParams();
        params.width = activity.dp(sizeDp);
        params.height = activity.dp(sizeDp);
        view.setLayoutParams(params);
    }
}
