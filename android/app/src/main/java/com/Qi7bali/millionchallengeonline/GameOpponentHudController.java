package net.androidgaming.millionaire2024;

import android.graphics.drawable.GradientDrawable;
import android.util.DisplayMetrics;
import android.util.TypedValue;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import de.hdodenhof.circleimageview.CircleImageView;

final class GameOpponentHudController {
    private final GameActivity activity;

    GameOpponentHudController(GameActivity activity) {
        this.activity = activity;
    }

    void initCompetitiveHudViews() {
        activity.llyPlayer1 = activity.findViewById(R.id.llyPlayer1);
        activity.imgPlayer1 = activity.findViewById(R.id.imgPlayer1);
        activity.txtPlayer1 = activity.findViewById(R.id.txtPlayer1);
        activity.llyOpponents = activity.findViewById(R.id.llyOpponents);
        activity.llyOpponentScores = activity.findViewById(R.id.llyOpponentScores);
        activity.scoreHeaderRow = activity.findViewById(R.id.llyScoreHeader);
        activity.scoreMeRow = activity.findViewById(R.id.llyScoreMe);

        activity.rlyScore = activity.findViewById(R.id.rlyScore);
        activity.labScore = activity.findViewById(R.id.labScore);
        activity.labSets = activity.findViewById(R.id.labSets);
        activity.labScoreGame = activity.findViewById(R.id.labScoreGame);
        activity.imgMe = activity.findViewById(R.id.imgMe);
        activity.txtMeName = activity.findViewById(R.id.txtMeName);
        activity.txtScoreMe = activity.findViewById(R.id.txtScoreMe);
        activity.txtScoreGameMe = activity.findViewById(R.id.txtScoreGameMe);
        activity.txtSetsMe = activity.findViewById(R.id.txtSetsMe);
        if (activity.txtMeName != null) activity.txtMeName.setText(activity.myName);

        activity.imgAnswer1Player1 = activity.findViewById(R.id.imgAnswer1Player1);
        activity.imgAnswer2Player1 = activity.findViewById(R.id.imgAnswer2Player1);
        activity.imgAnswer3Player1 = activity.findViewById(R.id.imgAnswer3Player1);
        activity.imgAnswer4Player1 = activity.findViewById(R.id.imgAnswer4Player1);
        activity.opponentAnswerContainers.clear();
        activity.opponentAnswerContainers.add(activity.findViewById(R.id.llyAnswer1Opponents));
        activity.opponentAnswerContainers.add(activity.findViewById(R.id.llyAnswer2Opponents));
        activity.opponentAnswerContainers.add(activity.findViewById(R.id.llyAnswer3Opponents));
        activity.opponentAnswerContainers.add(activity.findViewById(R.id.llyAnswer4Opponents));
    }

    void buildOpponentPanels() {
        if (!activity.modeOnline && !activity.campaignBossBattle) {
            return;
        }
        configureScoreboardLayout();
        activity.txtPlayer1.setText(activity.myName);
        Data.setImageSource(activity, activity.imgPlayer1, activity.myPhoto);
        activity.llyPlayer1.setVisibility(View.GONE);
        View scrollOpponents = activity.findViewById(R.id.scrollOpponents);
        if (scrollOpponents != null) {
            scrollOpponents.setVisibility(View.GONE);
        }
        if (activity.llyOpponents != null) {
            activity.llyOpponents.removeAllViews();
        }
        if (activity.llyOpponentScores != null) {
            activity.llyOpponentScores.removeAllViews();
        }
        clearOpponentAnswerThumbs();

        for (MatchOpponent opponent : activity.opponents) {
            if (activity.llyOpponents != null) {
                activity.llyOpponents.addView(createOpponentTopCard(opponent));
            }
            if (activity.llyOpponentScores != null) {
                activity.llyOpponentScores.addView(createOpponentScoreRow(opponent));
            }
            for (LinearLayout container : activity.opponentAnswerContainers) {
                CircleImageView thumbView = createAnswerThumbView(container.getChildCount() > 0);
                container.addView(thumbView);
                opponent.answerThumbViews.add(thumbView);
            }
        }

        activity.rlyScore.setVisibility(View.VISIBLE);
        refreshOpponentPanels();
    }

