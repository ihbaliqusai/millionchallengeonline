package net.androidgaming.millionaire2024;

import android.graphics.Color;
import android.graphics.drawable.GradientDrawable;
import android.graphics.drawable.LayerDrawable;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.TextView;

final class GameCampaignHudController {
    private final GameActivity activity;

    GameCampaignHudController(GameActivity activity) {
        this.activity = activity;
    }

    void configureGameplayHud() {
        if (!activity.campaignMode) {
            return;
        }
        hideMoneyBox();
        createProgressHudIfNeeded();
        showGameplayHud();
        updateProgressHud(false);
    }

    void hideMoneyBox() {
        if (activity.campaignMode && activity.llySolde != null) {
            activity.llySolde.setVisibility(View.GONE);
        }
    }

    void showGameplayHud() {
        if (!activity.campaignMode || activity.campaignHudPanel == null) {
            return;
        }
        activity.campaignHudPanel.setVisibility(View.VISIBLE);
    }

    void updateProgressHud(boolean animateStars) {
        if (!activity.campaignMode || activity.campaignHudPanel == null) {
            return;
        }
        int targetCount = Math.max(1, activity.getCampaignTargetQuestionCount());
        int shownQuestion = activity.currentQuestion >= 0
                ? Math.min(targetCount, activity.currentQuestion + 1)
                : Math.min(targetCount, activity.campaignAnsweredQuestions + 1);
        activity.txtCampaignHudQuestion.setText("السؤال " + shownQuestion + "/" + targetCount);
        activity.txtCampaignHudCorrect.setText("الصحيح " + activity.campaignCorrectAnswers);

        if (activity.campaignBossBattle && activity.campaignBossOpponent != null) {
            activity.txtCampaignHudBattle.setVisibility(View.VISIBLE);
            activity.txtCampaignHudBattle.setText("مواجهة الزعيم\nأنت: " + activity.gameScoreMe + " نقطة   VS   "
                    + activity.campaignBossOpponent.name + ": " + activity.campaignBossOpponent.gameScore + " نقطة");
        } else {
            activity.txtCampaignHudBattle.setVisibility(View.GONE);
        }

        int earnedStars = getEarnedStars();
        for (int i = 0; i < activity.campaignHudStars.size(); i++) {
            TextView star = activity.campaignHudStars.get(i);
            boolean earned = i < earnedStars;
            star.setTextColor(earned ? Color.rgb(255, 216, 74) : Color.argb(135, 255, 255, 255));
            star.setShadowLayer(
                    earned ? activity.dp(5) : activity.dp(3),
                    0,
                    earned ? 0 : activity.dp(1),
                    earned ? Color.argb(210, 255, 197, 45) : Color.argb(150, 0, 0, 0)
            );
            if (animateStars && earned && i >= activity.campaignLastDisplayedStars) {
                animateCampaignStar(star);
            }
        }
        activity.campaignLastDisplayedStars = earnedStars;
        updateProgressBar();
    }

    int getEarnedStars() {
        if (activity.campaignCorrectAnswers >= 9) return 3;
        if (activity.campaignCorrectAnswers >= 7) return 2;
        if (activity.campaignCorrectAnswers >= 5) return 1;
        return 0;
    }

    private void createProgressHudIfNeeded() {
        if (!activity.campaignMode || activity.campaignHudPanel != null) {
            return;
        }
        View root = activity.findViewById(android.R.id.content);
        if (!(root instanceof FrameLayout)) {
            return;
        }

        activity.campaignHudPanel = new LinearLayout(activity);
        activity.campaignHudPanel.setOrientation(LinearLayout.VERTICAL);
        activity.campaignHudPanel.setPadding(activity.dp(14), activity.dp(12), activity.dp(14), activity.dp(12));
        activity.campaignHudPanel.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        activity.campaignHudPanel.setBackground(createPanelBackground());
        activity.campaignHudPanel.setElevation(activity.dp(10));
        activity.campaignHudPanel.setVisibility(View.INVISIBLE);

        FrameLayout.LayoutParams panelParams = new FrameLayout.LayoutParams(
                activity.dp(activity.campaignBossBattle ? 268 : 228),
                FrameLayout.LayoutParams.WRAP_CONTENT
        );
        panelParams.gravity = android.view.Gravity.TOP | android.view.Gravity.START;
        panelParams.setMargins(activity.dp(10), activity.dp(16), activity.dp(10), activity.dp(10));

        activity.txtCampaignHudBattle = createText(14, Color.WHITE, true);
        activity.txtCampaignHudBattle.setGravity(android.view.Gravity.CENTER);
        activity.txtCampaignHudBattle.setVisibility(activity.campaignBossBattle ? View.VISIBLE : View.GONE);
        if (activity.campaignBossBattle) {
            activity.txtCampaignHudBattle.setPadding(activity.dp(8), activity.dp(6), activity.dp(8), activity.dp(6));
            activity.txtCampaignHudBattle.setBackground(createRoundedGradientDrawable(
                    new int[]{Color.argb(140, 255, 216, 74), Color.argb(65, 20, 184, 166)},
                    Color.argb(195, 255, 230, 130),
                    1,
                    12,
                    GradientDrawable.Orientation.LEFT_RIGHT
            ));
        }
        activity.campaignHudPanel.addView(activity.txtCampaignHudBattle, new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        ));

