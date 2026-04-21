package net.androidgaming.millionaire2024;

public class BattleGameActivity extends BaseGameActivity {
    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_battle;
    }

    @Override
    protected String getMatchModeId() {
        return "battle";
    }
}