    void configureScoreboardLayout() {
        if ((!activity.modeOnline && !activity.campaignBossBattle) || activity.rlyScore == null) {
            return;
        }

        final int totalPlayers = 1 + activity.opponents.size();
        final DisplayMetrics metrics = activity.getResources().getDisplayMetrics();
        final float screenHeightDp = metrics.heightPixels / metrics.density;
        final int scoreboardBudgetDp = Math.max(220, Math.round(screenHeightDp * 0.54f));
        final boolean compact = totalPlayers >= 6;
        final boolean ultraCompact = totalPlayers >= 9;

        activity.scoreboardPanelWidthDp = ultraCompact ? 228 : (compact ? 242 : 270);
        activity.scoreboardHeaderHeightDp = ultraCompact ? 22 : (compact ? 24 : 28);
        final int calculatedRowHeight = (scoreboardBudgetDp - activity.scoreboardHeaderHeightDp - 10) / Math.max(1, totalPlayers);
        activity.scoreboardRowHeightDp = Math.max(22, Math.min(48, calculatedRowHeight));
        activity.scoreboardAvatarColumnWidthDp = activity.scoreboardRowHeightDp <= 26 ? 30 : (activity.scoreboardRowHeightDp <= 32 ? 34 : (ultraCompact ? 36 : (compact ? 40 : 44)));
        activity.scoreboardAvatarSizeDp = Math.max(18, Math.min(28, activity.scoreboardRowHeightDp - 12));
        activity.scoreboardAvatarBorderDp = ultraCompact ? 1 : 2;
        activity.scoreboardHorizontalPaddingDp = activity.scoreboardRowHeightDp <= 26 ? 3 : (ultraCompact ? 4 : 6);
        activity.scoreboardHeaderTextSp = activity.scoreboardRowHeightDp <= 26 ? 8.5f : (ultraCompact ? 9f : (compact ? 10f : 11f));
        activity.scoreboardNameTextSp = activity.scoreboardRowHeightDp <= 26 ? 6.2f : (activity.scoreboardRowHeightDp <= 30 ? 6.8f : (ultraCompact ? 7f : (compact ? 7.5f : 8f)));
        activity.scoreboardValueTextSp = activity.scoreboardRowHeightDp <= 26 ? 10f : (activity.scoreboardRowHeightDp <= 30 ? 11f : (ultraCompact ? 11.5f : (compact ? 12.5f : 14f)));

        ViewGroup.LayoutParams panelParams = activity.rlyScore.getLayoutParams();
        panelParams.width = activity.dp(activity.scoreboardPanelWidthDp);
        activity.rlyScore.setLayoutParams(panelParams);

        if (activity.scoreHeaderRow != null) {
            LinearLayout.LayoutParams headerParams =
                    (LinearLayout.LayoutParams) activity.scoreHeaderRow.getLayoutParams();
            headerParams.height = activity.dp(activity.scoreboardHeaderHeightDp);
            activity.scoreHeaderRow.setLayoutParams(headerParams);
            activity.scoreHeaderRow.setPadding(
                    activity.dp(activity.scoreboardHorizontalPaddingDp),
                    0,
                    activity.dp(activity.scoreboardHorizontalPaddingDp),
                    0
            );

            for (int i = 0; i < activity.scoreHeaderRow.getChildCount(); i++) {
                View child = activity.scoreHeaderRow.getChildAt(i);
                if (child instanceof TextView) {
                    ((TextView) child).setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardHeaderTextSp);
                }
            }
            View starCell = activity.scoreHeaderRow.getChildAt(0);
            LinearLayout.LayoutParams starParams = (LinearLayout.LayoutParams) starCell.getLayoutParams();
            starParams.width = activity.dp(activity.scoreboardAvatarColumnWidthDp);
            starCell.setLayoutParams(starParams);
        }

