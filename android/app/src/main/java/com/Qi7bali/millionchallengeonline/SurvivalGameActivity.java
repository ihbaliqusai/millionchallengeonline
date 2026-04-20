package net.androidgaming.millionaire2024;

import android.os.Bundle;
import android.widget.TextView;

public class SurvivalGameActivity extends BaseGameActivity {

    private TextView life1;
    private TextView life2;
    private TextView life3;

    private static final String HEART_FULL = "\u2665";
    private static final String HEART_EMPTY = "\u2661";
    private static final int COLOR_FULL = 0xFFE53935;
    private static final int COLOR_EMPTY = 0xFF616161;

    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_survival;
    }

    @Override
    protected boolean isSurvivalMode() {
        return true;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        eliminationMode = true;

        life1 = findViewById(R.id.imgLife1);
        life2 = findViewById(R.id.imgLife2);
        life3 = findViewById(R.id.imgLife3);

        refreshMyLives();
        refreshPlayerPanels();
    }

    @Override
    protected void onMyLifeLost() {
        runOnUiThread(() -> {
            refreshMyLives();
            refreshPlayerPanels();
        });
    }

    private void refreshMyLives() {
        setHeart(life1, myLivesRemaining >= 1);
        setHeart(life2, myLivesRemaining >= 2);
        setHeart(life3, myLivesRemaining >= 3);
    }

    private void setHeart(TextView view, boolean alive) {
        if (view == null) {
            return;
        }
        view.setText(alive ? HEART_FULL : HEART_EMPTY);
        view.setTextColor(alive ? COLOR_FULL : COLOR_EMPTY);
    }

    @Override
    protected void onOpponentLifeLost(Object opponentObj) {
        refreshPlayerPanels();
    }
}