        activity.txtCampaignHudQuestion = createText(14, Color.WHITE, true);
        activity.txtCampaignHudQuestion.setGravity(android.view.Gravity.CENTER);
        activity.txtCampaignHudQuestion.setShadowLayer(activity.dp(3), 0, activity.dp(1), Color.argb(190, 0, 0, 0));
        activity.campaignHudPanel.addView(activity.txtCampaignHudQuestion);

        activity.txtCampaignHudCorrect = createText(13, Color.argb(245, 190, 242, 255), true);
        activity.txtCampaignHudCorrect.setGravity(android.view.Gravity.CENTER);
        activity.txtCampaignHudCorrect.setPadding(0, activity.dp(6), 0, 0);
        activity.txtCampaignHudCorrect.setShadowLayer(activity.dp(3), 0, activity.dp(1), Color.argb(180, 0, 0, 0));
        activity.campaignHudPanel.addView(activity.txtCampaignHudCorrect);

        LinearLayout starsRow = new LinearLayout(activity);
        starsRow.setOrientation(LinearLayout.HORIZONTAL);
        starsRow.setGravity(android.view.Gravity.CENTER);
        starsRow.setLayoutDirection(View.LAYOUT_DIRECTION_RTL);
        LinearLayout.LayoutParams starsParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
        starsParams.setMargins(0, activity.dp(7), 0, activity.dp(7));
        activity.campaignHudPanel.addView(starsRow, starsParams);

        activity.campaignHudStars.clear();
        for (int i = 0; i < 3; i++) {
            TextView star = createText(activity.campaignBossBattle ? 30 : 25, Color.argb(135, 255, 255, 255), true);
            star.setText("★");
            star.setGravity(android.view.Gravity.CENTER);
            star.setShadowLayer(activity.dp(3), 0, activity.dp(1), Color.argb(150, 0, 0, 0));
            int starBox = activity.campaignBossBattle ? 38 : 30;
            LinearLayout.LayoutParams starParams = new LinearLayout.LayoutParams(activity.dp(starBox), activity.dp(starBox));
            starParams.setMargins(activity.dp(activity.campaignBossBattle ? 4 : 3), 0, activity.dp(activity.campaignBossBattle ? 4 : 3), 0);
            starsRow.addView(star, starParams);
            activity.campaignHudStars.add(star);
        }