        if (activity.scoreMeRow != null) {
            LinearLayout.LayoutParams myRowParams =
                    (LinearLayout.LayoutParams) activity.scoreMeRow.getLayoutParams();
            myRowParams.height = activity.dp(activity.scoreboardRowHeightDp);
            activity.scoreMeRow.setLayoutParams(myRowParams);
            activity.scoreMeRow.setPadding(
                    activity.dp(activity.scoreboardHorizontalPaddingDp),
                    activity.dp(2),
                    activity.dp(activity.scoreboardHorizontalPaddingDp),
                    activity.dp(2)
            );

            View identityCol = activity.scoreMeRow.getChildAt(0);
            if (identityCol instanceof LinearLayout) {
                LinearLayout identityLayout = (LinearLayout) identityCol;
                LinearLayout.LayoutParams identityParams =
                        (LinearLayout.LayoutParams) identityLayout.getLayoutParams();
                identityParams.width = activity.dp(activity.scoreboardAvatarColumnWidthDp);
                identityLayout.setLayoutParams(identityParams);

                View avatarView = identityLayout.getChildAt(0);
                if (avatarView instanceof CircleImageView) {
                    CircleImageView avatar = (CircleImageView) avatarView;
                    LinearLayout.LayoutParams avatarParams =
                            (LinearLayout.LayoutParams) avatar.getLayoutParams();
                    avatarParams.width = activity.dp(activity.scoreboardAvatarSizeDp);
                    avatarParams.height = activity.dp(activity.scoreboardAvatarSizeDp);
                    avatar.setLayoutParams(avatarParams);
                    avatar.setBorderWidth(activity.dp(activity.scoreboardAvatarBorderDp));
                }

                View nameView = identityLayout.getChildAt(1);
                if (nameView instanceof TextView) {
                    TextView nameText = (TextView) nameView;
                    LinearLayout.LayoutParams nameParams =
                            (LinearLayout.LayoutParams) nameText.getLayoutParams();
                    nameParams.width = activity.dp(activity.scoreboardAvatarColumnWidthDp);
                    nameText.setLayoutParams(nameParams);
                    nameText.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardNameTextSp);
                }
            }

