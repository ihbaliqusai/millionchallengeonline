package net.androidgaming.millionaire2024;

final class GameRules {
    static final int ANSWER_KEY_RIGHT = 1;
    static final int ANSWER_KEY_WRONG_1 = 2;
    static final int ANSWER_KEY_WRONG_2 = 3;
    static final int ANSWER_KEY_WRONG_3 = 4;
    static final int[] ONLINE_SPEED_POINTS = new int[]{10, 7, 5, 3};
    static final long QUESTION_TIMEOUT_MS = 30_000L;
    static final long FIRST_QUESTION_SYNC_BUFFER_MS = 4_500L;
    static final long NEXT_QUESTION_SYNC_BUFFER_MS = 2_500L;
    static final int MAX_TIMEOUT_STREAK = 3;

    private GameRules() {
    }
}