        activity.campaignHudProgressTrack = new FrameLayout(activity);
        activity.campaignHudProgressTrack.setBackground(createRoundedDrawable(
                Color.argb(95, 255, 255, 255),
                Color.argb(120, 255, 255, 255),
                1,
                6
        ));
        LinearLayout.LayoutParams trackParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                activity.dp(7)
        );
        activity.campaignHudPanel.addView(activity.campaignHudProgressTrack, trackParams);

        activity.campaignHudProgressFill = new View(activity);
        activity.campaignHudProgressFill.setBackground(createRoundedGradientDrawable(
                new int[]{Color.rgb(255, 244, 170), Color.rgb(255, 193, 7)},
                Color.TRANSPARENT,
                0,
                6,
                GradientDrawable.Orientation.LEFT_RIGHT
        ));
        activity.campaignHudProgressTrack.addView(activity.campaignHudProgressFill, new FrameLayout.LayoutParams(0, activity.dp(7)));

        activity.txtCampaignHudBadge = createText(12, Color.argb(255, 255, 235, 160), true);
        activity.txtCampaignHudBadge.setGravity(android.view.Gravity.CENTER);
        activity.txtCampaignHudBadge.setVisibility("noLifeline".equals(activity.campaignStageType) ? View.VISIBLE : View.GONE);
        activity.txtCampaignHudBadge.setText("بدون مساعدات");
        activity.txtCampaignHudBadge.setPadding(activity.dp(8), activity.dp(4), activity.dp(8), activity.dp(4));
        activity.txtCampaignHudBadge.setBackground(createRoundedGradientDrawable(
                new int[]{Color.argb(105, 255, 216, 74), Color.argb(55, 56, 189, 248)},
                Color.argb(165, 255, 216, 74),
                1,
                11,
                GradientDrawable.Orientation.LEFT_RIGHT
        ));
        LinearLayout.LayoutParams badgeParams = new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
        );
        badgeParams.setMargins(0, activity.dp(7), 0, 0);
        activity.campaignHudPanel.addView(activity.txtCampaignHudBadge, badgeParams);

        ((FrameLayout) root).addView(activity.campaignHudPanel, panelParams);
    }

    private TextView createText(int sizeSp, int color, boolean bold) {
        TextView textView = new TextView(activity);
        textView.setTextColor(color);
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp);
        textView.setIncludeFontPadding(false);
        textView.setSingleLine(false);
        textView.setTypeface(null, bold ? android.graphics.Typeface.BOLD : android.graphics.Typeface.NORMAL);
        return textView;
    }

    private LayerDrawable createPanelBackground() {
        GradientDrawable glow = createRoundedGradientDrawable(
                new int[]{Color.argb(72, 56, 189, 248), Color.argb(38, 255, 216, 74)},
                Color.TRANSPARENT,
                0,
                20,
                GradientDrawable.Orientation.TL_BR
        );
        GradientDrawable glass = createRoundedGradientDrawable(
                new int[]{Color.argb(232, 3, 10, 32), Color.argb(218, 9, 25, 58), Color.argb(232, 2, 8, 28)},
                Color.argb(190, 255, 220, 115),
                1,
                18,
                GradientDrawable.Orientation.TOP_BOTTOM
        );
        GradientDrawable innerStroke = createRoundedDrawable(
                Color.TRANSPARENT,
                Color.argb(125, 125, 231, 255),
                1,
                16
        );
        GradientDrawable topSheen = createRoundedGradientDrawable(
                new int[]{Color.argb(155, 255, 255, 255), Color.argb(0, 255, 255, 255)},
                Color.TRANSPARENT,
                0,
                14,
                GradientDrawable.Orientation.LEFT_RIGHT
        );
        LayerDrawable layers = new LayerDrawable(new android.graphics.drawable.Drawable[]{
                glow,
                glass,
                innerStroke,
                topSheen
        });
        layers.setLayerInset(1, activity.dp(1), activity.dp(1), activity.dp(1), activity.dp(1));
        layers.setLayerInset(2, activity.dp(3), activity.dp(3), activity.dp(3), activity.dp(3));
        layers.setLayerInset(3, activity.dp(16), activity.dp(6), activity.dp(16), activity.dp(58));
        return layers;
    }

    private GradientDrawable createRoundedGradientDrawable(
            int[] colors,
            int strokeColor,
            int strokeDp,
            int radiusDp,
            GradientDrawable.Orientation orientation
    ) {
        GradientDrawable drawable = new GradientDrawable(orientation, colors);
        drawable.setCornerRadius(activity.dp(radiusDp));
        if (strokeDp > 0) {
            drawable.setStroke(activity.dp(strokeDp), strokeColor);
        }
        return drawable;
    }

    private GradientDrawable createRoundedDrawable(int fillColor, int strokeColor, int strokeDp, int radiusDp) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(fillColor);
        drawable.setCornerRadius(activity.dp(radiusDp));
        if (strokeDp > 0) {
            drawable.setStroke(activity.dp(strokeDp), strokeColor);
        }
        return drawable;
    }

    private void updateProgressBar() {
        if (activity.campaignHudProgressTrack == null || activity.campaignHudProgressFill == null) {
            return;
        }
        activity.campaignHudProgressTrack.post(new Runnable() {
            @Override
            public void run() {
                int trackWidth = activity.campaignHudProgressTrack.getWidth();
                if (trackWidth <= 0) {
                    return;
                }
                float ratio = Math.max(0f, Math.min(1f, activity.campaignCorrectAnswers / 9f));
                ViewGroup.LayoutParams params = activity.campaignHudProgressFill.getLayoutParams();
                params.width = Math.round(trackWidth * ratio);
                activity.campaignHudProgressFill.setLayoutParams(params);
            }
        });
    }

    private void animateCampaignStar(final TextView star) {
        if (star == null) {
            return;
        }
        star.setScaleX(0.65f);
        star.setScaleY(0.65f);
        star.setAlpha(0.65f);
        star.animate()
                .scaleX(1.35f)
                .scaleY(1.35f)
                .alpha(1f)
                .setDuration(160)
                .withEndAction(new Runnable() {
                    @Override
                    public void run() {
                        star.animate()
                                .scaleX(1f)
                                .scaleY(1f)
                                .setDuration(160)
                                .start();
                    }
                })
                .start();
    }
}
