package net.androidgaming.millionaire2024;

public class EliminationGameActivity extends BaseGameActivity {
    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_elimination;
    }

    @Override
    protected String getMatchModeId() {
        return "elimination";
    }

    @Override
    protected boolean usesEliminationRoundFlow() {
        return true;
    }
}
