package net.androidgaming.millionaire2024;

public class SeriesGameActivity extends BaseGameActivity {

    @Override
    protected int getLayoutResId() {
        return R.layout.activity_game_series;
    }

    /**
     * يقرأ seriesTarget من الـ Intent المُرسل من Flutter.
     * 2 = أفضل من 3 (أول من يفوز بجولتين)
     * 3 = أفضل من 5 (أول من يفوز بـ 3 جولات)
     */
    @Override
    protected int getSeriesTarget() {
        int target = getIntent().getIntExtra("seriesTarget", 2);
        return Math.max(1, target);
    }
}