            styleScoreValueCell(activity.txtScoreMe, activity.getResources().getColor(android.R.color.white));
            styleScoreValueCell(activity.txtScoreGameMe, activity.getResources().getColor(R.color.lightBlueApp));
            if (activity.txtSetsMe != null) {
                styleStateCell(activity.txtSetsMe, activity.localPlayerEliminated);
            }
        }

        if (activity.labScore != null) {
            activity.labScore.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardHeaderTextSp);
        }
        if (activity.labSets != null) {
            activity.labSets.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardHeaderTextSp);
        }
        if (activity.labScoreGame != null) {
            activity.labScoreGame.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardHeaderTextSp);
        }

        if (activity.llyOpponentScores != null) {
            ViewGroup.LayoutParams rowsParams = activity.llyOpponentScores.getLayoutParams();
            rowsParams.height = ViewGroup.LayoutParams.WRAP_CONTENT;
            activity.llyOpponentScores.setLayoutParams(rowsParams);
        }
    }

    void refreshOpponentPanels() {
        for (MatchOpponent opponent : activity.opponents) {
            if (opponent.topNameView != null) {
                opponent.topNameView.setText(opponent.name);
                opponent.topNameView.setAlpha(opponent.eliminated ? 0.45f : 1f);
            }
            if (opponent.topImageView != null) {
                Data.setImageSource(activity, opponent.topImageView, opponent.photo);
                updatePlayerVisualState(opponent.topImageView, opponent.eliminated);
            }
            if (opponent.scoreImageView != null) {
                Data.setImageSource(activity, opponent.scoreImageView, opponent.photo);
                updatePlayerVisualState(opponent.scoreImageView, opponent.eliminated);
            }
            if (opponent.scoreNameView != null) {
                opponent.scoreNameView.setText(opponent.name);
                opponent.scoreNameView.setAlpha(opponent.eliminated ? 0.45f : 1f);
            }
            if (opponent.roundScoreView != null) {
                opponent.roundScoreView.setText(String.valueOf(opponent.roundScore));
                opponent.roundScoreView.setAlpha(opponent.eliminated ? 0.45f : 1f);
            }
            if (opponent.setsView != null) {
                opponent.setsView.setText(activity.eliminationMode
                        ? (opponent.eliminated ? "خارج" : "نشط")
                        : String.valueOf(opponent.sets));
                opponent.setsView.setAlpha(opponent.eliminated ? 0.45f : 1f);
                styleStateCell(opponent.setsView, opponent.eliminated);
            }
            if (opponent.gameScoreView != null) {
                opponent.gameScoreView.setText(String.valueOf(opponent.gameScore));
                opponent.gameScoreView.setAlpha(opponent.eliminated ? 0.45f : 1f);
            }
            for (CircleImageView thumbView : opponent.answerThumbViews) {
                Data.setImageSource(activity, thumbView, opponent.photo);
                thumbView.setVisibility(View.INVISIBLE);
            }
        }
        refreshMePanelState();
    }

    private void styleScoreValueCell(TextView textView, int color) {
        if (textView == null) {
            return;
        }
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) textView.getLayoutParams();
        params.height = ViewGroup.LayoutParams.MATCH_PARENT;
        textView.setLayoutParams(params);
        textView.setTextColor(color);
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardValueTextSp);
    }

    private void styleStateCell(TextView textView, boolean eliminated) {
        if (textView == null) {
            return;
        }

        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) textView.getLayoutParams();
        final int verticalInsetDp = Math.max(1, Math.min(5, (activity.scoreboardRowHeightDp - 16) / 3));
        params.height = activity.eliminationMode ? activity.dp(Math.max(16, activity.scoreboardRowHeightDp - (verticalInsetDp * 2))) : ViewGroup.LayoutParams.MATCH_PARENT;
        params.topMargin = activity.eliminationMode ? activity.dp(verticalInsetDp) : 0;
        params.bottomMargin = activity.eliminationMode ? activity.dp(verticalInsetDp) : 0;
        params.leftMargin = activity.eliminationMode ? activity.dp(2) : 0;
        params.rightMargin = activity.eliminationMode ? activity.dp(2) : 0;
        textView.setLayoutParams(params);
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.eliminationMode ? (activity.scoreboardValueTextSp - 1f) : activity.scoreboardValueTextSp);

        if (!activity.eliminationMode) {
            textView.setTextColor(activity.getResources().getColor(R.color.stepSelected));
            textView.setBackground(null);
            return;
        }

        GradientDrawable drawable = new GradientDrawable();
        drawable.setCornerRadius(activity.dp(12));
        if (eliminated) {
            drawable.setColor(android.graphics.Color.parseColor("#33B91C1C"));
            drawable.setStroke(activity.dp(1), android.graphics.Color.parseColor("#F87171"));
            textView.setTextColor(android.graphics.Color.parseColor("#FECACA"));
        } else {
            drawable.setColor(android.graphics.Color.parseColor("#1A0EA5E9"));
            drawable.setStroke(activity.dp(1), android.graphics.Color.parseColor("#7DD3FC"));
            textView.setTextColor(android.graphics.Color.parseColor("#E0F2FE"));
        }
        textView.setBackground(drawable);
    }

    private View createOpponentTopCard(MatchOpponent opponent) {
        LinearLayout card = new LinearLayout(activity);
        card.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(activity.dp(84), ViewGroup.LayoutParams.WRAP_CONTENT);
        params.setMargins(activity.dp(6), 0, activity.dp(6), 0);
        card.setLayoutParams(params);

        CircleImageView imageView = new CircleImageView(activity);
        LinearLayout.LayoutParams imageParams = new LinearLayout.LayoutParams(activity.dp(64), activity.dp(64));
        imageParams.gravity = android.view.Gravity.CENTER_HORIZONTAL;
        imageView.setLayoutParams(imageParams);
        imageView.setBorderWidth(activity.dp(2));
        imageView.setBorderColor(activity.getResources().getColor(R.color.player2));
        Data.setImageSource(activity, imageView, opponent.photo);

        TextView nameView = new TextView(activity);
        nameView.setLayoutParams(new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        nameView.setTextColor(activity.getResources().getColor(android.R.color.white));
        nameView.setTextSize(12);
        nameView.setGravity(android.view.Gravity.CENTER_HORIZONTAL);
        nameView.setMaxLines(2);
        nameView.setText(opponent.name);

        opponent.topImageView = imageView;
        opponent.topNameView = nameView;

        card.addView(imageView);
        card.addView(nameView);
        return card;
    }

    private View createOpponentScoreRow(MatchOpponent opponent) {
        LinearLayout row = new LinearLayout(activity);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(android.view.Gravity.CENTER_VERTICAL);
        row.setPadding(activity.dp(activity.scoreboardHorizontalPaddingDp), activity.dp(2), activity.dp(activity.scoreboardHorizontalPaddingDp), activity.dp(2));
        row.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                activity.dp(activity.scoreboardRowHeightDp)
        ));

        LinearLayout avatarCol = new LinearLayout(activity);
        avatarCol.setOrientation(LinearLayout.VERTICAL);
        avatarCol.setGravity(android.view.Gravity.CENTER_HORIZONTAL);
        avatarCol.setLayoutParams(new LinearLayout.LayoutParams(
                activity.dp(activity.scoreboardAvatarColumnWidthDp),
                ViewGroup.LayoutParams.MATCH_PARENT
        ));

        CircleImageView imageView = new CircleImageView(activity);
        LinearLayout.LayoutParams imageParams = new LinearLayout.LayoutParams(
                activity.dp(activity.scoreboardAvatarSizeDp),
                activity.dp(activity.scoreboardAvatarSizeDp)
        );
        imageParams.setMargins(0, activity.dp(1), 0, activity.dp(1));
        imageView.setLayoutParams(imageParams);
        imageView.setBorderWidth(activity.dp(activity.scoreboardAvatarBorderDp));
        imageView.setBorderColor(activity.getResources().getColor(R.color.player2));
        Data.setImageSource(activity, imageView, opponent.photo);

        TextView nameLabel = new TextView(activity);
        nameLabel.setLayoutParams(new LinearLayout.LayoutParams(
                activity.dp(activity.scoreboardAvatarColumnWidthDp),
                ViewGroup.LayoutParams.WRAP_CONTENT
        ));
        nameLabel.setGravity(android.view.Gravity.CENTER);
        nameLabel.setTextColor(android.graphics.Color.WHITE);
        nameLabel.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardNameTextSp);
        nameLabel.setMaxLines(1);
        nameLabel.setEllipsize(android.text.TextUtils.TruncateAt.END);
        nameLabel.setText(opponent.name);

        avatarCol.addView(imageView);
        avatarCol.addView(nameLabel);

        TextView roundView = createScoreCell();
        TextView setsView = createSetsCell();
        TextView gameView = createGameScoreCell();

        opponent.scoreImageView = imageView;
        opponent.scoreNameView = nameLabel;
        opponent.roundScoreView = roundView;
        opponent.setsView = setsView;
        opponent.gameScoreView = gameView;

        row.addView(avatarCol);
        row.addView(roundView);
        row.addView(setsView);
        row.addView(gameView);
        return row;
    }

    private TextView createScoreCell() {
        TextView textView = new TextView(activity);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.MATCH_PARENT,
                1f
        );
        textView.setLayoutParams(params);
        textView.setGravity(android.view.Gravity.CENTER);
        textView.setTextColor(activity.getResources().getColor(android.R.color.white));
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardValueTextSp);
        textView.setTypeface(null, android.graphics.Typeface.BOLD);
        textView.setText("0");
        return textView;
    }

    private TextView createSetsCell() {
        TextView textView = new TextView(activity);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                0,
                activity.eliminationMode ? activity.dp(Math.max(26, activity.scoreboardRowHeightDp - 12)) : ViewGroup.LayoutParams.MATCH_PARENT,
                1f
        );
        if (activity.eliminationMode) {
            params.setMargins(activity.dp(2), activity.dp(5), activity.dp(2), activity.dp(5));
        }
        textView.setLayoutParams(params);
        textView.setGravity(android.view.Gravity.CENTER);
        textView.setTextColor(activity.getResources().getColor(R.color.stepSelected));
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP,
                activity.eliminationMode ? (activity.scoreboardValueTextSp - 1f) : activity.scoreboardValueTextSp);
        textView.setTypeface(null, android.graphics.Typeface.BOLD);
        textView.setText("0");
        return textView;
    }

    private TextView createGameScoreCell() {
        TextView textView = new TextView(activity);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.MATCH_PARENT,
                1f
        );
        textView.setLayoutParams(params);
        textView.setGravity(android.view.Gravity.CENTER);
        textView.setTextColor(activity.getResources().getColor(R.color.lightBlueApp));
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, activity.scoreboardValueTextSp);
        textView.setTypeface(null, android.graphics.Typeface.BOLD);
        textView.setText("0");
        return textView;
    }

    private CircleImageView createAnswerThumbView(boolean overlapPrevious) {
        CircleImageView imageView = new CircleImageView(activity);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(activity.dp(14), activity.dp(14));
        params.setMargins(overlapPrevious ? activity.dp(-9) : 0, activity.dp(1), 0, activity.dp(1));
        imageView.setLayoutParams(params);
        imageView.setBorderWidth(activity.dp(1));
        imageView.setBorderColor(activity.getResources().getColor(R.color.player2));
        imageView.setVisibility(View.INVISIBLE);
        return imageView;
    }

    private void clearOpponentAnswerThumbs() {
        for (LinearLayout container : activity.opponentAnswerContainers) {
            container.removeAllViews();
        }
        for (MatchOpponent opponent : activity.opponents) {
            opponent.answerThumbViews.clear();
        }
    }

    private void refreshMePanelState() {
        updatePlayerVisualState(activity.imgMe, activity.localPlayerEliminated);
        if (activity.txtMeName != null) activity.txtMeName.setAlpha(activity.localPlayerEliminated ? 0.45f : 1f);
        if (activity.txtScoreMe != null) activity.txtScoreMe.setAlpha(activity.localPlayerEliminated ? 0.45f : 1f);
        if (activity.txtScoreGameMe != null) activity.txtScoreGameMe.setAlpha(activity.localPlayerEliminated ? 0.45f : 1f);
        if (activity.txtSetsMe != null) {
            activity.txtSetsMe.setAlpha(activity.localPlayerEliminated ? 0.45f : 1f);
            if (activity.eliminationMode) {
                activity.txtSetsMe.setText(activity.localPlayerEliminated ? "خارج" : "نشط");
            }
            styleStateCell(activity.txtSetsMe, activity.localPlayerEliminated);
        }
    }

    private void updatePlayerVisualState(ImageView view, boolean eliminated) {
        if (view == null) {
            return;
        }
        if (eliminated) {
            GameLifelineController.setGreyscale(view);
            view.setImageAlpha(140);
        } else {
            GameLifelineController.setColored(view);
            view.setImageAlpha(255);
        }
    }
}
