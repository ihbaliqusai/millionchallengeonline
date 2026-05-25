package net.androidgaming.millionaire2024;

import android.widget.TextView;

import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;

import de.hdodenhof.circleimageview.CircleImageView;

final class MatchOpponent {
    String id = "";
    String name = "خصم آلي";
    String photo = "";
    int level = 1;
    int intelligence = 60;
    int score = 0;
    boolean bot = false;
    boolean left = false;
    int sets = 0;
    int roundScore = 0;
    int gameScore = 0;
    int totalCorrectAnswers = 0;
    int setCorrectAnswers = 0;
    int timeoutStreak = 0;
    int submittedAnswerKey = 0;
    int displayedAnswer = 0;
    int roundPoints = 0;
    boolean submitted = false;
    boolean eliminated = false;
    long answerElapsedMs = GameRules.QUESTION_TIMEOUT_MS;
    long totalAnswerTimeMs = 0L;
    long setAnswerTimeMs = 0L;
    CircleImageView topImageView;
    TextView topNameView;
    CircleImageView scoreImageView;
    TextView scoreNameView;
    TextView roundScoreView;
    TextView setsView;
    TextView gameScoreView;
    final ArrayList<CircleImageView> answerThumbViews = new ArrayList<>();
    DatabaseReference statusRef;
    ValueEventListener statusListener;
}
