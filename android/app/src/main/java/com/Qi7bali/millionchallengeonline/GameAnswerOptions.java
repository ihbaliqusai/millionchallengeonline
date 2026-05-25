package net.androidgaming.millionaire2024;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;

import static net.androidgaming.millionaire2024.GameRules.ANSWER_KEY_RIGHT;
import static net.androidgaming.millionaire2024.GameRules.ANSWER_KEY_WRONG_1;
import static net.androidgaming.millionaire2024.GameRules.ANSWER_KEY_WRONG_2;
import static net.androidgaming.millionaire2024.GameRules.ANSWER_KEY_WRONG_3;

final class GameAnswerOptions {
    private GameAnswerOptions() {
    }

    static ArrayList<Integer> buildShuffledKeys(
            boolean onlineMode,
            int currentQuestion,
            String gameId,
            Question question
    ) {
        ArrayList<Integer> list = new ArrayList<>();
        list.add(ANSWER_KEY_RIGHT);
        list.add(ANSWER_KEY_WRONG_1);
        list.add(ANSWER_KEY_WRONG_2);
        list.add(ANSWER_KEY_WRONG_3);

        if (onlineMode) {
            long seed = 17L;
            seed = (31L * seed) + currentQuestion;
            seed = (31L * seed) + (gameId == null ? 0 : gameId.hashCode());
            seed = (31L * seed) + (question == null || question.Q == null ? 0 : question.Q.hashCode());
            Collections.shuffle(list, new Random(seed));
        } else {
            Collections.shuffle(list);
        }
        return list;
    }

    static String getAnswerText(Question question, int answerKey) {
        switch (answerKey) {
            case ANSWER_KEY_RIGHT:
                return question.R;
            case ANSWER_KEY_WRONG_1:
                return question.W1;
            case ANSWER_KEY_WRONG_2:
                return question.W2;
            case ANSWER_KEY_WRONG_3:
                return question.W3;
            default:
                return "";
        }
    }

    static int getAnswerKeyForDisplayedIndex(List<Integer> answerOrder, int displayedIndex) {
        if (answerOrder == null || displayedIndex <= 0 || displayedIndex > answerOrder.size()) {
            return 0;
        }
        return answerOrder.get(displayedIndex - 1);
    }

    static int getDisplayedIndexForAnswerKey(List<Integer> answerOrder, int answerKey) {
        if (answerOrder == null) return 0;
        for (int i = 0; i < answerOrder.size(); i++) {
            if (answerOrder.get(i) == answerKey) {
                return i + 1;
            }
        }
        return 0;
    }

    static int getDisplayedIndexFromTextId(int id) {
        if (id == R.id.txtA1) {
            return 1;
        } else if (id == R.id.txtA2) {
            return 2;
        } else if (id == R.id.txtA3) {
            return 3;
        } else if (id == R.id.txtA4) {
            return 4;
        }
        return -1;
    }
}
