package net.androidgaming.millionaire2024;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.widget.TextViewCompat;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.ColorMatrix;
import android.graphics.ColorMatrixColorFilter;
import android.graphics.drawable.GradientDrawable;
import android.media.MediaPlayer;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.os.Handler;
import android.util.DisplayMetrics;
import android.util.Log;
import android.util.TypedValue;
import android.view.HapticFeedbackConstants;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.TranslateAnimation;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;
import com.google.android.gms.ads.AdRequest;
import com.google.android.gms.ads.LoadAdError;
import com.google.android.gms.ads.FullScreenContentCallback;
import com.google.android.gms.ads.interstitial.InterstitialAd;
import com.google.android.gms.ads.interstitial.InterstitialAdLoadCallback;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.HashMap;
import java.util.Random;

import de.hdodenhof.circleimageview.CircleImageView;
import io.netopen.hotbitmapgg.library.view.RingProgressBar;
import com.google.android.gms.ads.MobileAds;
import com.google.android.gms.ads.initialization.InitializationStatus;
import com.google.android.gms.ads.initialization.OnInitializationCompleteListener;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.MutableData;
import com.google.firebase.database.Query;
import com.google.firebase.database.Transaction;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Iterator;
import java.util.Locale;

public class GameActivity extends AppCompatActivity {
    private static final int ANSWER_KEY_RIGHT = 1;
    private static final int ANSWER_KEY_WRONG_1 = 2;
    private static final int ANSWER_KEY_WRONG_2 = 3;
    private static final int ANSWER_KEY_WRONG_3 = 4;
    private static final int[] ONLINE_SPEED_POINTS = new int[]{10, 7, 5, 3};
    private static final long QUESTION_TIMEOUT_MS = 30_000L;
    private static final long FIRST_QUESTION_SYNC_BUFFER_MS = 4_500L;
    private static final long NEXT_QUESTION_SYNC_BUFFER_MS = 2_500L;
    private static final int MAX_TIMEOUT_STREAK = 3;

    private static class BotProfile {
        final String name;
        final String photo;
        final int intelligence;

        BotProfile(String name, String photo, int intelligence) {
            this.name = name;
            this.photo = photo;
            this.intelligence = intelligence;
        }
    }

    private static class RoundRankEntry {
        final String playerId;
        final long elapsedMs;

        RoundRankEntry(String playerId, long elapsedMs) {
            this.playerId = playerId;
            this.elapsedMs = elapsedMs;
        }
    }

    private static final BotProfile[] BOT_PROFILES = new BotProfile[]{
            new BotProfile("طارق",   "drawable:avatar1",  95),
            new BotProfile("ليلى",   "drawable:avatar2",  70),
            new BotProfile("هدى",    "drawable:avatar3",  65),
            new BotProfile("عمر",    "drawable:avatar4",  85),
            new BotProfile("منى",    "drawable:avatar5",  50),
            new BotProfile("سارة",   "drawable:avatar6",  80),
            new BotProfile("علي",    "drawable:avatar7",  60),
            new BotProfile("فيصل",   "drawable:avatar8",  90),
            new BotProfile("يوسف",   "drawable:avatar9",  40),
            new BotProfile("رنا",    "drawable:avatar10", 75),
            new BotProfile("خالد",   "drawable:avatar11", 92),
            new BotProfile("سالم",   "drawable:avatar12", 78)
    };

    private static class MatchOpponent {
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
        long answerElapsedMs = QUESTION_TIMEOUT_MS;
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

    ArrayList<Question> questions = new ArrayList<>();
    ArrayList<TextView> listAnswerViews = new ArrayList<>();
    ArrayList<LinearLayout> steps = new ArrayList<>();
    ArrayList<Integer> currentAnswerOrder = new ArrayList<>();
    TextView txtQ, txtA1, txtA2, txtA3, txtA4, txtSelected, txtRight, txtAmount,
            txtProgress, txtPlayer1, txtPlayer2, txtScoreMe, txtSetsMe, txtScoreGameMe,
            txtScoreOpponent, txtSetsOpponent, txtScoreGameOpponent;
    ImageView imgA1, imgA2, imgA3, imgA4, imgVote1, imgVote2, imgVote3, imgVote4, btnCloseVote,
            imgCallerBody, imgCallerFace, imgCallerMouth,
            imgSelected, imgRight, imgHelp5050, imgHelpCall, imgHelpAudience, imgHome, imgVolume,
            imgAnswer1Player1, imgAnswer1Player2, imgAnswer2Player1, imgAnswer2Player2,
            imgAnswer3Player1, imgAnswer3Player2, imgAnswer4Player1, imgAnswer4Player2;
    RelativeLayout rlySelected, rlyRight, rlyDialog, rlyVotes, rlyCall, rlyProgress;
    LinearLayout rlyScore;
    LinearLayout llyQA, llySteps, llySolde, llyPlayer1, llyPlayer2;
    Typewriter txtDialog, txtCallAnswer;
    Button btnDialogYes, btnDialogNo, btnGetMoney;
    RingProgressBar pbTime;
    CountDownTimer cdtProgress;
    MediaPlayer mpSound, mpBeep, mpBeep1;
    CircleImageView imgPlayer1, imgPlayer2, imgMe, imgOpponent;
    boolean FAST_LIGHTS,
            CAN_PLAY = false,
            CAN_CLICK = false,
            CAN_HOME = false,
            EXITING = false,
            SOUND_ON = true,
            MUSIC_ON = true,
            currentSoundIsMusic = false,
            modeOnline = false,
            eliminationMode = false,
            meOwner;
    Person person;
    Data dataAnswer;
    InterstitialAd mInterstitialAd;
    String myID, opponentID, myName, opponentName, myPhoto, opponentPhoto,
            currentDialog, gameID;
    int myLevel = 1, opponentLevel = 1, myScore = 0, opponentScore = 0,
            currentQuestion, currentStep, PROGRESS_VALUE, T_LIGHTS = 0,
            setMe = 0, setOpponent = 0,
            setScoreMe = 0, setScoreOpponent = 0,
            gameScoreMe = 0, gameScoreOpponent = 0,
            rightAnswer, myAnswer, opponentAnswer, myResult;
    boolean usedHelp5050 = false, usedHelpAudience = false, usedHelpCall = false;

    private boolean adsInitialized = false;
    private boolean questionsReady = false;
    private boolean startPending = false;
    private boolean questionsLoadFailed = false;
    private DatabaseReference myStatusRef;
    private DatabaseReference serverOffsetRef;
    private DatabaseReference questionSyncRef;
    private DatabaseReference opponentStatusRef;
    private ValueEventListener opponentStatusListener;
    private ValueEventListener serverOffsetListener;
    private ValueEventListener questionSyncListener;
    private boolean opponentExitHandled = false;
    private boolean matchStateCommitted = false;
    private final Handler fictitiousAnswerHandler = new Handler();
    private final Handler questionSyncHandler = new Handler();
    private Runnable pendingFictitiousAnswerRunnable;
    private Runnable pendingQuestionStartRunnable;
    private DatabaseReference roundSyncRef;
    private ValueEventListener roundSyncListener;
    private ValueEventListener opponentRoundListener;
    private boolean myAnswerSubmitted = false;
    private boolean opponentAnswerSubmitted = false;
    private boolean resolvingRound = false;
    private boolean roundResolved = false;
    private boolean resolvingFinal = false;  // guard: only one Firebase read in-flight
    private int mySubmittedAnswerKey = 0;
    private int opponentSubmittedAnswerKey = 0;
    private int myRoundPoints = 0;
    private int opponentRoundPoints = 0;
    private int myTimeoutStreak = 0;
    private int myTotalCorrectAnswers = 0;
    private int mySetCorrectAnswers = 0;
    private long myAnswerElapsedMs = QUESTION_TIMEOUT_MS;
    private long myTotalAnswerTimeMs = 0L;
    private long mySetAnswerTimeMs = 0L;
    private long serverTimeOffsetMs = 0L;
    private long questionStartTimeMs = 0L;
    private boolean localPlayerRemoved = false;
    private boolean localPlayerEliminated = false;
    private boolean spectatorEliminationRound = false;
    private int pendingQuestionIndex = -1;
    private long scheduledQuestionStartAt = 0L;
    private final ArrayList<MatchOpponent> opponents = new ArrayList<>();
    private final ArrayList<LinearLayout> opponentAnswerContainers = new ArrayList<>();
    private final HashMap<String, Runnable> pendingBotAnswerRunnables = new HashMap<>();
    private LinearLayout llyOpponents;
    private LinearLayout llyOpponentScores;
    private LinearLayout scoreHeaderRow;
    private LinearLayout scoreMeRow;
    private TextView txtMeName;
    private TextView labScore;
    private TextView labSets;
    private TextView labScoreGame;
    private int scoreboardPanelWidthDp = 270;
    private int scoreboardHeaderHeightDp = 28;
    private int scoreboardRowHeightDp = 48;
    private int scoreboardAvatarColumnWidthDp = 44;
    private int scoreboardAvatarSizeDp = 28;
    private int scoreboardAvatarBorderDp = 2;
    private int scoreboardHorizontalPaddingDp = 6;
    private float scoreboardHeaderTextSp = 11f;
    private float scoreboardNameTextSp = 8f;
    private float scoreboardValueTextSp = 14f;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_game);
        if (getSupportActionBar() != null) getSupportActionBar().hide();

        AppPrefs.ensureGuestUser(this);
        myID = AppPrefs.getUserId(this);
        myName = AppPrefs.getUserName(this);
        myPhoto = AppPrefs.getUserPhoto(this);
        myLevel = AppPrefs.getUserLevel(this);
        myScore = AppPrefs.getUserScore(this);
        SOUND_ON = AppPrefs.isSoundEnabled(this);
        MUSIC_ON = AppPrefs.isMusicEnabled(this);

        String modeExtra = getIntent().getStringExtra("mode");
        String matchModeExtra = getIntent().getStringExtra("matchMode");
        modeOnline = "online".equals(modeExtra);
        eliminationMode = "elimination".equals(matchModeExtra);
        meOwner = getIntent().getBooleanExtra("meOwner", true);


        findViewById(android.R.id.content).post(new Runnable() {
            @Override
            public void run() {
                initAdsIfNeeded();
            }
        });

        person = new Person((RelativeLayout) (findViewById(R.id.rlyPerson)));
        playSound(R.raw.main_theme_4, false, false);

        if (modeOnline) {
            if (Data.isNetworkAvailable(GameActivity.this)) {
                parseOpponentsFromIntent();

                llyPlayer1 = findViewById(R.id.llyPlayer1);
                imgPlayer1 = findViewById(R.id.imgPlayer1);
                txtPlayer1 = findViewById(R.id.txtPlayer1);
                llyOpponents = findViewById(R.id.llyOpponents);
                llyOpponentScores = findViewById(R.id.llyOpponentScores);
                scoreHeaderRow = findViewById(R.id.llyScoreHeader);
                scoreMeRow = findViewById(R.id.llyScoreMe);

                rlyScore = findViewById(R.id.rlyScore);
                labScore = findViewById(R.id.labScore);
                labSets = findViewById(R.id.labSets);
                labScoreGame = findViewById(R.id.labScoreGame);
                imgMe = findViewById(R.id.imgMe);
                txtMeName = findViewById(R.id.txtMeName);
                txtScoreMe = findViewById(R.id.txtScoreMe);
                txtScoreGameMe = findViewById(R.id.txtScoreGameMe);
                txtSetsMe = findViewById(R.id.txtSetsMe);
                if (eliminationMode) {
                    labScore.setText("الصحيح");
                    labSets.setText("الحالة");
                    labScoreGame.setText("النقاط");
                    txtSetsMe.setText("نشط");
                }
                if (txtMeName != null) txtMeName.setText(myName);

                imgAnswer1Player1 = findViewById(R.id.imgAnswer1Player1);
                imgAnswer2Player1 = findViewById(R.id.imgAnswer2Player1);
                imgAnswer3Player1 = findViewById(R.id.imgAnswer3Player1);
                imgAnswer4Player1 = findViewById(R.id.imgAnswer4Player1);
                opponentAnswerContainers.add(findViewById(R.id.llyAnswer1Opponents));
                opponentAnswerContainers.add(findViewById(R.id.llyAnswer2Opponents));
                opponentAnswerContainers.add(findViewById(R.id.llyAnswer3Opponents));
                opponentAnswerContainers.add(findViewById(R.id.llyAnswer4Opponents));

                Data.setImageSource(this, imgMe, myPhoto);
                Data.setImageSource(this, imgAnswer1Player1, myPhoto);
                Data.setImageSource(this, imgAnswer2Player1, myPhoto);
                Data.setImageSource(this, imgAnswer3Player1, myPhoto);
                Data.setImageSource(this, imgAnswer4Player1, myPhoto);
                configureScoreboardLayout();
                buildOpponentPanels();
                syncPrimaryOpponentFields();

                if (meOwner) {
                    new Data().createGameID(myID, getOpponentIds(), new OnCreateGameIdListener() {
                        @Override
                        public void onSuccess(String gameID) {
                            GameActivity.this.gameID = gameID;
                            beginOnlineGameSession();
                            for (MatchOpponent opponent : opponents) {
                                if (!opponent.bot) {
                                    FirebaseDatabase.getInstance().getReference()
                                            .child("temp")
                                            .child(opponent.id)
                                            .child("gameID")
                                            .setValue(gameID);
                                }
                            }
                            getQuestions(gameID);
                        }

                        @Override
                        public void onFailed(DatabaseError error) {

                        }
                    });
                } else {
                    getGame();
                }
            } else {
                Toast.makeText(GameActivity.this, "لا يوجد اتصال بالإنترنت", Toast.LENGTH_SHORT).show();
            }

        } else {
            getQuestions("");
        }

        mpBeep = MediaPlayer.create(this, R.raw.beep);
        mpBeep1 = MediaPlayer.create(this, R.raw.beep1);

        rlyProgress = findViewById(R.id.rlyProgressbar);
        pbTime = findViewById(R.id.pbTime);
        txtProgress = findViewById(R.id.txtProgress);
        pbTime.setMax(300);

        rlyDialog = findViewById(R.id.rlyDialog);
        txtDialog = findViewById(R.id.txtDialog);

        rlyVotes = findViewById(R.id.rlyVotes);
        btnCloseVote = findViewById(R.id.btnCloseVote);
        rlyCall = findViewById(R.id.rlyCall);

        llyQA = findViewById(R.id.llyQA);
        llySteps = findViewById(R.id.llySteps);

        imgHelp5050 = findViewById(R.id.imgHelp5050);
        imgHelpCall = findViewById(R.id.imgHelpCall);
        imgHelpAudience = findViewById(R.id.imgHelpAudience);
        txtCallAnswer = findViewById(R.id.txtCallAnswer);
        updateInventoryBadges();

        imgHome = findViewById(R.id.imgHome);
        imgVolume = findViewById(R.id.imgVolume);

        imgCallerBody = findViewById(R.id.imgCallerBody);
        imgCallerFace = findViewById(R.id.imgCallerFace);
        imgCallerMouth = findViewById(R.id.imgCallerMouth);

        btnDialogYes = findViewById(R.id.btnDialogYes);
        btnDialogNo = findViewById(R.id.btnDialogNo);

        txtQ = findViewById(R.id.txtQ);
        txtA1 = findViewById(R.id.txtA1);
        txtA2 = findViewById(R.id.txtA2);
        txtA3 = findViewById(R.id.txtA3);
        txtA4 = findViewById(R.id.txtA4);
        configureAnswerTextSizing();
        configureGameSurfaceLayout();
        imgA1 = findViewById(R.id.imgA1);
        imgA2 = findViewById(R.id.imgA2);
        imgA3 = findViewById(R.id.imgA3);
        imgA4 = findViewById(R.id.imgA4);
        imgVote1 = findViewById(R.id.imgVote1);
        imgVote2 = findViewById(R.id.imgVote2);
        imgVote3 = findViewById(R.id.imgVote3);
        imgVote4 = findViewById(R.id.imgVote4);
        llySolde = findViewById(R.id.llySolde);
        txtAmount = findViewById(R.id.txtAmount);
        btnGetMoney = findViewById(R.id.btnGetMoney);

        FAST_LIGHTS = false;
        animLights();

        int idStep;
        for (int i = 1; i <= 15; i++) {
            idStep = getResources().getIdentifier("llyStep" + i, "id", this.getPackageName());
            steps.add((LinearLayout) findViewById(idStep));
        }

        listAnswerViews.add(txtA1);
        listAnswerViews.add(txtA2);
        listAnswerViews.add(txtA3);
        listAnswerViews.add(txtA4);

        currentQuestion = -1;
        currentStep = 0;

        goBlinking();

        final Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            int t = 0;

            @Override
            public void run() {
                t++;
                switch (t) {
                    case 1:
                        person.moveShow2Hands(2000);
                        if (modeOnline) {
                            rlyScore.setVisibility(View.VISIBLE);
                            Animations.move(rlyScore, 500, -300, 0, 0, 0);
                            showDialog("مرحبا بكما في مباراة جديدة", "", 800, 2000, R.drawable.mouth_01, false);
                        } else {
                            llySolde.setVisibility(View.VISIBLE);
                            showDialog("مرحبا بك في مباراة جديدة", "", 800, 2000, R.drawable.mouth_01, false);
                        }
                        handler.postDelayed(this, 3000);
                        break;
                    case 2:
                        person.moveShowHand(1000);
                        showDialog("هل تريد معرفة قوانين اللعبة ؟", "ConfirmRules", 1000, 0, R.drawable.mouth_05, false);
                        break;
                }
            }
        };
        handler.postDelayed(runnable, 4000);

        View.OnClickListener buttonListener = new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);
                if (CAN_PLAY) {
                    CAN_PLAY = false;
                    String viewName = getResources().getResourceName(view.getId());
                    myAnswer = Integer.parseInt(String.valueOf(viewName.charAt(viewName.length() - 1)));
                    rlySelected = findViewById(view.getId());
                    imgSelected = (ImageView) rlySelected.getChildAt(0);
                    txtSelected = (TextView) rlySelected.getChildAt(1);
                    if (txtSelected.getVisibility() == View.VISIBLE) {
                        imgSelected.setImageResource(R.drawable.frame_selected);
                        showDialog("جواب نهائي ؟", "ConfirmAnswer", 500, 0, R.drawable.mouth_05, false);
                        person.bend(1000, R.drawable.person_02);
                        person.raiseEyeBrowsUp(1000, false, true);
                    }
                }
            }
        };
        (findViewById(R.id.frameA1)).setOnClickListener(buttonListener);
        (findViewById(R.id.frameA2)).setOnClickListener(buttonListener);
        (findViewById(R.id.frameA3)).setOnClickListener(buttonListener);
        (findViewById(R.id.frameA4)).setOnClickListener(buttonListener);

        btnDialogYes.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);

                if (CAN_CLICK) {
                    CAN_CLICK = false;
                    CAN_HOME = true;
                    rlyDialog.setVisibility(View.INVISIBLE);
                    switch (currentDialog) {
                        case "ConfirmAnswer":
                            rlyVotes.setVisibility(View.INVISIBLE);
                            btnCloseVote.setVisibility(View.INVISIBLE);
                            imgSelected.setImageResource(R.drawable.frame_final);

                            if (modeOnline) {
                                if (Data.isNetworkAvailable(GameActivity.this)) {
                                    stopTimer(false);
                                    CAN_PLAY = false;
                                    submitOnlineAnswer(getAnswerKeyForDisplayedIndex(myAnswer));
                                    rlySelected.getChildAt(2).setVisibility(View.VISIBLE);
                                    resolveOnlineRoundIfReady();
                                } else {
                                    Toast.makeText(GameActivity.this, "لا يوجد اتصال بالإنترنت", Toast.LENGTH_SHORT).show();
                                }
                            } else {
                                checkAnswer(false);
                            }
                            break;
                        case "ConfirmHelp5050":
                            usedHelp5050 = true;
                            help_hideTwoAnswers();
                            startTimer(false);
                            imgHelp5050.setTag("0");
                            imgHelp5050.setImageResource(R.drawable.help_5050_0);
                            break;
                        case "ConfirmHelpAudience":
                            usedHelpAudience = true;
                            stopTimer(true);
                            help_getVoteAudience();
                            imgHelpAudience.setTag("0");
                            imgHelpAudience.setImageResource(R.drawable.help_audience_0);
                            break;
                        case "ConfirmHelpCall":
                            usedHelpCall = true;
                            stopTimer(true);
                            help_call();
                            imgHelpCall.setTag("0");
                            imgHelpCall.setImageResource(R.drawable.help_call_0);
                            break;
                        case "ConfirmExtraHelp5050":
                            if (PlayerProgress.consumeInventory(GameActivity.this, "5050")) {
                                usedHelp5050 = true;
                                help_hideTwoAnswers();
                                startTimer(false);
                                updateInventoryBadges();
                                Toast.makeText(GameActivity.this, "تم استخدام 50:50 إضافية", Toast.LENGTH_SHORT).show();
                            }
                            break;
                        case "ConfirmExtraHelpAudience":
                            if (PlayerProgress.consumeInventory(GameActivity.this, "audience")) {
                                usedHelpAudience = true;
                                stopTimer(true);
                                help_getVoteAudience();
                                updateInventoryBadges();
                                Toast.makeText(GameActivity.this, "تم استخدام مساعدة جمهور إضافية", Toast.LENGTH_SHORT).show();
                            }
                            break;
                        case "ConfirmExtraHelpCall":
                            if (PlayerProgress.consumeInventory(GameActivity.this, "call")) {
                                usedHelpCall = true;
                                stopTimer(true);
                                help_call();
                                updateInventoryBadges();
                                Toast.makeText(GameActivity.this, "تم استخدام اتصال إضافي", Toast.LENGTH_SHORT).show();
                            }
                            break;
                        case "ConfirmHome":
                        case "ConfirmExit":
                            EXITING = true;
                            finishGame();
                            break;
                        case "OpponentLeftContinue":
                            continueMatchWithComputer();
                            break;
                        case "EliminationSpectatorChoice":
                            continueEliminationMatchAsSpectator();
                            break;
                        case "ConfirmRules":
                            person.moveShowHand(1000);
                            if (modeOnline)
                                showDialog("تتكون المباراة من 3 جولات\nكل جولة من 5 أسئلة", "Rules-1", 1000, -1, R.drawable.mouth_05, false);
                            else
                                showDialog("أمامك 15 سؤال نحو المليون", "Rules1", 1000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules-1":
                            showDialog("كل إجابة صحيحة تربح قيمتها من النقاط\nوكل إجابة خاطئة تساوي صفر", "Rules0", 1000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules0":
                            showDialog("من يفوز بجولتبن يربح المباراة", "Rules1", 1000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules1":
                            person.moveHead(600);
                            showDialog("لديك 30 ثانية لللإجابة عن كل سؤال", "Rules2", 1000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules2":
                            person.like(600);
                            person.raiseEyeBrowsUp(600, false, true);
                            showDialog("إذا لم تعرف الإجابة يمكنك استخدام إحدى وسائل المساعدة", "Rules3", 2000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules3":
                            showDialog("الوسيلة الأولى\nحذف إجابتين خاطئتين", "Rules4", 1000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules4":
                            showDialog("الوسيلة الثانية\nالاتصال بصديق", "Rules5", 1000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules5":
                            showDialog("الوسيلة الثالثة\nطلب رأي الجمهور", "Rules6", 1000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules6":
                            person.moveShowHand(1000);
                            showDialog("يمكنك في أي وقت الانسحاب والاكتفاء بالمبلغ الذي وصلت إليه", "Rules7", 2000, -1, R.drawable.mouth_05, false);
                            break;
                        case "Rules7":
                            playSound(R.raw.commerical_break, true, false);
                            startMatchFlow();
                    }
                }
            }
        });

        btnDialogNo.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);

                if (CAN_CLICK) {
                    CAN_CLICK = false;
                    CAN_HOME = true;
                    switch (currentDialog) {
                        case "ConfirmAnswer":
                            CAN_PLAY = true;
                            imgSelected.setImageResource(R.drawable.frame);
                            rlyDialog.setVisibility(View.INVISIBLE);
                            person.raiseShoulders();
                            person.moveHead(600);
                            showDialog("حاول مرة أخرى", "", 1000, 1000, R.drawable.mouth_05, true);
                            break;
                        case "ConfirmHelp5050":
                        case "ConfirmHelpAudience":
                        case "ConfirmHelpCall":
                        case "ConfirmExtraHelp5050":
                        case "ConfirmExtraHelpAudience":
                        case "ConfirmExtraHelpCall":
                            rlyDialog.setVisibility(View.INVISIBLE);
                            CAN_PLAY = true;
                            startTimer(false);
                            break;
                        case "ConfirmHome":
                        case "ConfirmExit":
                            CAN_HOME = true;
                            rlyDialog.setVisibility(View.INVISIBLE);
                            CAN_PLAY = true;
                            break;
                        case "OpponentLeftContinue":
                            markMyGameState("finished");
                            EXITING = true;
                            openOnlineResultScreen(true);
                            break;
                        case "EliminationSpectatorChoice":
                            exitEliminationMatchAfterDecliningSpectator();
                            break;
                        case "ConfirmRules":
                        case "Rules1":
                        case "Rules2":
                        case "Rules3":
                        case "Rules4":
                        case "Rules5":
                        case "Rules6":
                        case "Rules7":
                            startMatchFlow();
                            break;
                    }
                }
            }
        });


        imgHelp5050.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);
                if (CAN_PLAY) {
                    if (imgHelp5050.getTag().toString().equals("1")) {
                        stopTimer(true);
                        showDialog("هل تريد حذف إجابتين ؟", "ConfirmHelp5050", 2000, 0, R.drawable.mouth_05, false);
                    } else if (PlayerProgress.getInventory5050(GameActivity.this) > 0) {
                        stopTimer(true);
                        showDialog("استخدام 50:50 إضافية من المخزون؟", "ConfirmExtraHelp5050", 1500, 0, R.drawable.mouth_05, false);
                    }
                }
            }
        });


        imgHelpAudience.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);
                if (CAN_PLAY) {
                    if (imgHelpAudience.getTag().toString().equals("1")) {
                        stopTimer(true);
                        showDialog("هل تريد طلب مساعدة الجمهور ؟", "ConfirmHelpAudience", 2000, 0, R.drawable.mouth_05, false);
                    } else if (PlayerProgress.getInventoryAudience(GameActivity.this) > 0) {
                        stopTimer(true);
                        showDialog("استخدام مساعدة جمهور إضافية من المخزون؟", "ConfirmExtraHelpAudience", 1500, 0, R.drawable.mouth_05, false);
                    }
                }
            }
        });

        btnCloseVote.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);
                rlyVotes.setVisibility(View.INVISIBLE);
                btnCloseVote.setVisibility(View.INVISIBLE);
            }
        });


        imgHelpCall.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);
                if (CAN_PLAY) {
                    if (imgHelpCall.getTag().toString().equals("1")) {
                        stopTimer(true);
                        showDialog("هل تريد الاتصال بصديق ؟", "ConfirmHelpCall", 2000, 0, R.drawable.mouth_05, false);
                    } else if (PlayerProgress.getInventoryCall(GameActivity.this) > 0) {
                        stopTimer(true);
                        showDialog("استخدام اتصال إضافي من المخزون؟", "ConfirmExtraHelpCall", 1500, 0, R.drawable.mouth_05, false);
                    }
                }
            }
        });

        imgVolume.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);
                if (SOUND_ON) {
                    //mpSound.stop();
                    if (mpSound != null && !currentSoundIsMusic) mpSound.setVolume(0, 0);
                    SOUND_ON = false;
                    AppPrefs.setSoundEnabled(GameActivity.this, false);
                    imgVolume.setImageResource(R.drawable.muted);
                } else {
                    if (mpSound != null && !currentSoundIsMusic) mpSound.setVolume(1f, 1f);
                    SOUND_ON = true;
                    AppPrefs.setSoundEnabled(GameActivity.this, true);
                    imgVolume.setImageResource(R.drawable.volume);
                }
            }
        });

        View.OnClickListener getMoneyAndHome = new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                gameHaptic(view);
                if (CAN_HOME) {
                    CAN_HOME = false;
                    confirmExit();
                }
            }
        };

        imgHome.setOnClickListener(getMoneyAndHome);
        btnGetMoney.setOnClickListener(getMoneyAndHome);
    }

    private void applyVolumeUi() {
        if (imgVolume == null) return;
        if (SOUND_ON) {
            imgVolume.setImageResource(R.drawable.volume);
            if (mpSound != null && !currentSoundIsMusic) mpSound.setVolume(1f, 1f);
        } else {
            imgVolume.setImageResource(R.drawable.muted);
            if (mpSound != null && !currentSoundIsMusic) mpSound.setVolume(0f, 0f);
        }
        if (mpSound != null && currentSoundIsMusic && !MUSIC_ON) {
            stopSound(mpSound);
            mpSound = null;
        }
    }

    private void gameHaptic(View view) {
        if (view != null && AppPrefs.isHapticEnabled(this)) {
            view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);
        }
    }


    @Override
    protected void onResume() {
        super.onResume();
        SOUND_ON = AppPrefs.isSoundEnabled(this);
        MUSIC_ON = AppPrefs.isMusicEnabled(this);
        applyVolumeUi();
    }

    private void parseOpponentsFromIntent() {
        opponents.clear();
        String opponentsJson = getIntent().getStringExtra("opponentsJson");
        if (opponentsJson == null || opponentsJson.trim().isEmpty()) {
            opponentsJson = "[]";
        }

        try {
            JSONArray jsonArray = new JSONArray(opponentsJson);
            for (int i = 0; i < jsonArray.length(); i++) {
                JSONObject item = jsonArray.optJSONObject(i);
                if (item == null) {
                    continue;
                }
                MatchOpponent opponent = new MatchOpponent();
                opponent.id = safeString(item.optString("id"));
                opponent.name = safeDisplayName(item.optString("name"), opponents.size() + 1);
                opponent.photo = safeString(item.optString("photo"));
                opponent.level = Math.max(1, item.optInt("level", 1));
                opponent.intelligence = Math.max(0, item.optInt("intelligence", 0));
                opponent.score = Math.max(0, item.optInt("score", 0));
                opponent.bot = item.optBoolean("bot", false) || "fictitious".equals(opponent.id);
                if (opponent.bot) {
                    applyBotIdentity(opponent, false);
                }
                if (!opponent.id.isEmpty()) {
                    opponents.add(opponent);
                }
            }
        } catch (Exception ignored) {
        }

        if (opponents.isEmpty()) {
            MatchOpponent fallback = new MatchOpponent();
            fallback.id = "fictitious";
            fallback.bot = true;
            applyBotIdentity(fallback, false);
            opponents.add(fallback);
        }

        syncPrimaryOpponentFields();
    }

    private void syncPrimaryOpponentFields() {
        MatchOpponent primaryOpponent = getPrimaryOpponent();
        if (primaryOpponent == null) {
            opponentID = "fictitious";
            opponentName = "الكمبيوتر";
            opponentPhoto = "";
            opponentLevel = 1;
            opponentScore = 0;
            return;
        }
        opponentID = primaryOpponent.id;
        opponentName = primaryOpponent.name;
        opponentPhoto = primaryOpponent.photo;
        opponentLevel = primaryOpponent.level;
        opponentScore = primaryOpponent.score;
    }

    private MatchOpponent getPrimaryOpponent() {
        if (opponents.isEmpty()) {
            return null;
        }
        return opponents.get(0);
    }

    private ArrayList<String> getOpponentIds() {
        ArrayList<String> ids = new ArrayList<>();
        for (MatchOpponent opponent : opponents) {
            if (opponent.id != null && !opponent.id.trim().isEmpty()) {
                ids.add(opponent.id);
            }
        }
        return ids;
    }

    private void buildOpponentPanels() {
        if (!modeOnline) {
            return;
        }
        configureScoreboardLayout();
        txtPlayer1.setText(myName);
        Data.setImageSource(this, imgPlayer1, myPhoto);
        llyPlayer1.setVisibility(View.GONE);
        View scrollOpponents = findViewById(R.id.scrollOpponents);
        if (scrollOpponents != null) {
            scrollOpponents.setVisibility(View.GONE);
        }
        if (llyOpponents != null) {
            llyOpponents.removeAllViews();
        }
        if (llyOpponentScores != null) {
            llyOpponentScores.removeAllViews();
        }
        clearOpponentAnswerThumbs();

        for (MatchOpponent opponent : opponents) {
            if (llyOpponents != null) {
                llyOpponents.addView(createOpponentTopCard(opponent));
            }
            if (llyOpponentScores != null) {
                llyOpponentScores.addView(createOpponentScoreRow(opponent));
            }
            for (LinearLayout container : opponentAnswerContainers) {
                CircleImageView thumbView = createAnswerThumbView(container.getChildCount() > 0);
                container.addView(thumbView);
                opponent.answerThumbViews.add(thumbView);
            }
        }

        rlyScore.setVisibility(View.VISIBLE);
        refreshOpponentPanels();
    }

    private void configureScoreboardLayout() {
        if (!modeOnline || rlyScore == null) {
            return;
        }

        final int totalPlayers = 1 + opponents.size();
        final DisplayMetrics metrics = getResources().getDisplayMetrics();
        final float screenHeightDp = metrics.heightPixels / metrics.density;
        final int scoreboardBudgetDp = Math.max(220, Math.round(screenHeightDp * 0.54f));
        final boolean compact = totalPlayers >= 6;
        final boolean ultraCompact = totalPlayers >= 9;

        scoreboardPanelWidthDp = ultraCompact ? 228 : (compact ? 242 : 270);
        scoreboardHeaderHeightDp = ultraCompact ? 22 : (compact ? 24 : 28);
        final int calculatedRowHeight = (scoreboardBudgetDp - scoreboardHeaderHeightDp - 10) / Math.max(1, totalPlayers);
        scoreboardRowHeightDp = Math.max(22, Math.min(48, calculatedRowHeight));
        scoreboardAvatarColumnWidthDp = scoreboardRowHeightDp <= 26 ? 30 : (scoreboardRowHeightDp <= 32 ? 34 : (ultraCompact ? 36 : (compact ? 40 : 44)));
        scoreboardAvatarSizeDp = Math.max(18, Math.min(28, scoreboardRowHeightDp - 12));
        scoreboardAvatarBorderDp = ultraCompact ? 1 : 2;
        scoreboardHorizontalPaddingDp = scoreboardRowHeightDp <= 26 ? 3 : (ultraCompact ? 4 : 6);
        scoreboardHeaderTextSp = scoreboardRowHeightDp <= 26 ? 8.5f : (ultraCompact ? 9f : (compact ? 10f : 11f));
        scoreboardNameTextSp = scoreboardRowHeightDp <= 26 ? 6.2f : (scoreboardRowHeightDp <= 30 ? 6.8f : (ultraCompact ? 7f : (compact ? 7.5f : 8f)));
        scoreboardValueTextSp = scoreboardRowHeightDp <= 26 ? 10f : (scoreboardRowHeightDp <= 30 ? 11f : (ultraCompact ? 11.5f : (compact ? 12.5f : 14f)));

        ViewGroup.LayoutParams panelParams = rlyScore.getLayoutParams();
        panelParams.width = dp(scoreboardPanelWidthDp);
        rlyScore.setLayoutParams(panelParams);

        if (scoreHeaderRow != null) {
            LinearLayout.LayoutParams headerParams =
                    (LinearLayout.LayoutParams) scoreHeaderRow.getLayoutParams();
            headerParams.height = dp(scoreboardHeaderHeightDp);
            scoreHeaderRow.setLayoutParams(headerParams);
            scoreHeaderRow.setPadding(
                    dp(scoreboardHorizontalPaddingDp),
                    0,
                    dp(scoreboardHorizontalPaddingDp),
                    0
            );

            for (int i = 0; i < scoreHeaderRow.getChildCount(); i++) {
                View child = scoreHeaderRow.getChildAt(i);
                if (child instanceof TextView) {
                    ((TextView) child).setTextSize(TypedValue.COMPLEX_UNIT_SP, scoreboardHeaderTextSp);
                }
            }
            View starCell = scoreHeaderRow.getChildAt(0);
            LinearLayout.LayoutParams starParams = (LinearLayout.LayoutParams) starCell.getLayoutParams();
            starParams.width = dp(scoreboardAvatarColumnWidthDp);
            starCell.setLayoutParams(starParams);
        }

        if (scoreMeRow != null) {
            LinearLayout.LayoutParams myRowParams =
                    (LinearLayout.LayoutParams) scoreMeRow.getLayoutParams();
            myRowParams.height = dp(scoreboardRowHeightDp);
            scoreMeRow.setLayoutParams(myRowParams);
            scoreMeRow.setPadding(
                    dp(scoreboardHorizontalPaddingDp),
                    dp(2),
                    dp(scoreboardHorizontalPaddingDp),
                    dp(2)
            );

            View identityCol = scoreMeRow.getChildAt(0);
            if (identityCol instanceof LinearLayout) {
                LinearLayout identityLayout = (LinearLayout) identityCol;
                LinearLayout.LayoutParams identityParams =
                        (LinearLayout.LayoutParams) identityLayout.getLayoutParams();
                identityParams.width = dp(scoreboardAvatarColumnWidthDp);
                identityLayout.setLayoutParams(identityParams);

                View avatarView = identityLayout.getChildAt(0);
                if (avatarView instanceof CircleImageView) {
                    CircleImageView avatar = (CircleImageView) avatarView;
                    LinearLayout.LayoutParams avatarParams =
                            (LinearLayout.LayoutParams) avatar.getLayoutParams();
                    avatarParams.width = dp(scoreboardAvatarSizeDp);
                    avatarParams.height = dp(scoreboardAvatarSizeDp);
                    avatar.setLayoutParams(avatarParams);
                    avatar.setBorderWidth(dp(scoreboardAvatarBorderDp));
                }

                View nameView = identityLayout.getChildAt(1);
                if (nameView instanceof TextView) {
                    TextView nameText = (TextView) nameView;
                    LinearLayout.LayoutParams nameParams =
                            (LinearLayout.LayoutParams) nameText.getLayoutParams();
                    nameParams.width = dp(scoreboardAvatarColumnWidthDp);
                    nameText.setLayoutParams(nameParams);
                    nameText.setTextSize(TypedValue.COMPLEX_UNIT_SP, scoreboardNameTextSp);
                }
            }

            styleScoreValueCell(txtScoreMe, getResources().getColor(android.R.color.white));
            styleScoreValueCell(txtScoreGameMe, getResources().getColor(R.color.lightBlueApp));
            if (txtSetsMe != null) {
                styleStateCell(txtSetsMe, localPlayerEliminated);
            }
        }

        if (labScore != null) {
            labScore.setTextSize(TypedValue.COMPLEX_UNIT_SP, scoreboardHeaderTextSp);
        }
        if (labSets != null) {
            labSets.setTextSize(TypedValue.COMPLEX_UNIT_SP, scoreboardHeaderTextSp);
        }
        if (labScoreGame != null) {
            labScoreGame.setTextSize(TypedValue.COMPLEX_UNIT_SP, scoreboardHeaderTextSp);
        }

        if (llyOpponentScores != null) {
            ViewGroup.LayoutParams rowsParams = llyOpponentScores.getLayoutParams();
            rowsParams.height = ViewGroup.LayoutParams.WRAP_CONTENT;
            llyOpponentScores.setLayoutParams(rowsParams);
        }
    }

    private void styleScoreValueCell(TextView textView, int color) {
        if (textView == null) {
            return;
        }
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) textView.getLayoutParams();
        params.height = ViewGroup.LayoutParams.MATCH_PARENT;
        textView.setLayoutParams(params);
        textView.setTextColor(color);
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, scoreboardValueTextSp);
    }

    private void configureAnswerTextSizing() {
        for (TextView answerView : new TextView[]{txtA1, txtA2, txtA3, txtA4}) {
            if (answerView == null) {
                continue;
            }
            answerView.setHorizontallyScrolling(false);
            TextViewCompat.setAutoSizeTextTypeUniformWithConfiguration(
                    answerView,
                    8,
                    14,
                    1,
                    TypedValue.COMPLEX_UNIT_SP
            );
        }
    }

    private void configureGameSurfaceLayout() {
        final DisplayMetrics metrics = getResources().getDisplayMetrics();
        final float screenWidthDp = metrics.widthPixels / metrics.density;
        final float screenHeightDp = metrics.heightPixels / metrics.density;
        final boolean shortScreen = screenHeightDp < 390f;
        final boolean narrowScreen = screenWidthDp < 760f;

        if (llyQA != null) {
            int targetWidthDp = modeOnline
                    ? Math.round(screenWidthDp * (shortScreen ? 0.46f : 0.48f))
                    : Math.round(screenWidthDp * (shortScreen ? 0.50f : 0.54f));
            targetWidthDp = Math.max(shortScreen ? 360 : 390, Math.min(450, targetWidthDp));
            ViewGroup.LayoutParams params = llyQA.getLayoutParams();
            params.width = dp(targetWidthDp);
            llyQA.setLayoutParams(params);
        }

        if (txtQ != null) {
            txtQ.setSingleLine(false);
            txtQ.setMaxLines(2);
            txtQ.setIncludeFontPadding(false);
            TextViewCompat.setAutoSizeTextTypeUniformWithConfiguration(
                    txtQ,
                    10,
                    shortScreen ? 16 : 18,
                    1,
                    TypedValue.COMPLEX_UNIT_SP
            );
        }

        final int toolSizeDp = shortScreen || narrowScreen ? 42 : 50;
        resizeSquareView(imgHelp5050, toolSizeDp);
        resizeSquareView(imgHelpCall, toolSizeDp);
        resizeSquareView(imgHelpAudience, toolSizeDp);
        resizeSquareView(imgVolume, toolSizeDp);
        resizeSquareView(imgHome, toolSizeDp);
        resizeSquareView(rlyProgress, shortScreen ? 44 : 50);

        if (txtProgress != null) {
            txtProgress.setTextSize(TypedValue.COMPLEX_UNIT_SP, shortScreen ? 17 : 20);
            txtProgress.setIncludeFontPadding(false);
        }
    }

    private void resizeSquareView(View view, int sizeDp) {
        if (view == null) {
            return;
        }
        ViewGroup.LayoutParams params = view.getLayoutParams();
        params.width = dp(sizeDp);
        params.height = dp(sizeDp);
        view.setLayoutParams(params);
    }

    private boolean isShortGameScreen() {
        final DisplayMetrics metrics = getResources().getDisplayMetrics();
        return metrics.heightPixels / metrics.density < 390f;
    }

    private void applyQuestionTextSize(String text) {
        if (txtQ == null) {
            return;
        }
        final int qLen = text == null ? 0 : text.length();
        final boolean shortScreen = isShortGameScreen();
        final float sizeSp;
        if (qLen <= 60) {
            sizeSp = shortScreen ? 16f : 18f;
        } else if (qLen <= 90) {
            sizeSp = shortScreen ? 14f : 15f;
        } else if (qLen <= 130) {
            sizeSp = shortScreen ? 12.5f : 13f;
        } else {
            sizeSp = shortScreen ? 10.5f : 11f;
        }
        txtQ.setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp);
    }

    private void applyAnswerTextSize(TextView answerView, String text) {
        if (answerView == null) {
            return;
        }
        final int aLen = text == null ? 0 : text.length();
        final boolean shortScreen = isShortGameScreen();
        final float sizeSp;
        if (aLen <= 20) {
            sizeSp = shortScreen ? 13f : 14f;
        } else if (aLen <= 30) {
            sizeSp = shortScreen ? 11.5f : 12f;
        } else if (aLen <= 45) {
            sizeSp = shortScreen ? 9.5f : 10f;
        } else {
            sizeSp = 8f;
        }
        answerView.setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp);
    }

    private void styleStateCell(TextView textView, boolean eliminated) {
        if (textView == null) {
            return;
        }

        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) textView.getLayoutParams();
        final int verticalInsetDp = Math.max(1, Math.min(5, (scoreboardRowHeightDp - 16) / 3));
        params.height = eliminationMode ? dp(Math.max(16, scoreboardRowHeightDp - (verticalInsetDp * 2))) : ViewGroup.LayoutParams.MATCH_PARENT;
        params.topMargin = eliminationMode ? dp(verticalInsetDp) : 0;
        params.bottomMargin = eliminationMode ? dp(verticalInsetDp) : 0;
        params.leftMargin = eliminationMode ? dp(2) : 0;
        params.rightMargin = eliminationMode ? dp(2) : 0;
        textView.setLayoutParams(params);
        textView.setTextSize(TypedValue.COMPLEX_UNIT_SP, eliminationMode ? (scoreboardValueTextSp - 1f) : scoreboardValueTextSp);

        if (!eliminationMode) {
            textView.setTextColor(getResources().getColor(R.color.stepSelected));
            textView.setBackground(null);
            return;
        }

        GradientDrawable drawable = new GradientDrawable();
        drawable.setCornerRadius(dp(12));
        if (eliminated) {
            drawable.setColor(android.graphics.Color.parseColor("#33B91C1C"));
            drawable.setStroke(dp(1), android.graphics.Color.parseColor("#F87171"));
            textView.setTextColor(android.graphics.Color.parseColor("#FECACA"));
        } else {
            drawable.setColor(android.graphics.Color.parseColor("#1A0EA5E9"));
            drawable.setStroke(dp(1), android.graphics.Color.parseColor("#7DD3FC"));
            textView.setTextColor(android.graphics.Color.parseColor("#E0F2FE"));
        }
        textView.setBackground(drawable);
    }

    private View createOpponentTopCard(MatchOpponent opponent) {
        LinearLayout card = new LinearLayout(this);
        card.setOrientation(LinearLayout.VERTICAL);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(dp(84), ViewGroup.LayoutParams.WRAP_CONTENT);
        params.setMargins(dp(6), 0, dp(6), 0);
        card.setLayoutParams(params);

        CircleImageView imageView = new CircleImageView(this);
        LinearLayout.LayoutParams imageParams = new LinearLayout.LayoutParams(dp(64), dp(64));
        imageParams.gravity = android.view.Gravity.CENTER_HORIZONTAL;
        imageView.setLayoutParams(imageParams);
        imageView.setBorderWidth(dp(2));
        imageView.setBorderColor(getResources().getColor(R.color.player2));
        Data.setImageSource(this, imageView, opponent.photo);

        TextView nameView = new TextView(this);
        nameView.setLayoutParams(new LinearLayout.LayoutParams(ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT));
        nameView.setTextColor(getResources().getColor(android.R.color.white));
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
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setGravity(android.view.Gravity.CENTER_VERTICAL);
        row.setPadding(dp(scoreboardHorizontalPaddingDp), dp(2), dp(scoreboardHorizontalPaddingDp), dp(2));
        row.setLayoutParams(new LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                dp(scoreboardRowHeightDp)
        ));

        // Avatar + name column
        LinearLayout avatarCol = new LinearLayout(this);
        avatarCol.setOrientation(LinearLayout.VERTICAL);
        avatarCol.setGravity(android.view.Gravity.CENTER_HORIZONTAL);
        avatarCol.setLayoutParams(new LinearLayout.LayoutParams(
                dp(scoreboardAvatarColumnWidthDp),
                ViewGroup.LayoutParams.MATCH_PARENT
        ));

        CircleImageView imageView = new CircleImageView(this);
        LinearLayout.LayoutParams imageParams = new LinearLayout.LayoutParams(
                dp(scoreboardAvatarSizeDp),
                dp(scoreboardAvatarSizeDp)
        );
        imageParams.setMargins(0, dp(1), 0, dp(1));
        imageView.setLayoutParams(imageParams);
        imageView.setBorderWidth(dp(scoreboardAvatarBorderDp));
        imageView.setBorderColor(getResources().getColor(R.color.player2));
        Data.setImageSource(this, imageView, opponent.photo);

        TextView nameLabel = new TextView(this);
        nameLabel.setLayoutParams(new LinearLayout.LayoutParams(
                dp(scoreboardAvatarColumnWidthDp),
                ViewGroup.LayoutParams.WRAP_CONTENT
        ));
        nameLabel.setGravity(android.view.Gravity.CENTER);
        nameLabel.setTextColor(android.graphics.Color.WHITE);
        nameLabel.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, scoreboardNameTextSp);
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
        TextView textView = new TextView(this);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.MATCH_PARENT,
                1f
        );
        textView.setLayoutParams(params);
        textView.setGravity(android.view.Gravity.CENTER);
        textView.setTextColor(getResources().getColor(android.R.color.white));
        textView.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, scoreboardValueTextSp);
        textView.setTypeface(null, android.graphics.Typeface.BOLD);
        textView.setText("0");
        return textView;
    }

    private TextView createSetsCell() {
        TextView textView = new TextView(this);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                0,
                eliminationMode ? dp(Math.max(26, scoreboardRowHeightDp - 12)) : ViewGroup.LayoutParams.MATCH_PARENT,
                1f
        );
        if (eliminationMode) {
            params.setMargins(dp(2), dp(5), dp(2), dp(5));
        }
        textView.setLayoutParams(params);
        textView.setGravity(android.view.Gravity.CENTER);
        textView.setTextColor(getResources().getColor(R.color.stepSelected));
        textView.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP,
                eliminationMode ? (scoreboardValueTextSp - 1f) : scoreboardValueTextSp);
        textView.setTypeface(null, android.graphics.Typeface.BOLD);
        textView.setText("0");
        return textView;
    }

    private TextView createGameScoreCell() {
        TextView textView = new TextView(this);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(
                0,
                ViewGroup.LayoutParams.MATCH_PARENT,
                1f
        );
        textView.setLayoutParams(params);
        textView.setGravity(android.view.Gravity.CENTER);
        textView.setTextColor(getResources().getColor(R.color.lightBlueApp));
        textView.setTextSize(android.util.TypedValue.COMPLEX_UNIT_SP, scoreboardValueTextSp);
        textView.setTypeface(null, android.graphics.Typeface.BOLD);
        textView.setText("0");
        return textView;
    }

    private CircleImageView createAnswerThumbView(boolean overlapPrevious) {
        CircleImageView imageView = new CircleImageView(this);
        LinearLayout.LayoutParams params = new LinearLayout.LayoutParams(dp(14), dp(14));
        params.setMargins(overlapPrevious ? dp(-9) : 0, dp(1), 0, dp(1));
        imageView.setLayoutParams(params);
        imageView.setBorderWidth(dp(1));
        imageView.setBorderColor(getResources().getColor(R.color.player2));
        imageView.setVisibility(View.INVISIBLE);
        return imageView;
    }

    private void clearOpponentAnswerThumbs() {
        for (LinearLayout container : opponentAnswerContainers) {
            container.removeAllViews();
        }
        for (MatchOpponent opponent : opponents) {
            opponent.answerThumbViews.clear();
        }
    }

    private void refreshOpponentPanels() {
        for (MatchOpponent opponent : opponents) {
            if (opponent.topNameView != null) {
                opponent.topNameView.setText(opponent.name);
                opponent.topNameView.setAlpha(opponent.eliminated ? 0.45f : 1f);
            }
            if (opponent.topImageView != null) {
                Data.setImageSource(this, opponent.topImageView, opponent.photo);
                updatePlayerVisualState(opponent.topImageView, opponent.eliminated);
            }
            if (opponent.scoreImageView != null) {
                Data.setImageSource(this, opponent.scoreImageView, opponent.photo);
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
                opponent.setsView.setText(eliminationMode
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
                Data.setImageSource(this, thumbView, opponent.photo);
                thumbView.setVisibility(View.INVISIBLE);
            }
        }
        refreshMePanelState();
    }

    private boolean allOpponentsSubmitted() {
        for (MatchOpponent opponent : opponents) {
            if (!opponent.eliminated && !opponent.submitted) {
                return false;
            }
        }
        return true;
    }

    private void autoSubmitSpectatorEliminationRound() {
        if (!modeOnline || !eliminationMode || !spectatorEliminationRound || myAnswerSubmitted) {
            return;
        }
        CAN_PLAY = false;
        final int questionIndex = currentQuestion;
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                if (EXITING || currentQuestion != questionIndex || myAnswerSubmitted) {
                    return;
                }
                submitOnlineAnswer(0);
                resolveOnlineRoundIfReady();
            }
        }, 150);
    }

    private boolean hasBotOpponents() {
        for (MatchOpponent opponent : opponents) {
            if (opponent.bot && !opponent.eliminated) {
                return true;
            }
        }
        return false;
    }

    private void refreshMePanelState() {
        updatePlayerVisualState(imgMe, localPlayerEliminated);
        if (txtMeName != null) txtMeName.setAlpha(localPlayerEliminated ? 0.45f : 1f);
        if (txtScoreMe != null) txtScoreMe.setAlpha(localPlayerEliminated ? 0.45f : 1f);
        if (txtScoreGameMe != null) txtScoreGameMe.setAlpha(localPlayerEliminated ? 0.45f : 1f);
        if (txtSetsMe != null) {
            txtSetsMe.setAlpha(localPlayerEliminated ? 0.45f : 1f);
            if (eliminationMode) {
                txtSetsMe.setText(localPlayerEliminated ? "خارج" : "نشط");
            }
            styleStateCell(txtSetsMe, localPlayerEliminated);
        }
    }

    private void updatePlayerVisualState(ImageView view, boolean eliminated) {
        if (view == null) {
            return;
        }
        if (eliminated) {
            setGreyscale(view);
            view.setImageAlpha(140);
        } else {
            setColored(view);
            view.setImageAlpha(255);
        }
    }

    private MatchOpponent findOpponentById(String playerId) {
        for (MatchOpponent opponent : opponents) {
            if (opponent.id.equals(playerId)) {
                return opponent;
            }
        }
        return null;
    }

    private int dp(int value) {
        return Math.round(getResources().getDisplayMetrics().density * value);
    }

    private String safeDisplayName(String name, int index) {
        String resolved = safeString(name).trim();
        if (resolved.isEmpty()) {
            return index <= 1
                    ? "خصم آلي"
                    : String.format(Locale.getDefault(), "خصم آلي %d", index);
        }
        return resolved;
    }

    private BotProfile resolveBotProfile(String playerId) {
        // Bot IDs follow: "bot_room_ROOMID_SLOT" where SLOT starts at 1
        // Use SLOT for sequential (non-repeating) profile assignment
        if (playerId != null) {
            String[] parts = playerId.split("_");
            if (parts.length >= 1) {
                try {
                    int slot = Integer.parseInt(parts[parts.length - 1]) - 1;
                    if (slot >= 0 && slot < BOT_PROFILES.length) {
                        return BOT_PROFILES[slot];
                    }
                } catch (NumberFormatException ignored) {}
            }
        }
        int seed = Math.abs(stableHash(playerId));
        return BOT_PROFILES[seed % BOT_PROFILES.length];
    }

    private void applyBotIdentity(MatchOpponent opponent, boolean replacingHuman) {
        if (opponent == null) {
            return;
        }
        BotProfile profile = resolveBotProfile(opponent.id);
        opponent.bot = true;
        opponent.name = profile.name;
        opponent.photo = profile.photo;
        opponent.intelligence = profile.intelligence;
        opponent.level = Math.max(1, opponent.intelligence / 10);
        if (replacingHuman) {
            Toast.makeText(
                    this,
                    opponent.name + " يتابع اللعب الآن كخصم آلي",
                    Toast.LENGTH_SHORT
            ).show();
        }
    }

    private int getFictitiousRandomTime() {
        int res = 5;
        switch (questions.get(currentQuestion).Level) {
            case "0":
                res = (new Random()).nextInt(3) + 1;
                break;
            case "1":
                res = (new Random()).nextInt(3) + 4;
                break;
            case "2":
                res = (new Random()).nextInt(6) + 7;
                break;
            case "3":
                res = (new Random()).nextInt(8) + 13;
                break;
        }
        return 30 - res;
    }

    private int getFictitiousRandomAnswer() {
        int res = 1;
        int x = (new Random()).nextInt(10) + 1;
        switch (questions.get(currentQuestion).Level) {
            case "0":
                res = rightAnswer;
                break;
            case "1":
                if (x < 9)
                    res = rightAnswer;
                else
                    res = getWrongAnswer(rightAnswer);
                break;
            case "2":
                if (x < 6)
                    res = rightAnswer;
                else
                    res = getWrongAnswer(rightAnswer);
                break;
            case "3":
                if (x < 4)
                    res = rightAnswer;
                else
                    res = getWrongAnswer(rightAnswer);
                break;
        }
        return res;
    }

    private int getBotDelayMillis(MatchOpponent opponent) {
        int intel = opponent.intelligence; // 0-100

        // Phase 1 (Q1-5, idx 0-4):  smart=5.3s  dumb=10.4s  → base=4835 + (100-intel)*93
        // Phase 2 (Q6-10, idx 5-9): smart=7.8s  dumb=15.4s  → base=7110 + (100-intel)*138
        // Phase 3 (Q11-15, idx 10+): smart=9.3s dumb=25.4s  → base=7835 + (100-intel)*293
        int baseMs;
        if (currentQuestion < 5) {
            baseMs = 4835 + (100 - intel) * 93;
        } else if (currentQuestion < 10) {
            baseMs = 7110 + (100 - intel) * 138;
        } else {
            baseMs = 7835 + (100 - intel) * 293;
        }

        // Difficulty of the current question adds extra thinking time
        String level = "0";
        if (currentQuestion >= 0 && currentQuestion < questions.size()) {
            level = questions.get(currentQuestion).Level;
        }
        switch (level) {
            case "1": baseMs += 400;  break;
            case "2": baseMs += 1000; break;
            case "3": baseMs += 2200; break;
        }

        // Deterministic personality seed (consistent per bot+question across games)
        int seed = Math.abs(stableHash(opponent.id + "|q" + currentQuestion));
        baseMs += (seed % 600) - 300; // ±300ms stable character offset

        // Human-like random jitter ±350ms — different every game
        baseMs += new Random().nextInt(700) - 350;

        // Rare hesitation (8% chance): bot second-guesses itself +1-3 extra seconds
        if (new Random().nextInt(100) < 8) {
            baseMs += 1000 + new Random().nextInt(2000);
        }

        // Never answer in the first 900ms (too inhuman)
        baseMs = Math.max(900, baseMs);

        // Never run out of time (stop 3 seconds before timer ends)
        int remainingMs = Math.max(1500, ((PROGRESS_VALUE / 10) - 3) * 1000);
        return Math.min(remainingMs, baseMs);
    }

    private int getBotDisplayedAnswer(MatchOpponent opponent) {
        int levelPenalty = 0;
        switch (questions.get(currentQuestion).Level) {
            case "1": levelPenalty = 8;  break;
            case "2": levelPenalty = 18; break;
            case "3": levelPenalty = 26; break;
            default:  levelPenalty = 0;  break;
        }
        int successChance = Math.max(20, Math.min(97, opponent.intelligence - levelPenalty));
        // Mix 80% stable hash (consistent character) + 20% random (human unpredictability)
        int stablePart = Math.abs(stableHash(opponent.id + "|" + currentQuestion)) % 80;
        int randomPart = new Random().nextInt(20);
        int roll = (stablePart + randomPart) % 100;
        return roll < successChance ? rightAnswer : getWrongAnswer(rightAnswer);
    }

    private int getWrongAnswer(int rightAnswer) {
        int res;
        do {
            res = (new Random()).nextInt(4) + 1;
        } while (res == rightAnswer);
        return res;
    }

    private void checkAnswer(final boolean timeout) {
        final int amount = modeOnline ? 0 : Integer.parseInt(getCurrentStepAmount().replace("$", ""));
        if (!timeout) {
            stopTimer(false);
            playSound(R.raw.drum1, false, true);
            FAST_LIGHTS = true;
        }
        CAN_HOME = true;
        final Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            int t = 0;

            @Override
            public void run() {
                t++;
                switch (t) {
                    case 1:
                        FAST_LIGHTS = false;
                        T_LIGHTS = 3;
                        if (modeOnline) {
                            applyOnlineRoundMetrics();
                            if (handleLocalTimeoutRemovalIfNeeded()) {
                                return;
                            }
                            if (eliminationMode && spectatorEliminationRound) {
                                t = 2;
                                handler.postDelayed(this, 400);
                                break;
                            }
                        }
                        if (!timeout) {
                            if (myAnswer == rightAnswer) {
                                imgSelected.setImageResource(R.drawable.frame_right);
                                PlayerStats.recordCorrectAnswer(GameActivity.this);
                                person.like(1000);
                                playSound(R.raw.correct_answer, false, false);
                                showDialog("الجواب صحيح", "", 1000, 2000, R.drawable.mouth_01, false);
                                if (modeOnline) {
                                    t = 2;
                                }
                                handler.postDelayed(this, 3000);
                            } else {
                                onWrongAnswer(false);
                                if (modeOnline) {
                                    t = 2;
                                    handler.postDelayed(this, 3000);
                                }
                            }
                        } else {
                            onWrongAnswer(true);
                            if (modeOnline) {
                                t = 2;
                                handler.postDelayed(this, 3000);
                            }
                        }
                        break;
                    case 2:
                        Animations.move(llyQA, 1000, 0, -140, 0, 0);
                        Animations.move(llySteps, 1000, 0, -360, 0, 0);
                        String currentStepDialog = getCurrentStepAmount();
                        if (modeOnline) {
                            txtAmount.setText(gameScoreMe + "");
                        } else {
                            txtAmount.setText(currentStepDialog);
                        }
                        if (eliminationMode) {
                            if (spectatorEliminationRound) {
                                handler.postDelayed(this, 500);
                                break;
                            }
                            if (mySubmittedAnswerKey == ANSWER_KEY_RIGHT) {
                                person.moveShowScreen(2000);
                                person.lookAside(1000);
                                showDialog("إجابة صحيحة، ونقاطك الآن " + gameScoreMe, "", 1000, 2000, R.drawable.mouth_01, false);
                            } else {
                                handler.postDelayed(this, 500);
                                CAN_HOME = true;
                                break;
                            }
                            CAN_HOME = true;
                            handler.postDelayed(this, 3000);
                            break;
                        } else if (currentQuestion == 14) {
                            person.moveShow2Hands(2000);
                            person.raiseEyeBrowsUp(2000, true, true);
                            showDialog("ألف مبروك\n لقد فزت بالمليون", "", 2000, 2000, R.drawable.mouth_01, false);
                            CAN_HOME = false;
                        } else {
                            person.moveShowScreen(2000);
                            person.lookAside(1000);
                            showDialog("أصبح رصيدك الآن\n" + currentStepDialog, "", 1000, 2000, R.drawable.mouth_01, false);
                            CAN_HOME = true;
                        }
                        handler.postDelayed(this, 3000);
                        break;
                    case 3:
                        if (modeOnline) {
                            if (eliminationMode) {
                                myResult = handleEliminationRoundProgress();
                                if (myResult == -3) {
                                    return;
                                }
                                if (myResult != -2) t = 6;
                                handler.postDelayed(this, 3000);
                            } else if (checkScoresMulti()) {
                                myResult = checkEndOfGameMulti();
                                if (myResult != -2) t = 6;
                                handler.postDelayed(this, 3000);
                            } else {
                                handler.postDelayed(this, 1000);
                            }
                        } else {
                            if (currentQuestion == 14) {
                                goToWinnerScreen("1000000$");
                            } else {
                                if (currentQuestion == 4) {
                                    person.like(1000);
                                    person.raiseEyeBrowsUp(1000, false, true);
                                    showDialog("ممتاز.. لقد ضمنت الآن مبلغ 1000$ حتى لو خسرت", "", 2000, 3000, R.drawable.mouth_01, false);
                                } else if (currentQuestion == 9) {
                                    person.like(1000);
                                    person.raiseEyeBrowsUp(1000, false, true);
                                    showDialog("ممتاز.. لقد ضمنت الآن مبلغ 32000$ حتى لو خسرت", "", 2000, 3000, R.drawable.mouth_01, false);
                                }
                                handler.postDelayed(this, 3000);
                            }
                        }
                        break;
                    case 4:
                        initQuestion();
                        nextStep();
                        playSound(R.raw.lets_play, true, false);
                        String currentStepAmount = getCurrentStepAmount();
                        person.moveHead(1000);
                        person.lookAside(600);
                        showDialog("السؤال التالي قيمته\n" + currentStepAmount, "", 1000, 3000, R.drawable.mouth_02, false);
                        CAN_HOME = true;
                        if (modeOnline) t++;
                        handler.postDelayed(this, 4000);
                        break;
                    case 5:
                        Animations.move(llyQA, 1000, -140, 0, 0, 0);
                        Animations.move(llySteps, 1000, -360, 0, 0, 0);
                        handler.postDelayed(this, 1000);
                        break;
                    case 6:
                        if (modeOnline) {
                            requestSynchronizedQuestion(currentQuestion + 1);
                        } else {
                            nextQuestion();
                        }
                        break;
                    case 7:
                        if (modeOnline) {
                            openOnlineResultScreen(false);
                        }
                        break;
                }
            }
        };
        int delayDrum;
        if (timeout) {
            delayDrum = 100;
        } else {
            delayDrum = (currentQuestion < 5) ? 3000 : ((currentQuestion < 10) ? 6000 : 9000);
         }
        handler.postDelayed(runnable, delayDrum);
    }

    private void applyOnlineRoundMetrics() {
        if (eliminationMode) {
            if (!spectatorEliminationRound && mySubmittedAnswerKey == ANSWER_KEY_RIGHT) {
                setScoreMe += 1;
                mySetCorrectAnswers++;
                myTotalCorrectAnswers++;
            }
            if (!spectatorEliminationRound) {
                if (myRoundPoints > 0) {
                    gameScoreMe += myRoundPoints;
                }
                mySetAnswerTimeMs += myAnswerElapsedMs;
                myTotalAnswerTimeMs += myAnswerElapsedMs;
            }

            for (MatchOpponent opponent : opponents) {
                if (opponent.eliminated) {
                    continue;
                }
                if (opponent.submittedAnswerKey == ANSWER_KEY_RIGHT) {
                    opponent.roundScore += 1;
                    opponent.setCorrectAnswers++;
                    opponent.totalCorrectAnswers++;
                }
                if (opponent.roundPoints > 0) {
                    opponent.gameScore += opponent.roundPoints;
                }
                opponent.setAnswerTimeMs += opponent.answerElapsedMs;
                opponent.totalAnswerTimeMs += opponent.answerElapsedMs;
            }

            txtScoreMe.setText(setScoreMe + "");
            txtScoreGameMe.setText(gameScoreMe + "");
            refreshOpponentPanels();
            return;
        }

        if (myRoundPoints > 0) {
            setScoreMe += myRoundPoints;
            gameScoreMe += myRoundPoints;
        }
        if (mySubmittedAnswerKey == ANSWER_KEY_RIGHT) {
            mySetCorrectAnswers++;
            myTotalCorrectAnswers++;
        }
        mySetAnswerTimeMs += myAnswerElapsedMs;
        myTotalAnswerTimeMs += myAnswerElapsedMs;
        myTimeoutStreak = mySubmittedAnswerKey == 0 ? myTimeoutStreak + 1 : 0;

        for (MatchOpponent opponent : opponents) {
            if (opponent.roundPoints > 0) {
                opponent.roundScore += opponent.roundPoints;
                opponent.gameScore += opponent.roundPoints;
            }
            if (opponent.submittedAnswerKey == ANSWER_KEY_RIGHT) {
                opponent.setCorrectAnswers++;
                opponent.totalCorrectAnswers++;
            }
            opponent.setAnswerTimeMs += opponent.answerElapsedMs;
            opponent.totalAnswerTimeMs += opponent.answerElapsedMs;
            opponent.timeoutStreak = opponent.submittedAnswerKey == 0 ? opponent.timeoutStreak + 1 : 0;
        }

        txtScoreMe.setText(setScoreMe + "");
        txtScoreGameMe.setText(gameScoreMe + "");
        refreshOpponentPanels();
    }

    private boolean handleLocalTimeoutRemovalIfNeeded() {
        if (!modeOnline || eliminationMode || localPlayerRemoved || myTimeoutStreak < MAX_TIMEOUT_STREAK) {
            return false;
        }

        localPlayerRemoved = true;
        markMyGameState("left_timeout");
        detachOpponentRoundListener();
        detachQuestionSyncListener();
        stopTimer(false);
        CAN_PLAY = false;
        CAN_HOME = false;

        new AlertDialog.Builder(this)
                .setMessage("أخطأت في 3 أسئلة متتالية. سيكمل خصم آلي اللعب بدلًا منك.")
                .setCancelable(false)
                .setPositiveButton("حسنًا", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        Intent intent = new Intent(GameActivity.this, MainActivity.class);
                        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                        startActivity(intent);
                        finish();
                    }
                })
                .show();
        return true;
    }

    private int handleEliminationRoundProgress() {
        final ArrayList<String> eliminatedNames = new ArrayList<>();
        boolean localEliminatedThisRound = false;

        if (!localPlayerEliminated && mySubmittedAnswerKey != ANSWER_KEY_RIGHT) {
            localPlayerEliminated = true;
            markMyGameState("eliminated");
            localEliminatedThisRound = true;
            eliminatedNames.add("أنت");
        }

        for (MatchOpponent opponent : opponents) {
            if (opponent.eliminated) {
                continue;
            }
            if (opponent.submittedAnswerKey != ANSWER_KEY_RIGHT) {
                opponent.eliminated = true;
                eliminatedNames.add(opponent.name);
            }
        }

        refreshOpponentPanels();

        if (currentQuestion == 14) {
            String leaderId = getMatchLeaderId();
            if (myID.equals(leaderId)) {
                person.moveShow2Hands(2000);
                person.raiseEyeBrowsUp(1000, false, true);
                showDialog("مبروك، فزت في مباراة الإقصاء بأعلى نقاط", "", 2000, 3000, R.drawable.mouth_01, false);
                updateScoreAndLevel();
                return 1;
            }

            showDialog("انتهت مباراة الإقصاء. الفائز هو " + getPlayerDisplayName(leaderId), "", 2000, 3000, R.drawable.mouth_01, false);
            updateScoreAndLevel();
            return -1;
        }

        if (localEliminatedThisRound) {
            if (getAlivePlayersCount() == 0) {
                showDialog("انتهت المباراة، جميع اللاعبين خارج", "", 2000, 3000, R.drawable.mouth_05, false);
                updateScoreAndLevel();
                return -1;
            }
            showDialog("إجابة خاطئة، خرجت من المنافسة.\nهل تريد متابعة المباراة كمشاهد؟", "EliminationSpectatorChoice", 1000, 0, R.drawable.mouth_05, false);
            return -3;
        }

        if (getAlivePlayersCount() == 0) {
            showDialog("انتهت المباراة، جميع اللاعبين خارج", "", 2000, 3000, R.drawable.mouth_05, false);
            updateScoreAndLevel();
            return -1;
        }

        if (eliminatedNames.isEmpty()) {
            showDialog("جميع اللاعبين أجابوا بشكل صحيح", "", 1000, 2000, R.drawable.mouth_01, false);
        } else if (eliminatedNames.size() == 1) {
            showDialog("تم إقصاء " + eliminatedNames.get(0), "", 1000, 2000, R.drawable.mouth_05, false);
        } else {
            showDialog("تم إقصاء " + joinNames(eliminatedNames), "", 1000, 2000, R.drawable.mouth_05, false);
        }
        return -2;
    }

    private void continueEliminationMatchAsSpectator() {
        if (!modeOnline || !eliminationMode || EXITING) {
            return;
        }

        if (getAlivePlayersCount() == 0) {
            updateScoreAndLevel();
            openOnlineResultScreen(false);
            return;
        }

        initQuestion();
        nextStep();
        playSound(R.raw.lets_play, true, false);
        String currentStepAmount = getCurrentStepAmount();
        person.moveHead(1000);
        person.lookAside(600);
        showDialog("السؤال التالي قيمته\n" + currentStepAmount, "", 1000, 3000, R.drawable.mouth_02, false);
        CAN_HOME = true;

        final Handler handler = new Handler();
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (EXITING) {
                    return;
                }
                Animations.move(llyQA, 1000, -140, 0, 0, 0);
                Animations.move(llySteps, 1000, -360, 0, 0, 0);
                handler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        if (EXITING) {
                            return;
                        }
                        requestSynchronizedQuestion(currentQuestion + 1);
                    }
                }, 1000);
            }
        }, 4000);
    }

    private void exitEliminationMatchAfterDecliningSpectator() {
        if (EXITING) {
            return;
        }

        updateScoreAndLevel();
        PlayerProgress.onOnlineMatchFinished(
                GameActivity.this,
                false,
                setMe,
                "elimination",
                false,
                null
        );
        PlayerStats.recordGameEnd(GameActivity.this, false, gameScoreMe * 1000);
        detachOpponentStatusListener();
        detachOpponentRoundListener();
        detachQuestionSyncListener();
        EXITING = true;

        Intent intent = new Intent(GameActivity.this, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
        finish();
    }

    private int getAlivePlayersCount() {
        int aliveCount = localPlayerEliminated ? 0 : 1;
        for (MatchOpponent opponent : opponents) {
            if (!opponent.eliminated) {
                aliveCount++;
            }
        }
        return aliveCount;
    }

    private String getAliveLeaderId() {
        String leaderId = localPlayerEliminated ? "" : myID;
        for (MatchOpponent opponent : opponents) {
            if (opponent.eliminated) {
                continue;
            }
            if (leaderId.isEmpty() || compareMatchStanding(opponent.id, leaderId) < 0) {
                leaderId = opponent.id;
            }
        }
        return leaderId;
    }

    private String joinNames(ArrayList<String> names) {
        StringBuilder builder = new StringBuilder();
        for (int i = 0; i < names.size(); i++) {
            if (i > 0) {
                builder.append(i == names.size() - 1 ? " و " : "، ");
            }
            builder.append(names.get(i));
        }
        return builder.toString();
    }


    private boolean usedAllHelps() {
        return usedHelp5050 && usedHelpAudience && usedHelpCall;
    }

    private boolean usedAnyHelp() {
        return usedHelp5050 || usedHelpAudience || usedHelpCall;
    }

    private void goToWinnerScreen(String amount) {
        try {
            int prize = Integer.parseInt(amount.replace("$", "").trim());
            PlayerStats.recordGameEnd(GameActivity.this, true, prize);
            PlayerProgress.onGameFinished(GameActivity.this, true, prize, PlayerStats.getBestStreak(GameActivity.this), usedAllHelps(), usedAnyHelp());
        } catch (Exception ignored) {}
        Intent intent = new Intent(GameActivity.this, WinnerActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        intent.putExtra("amount", amount);
        startActivity(intent);
    }

    private boolean checkScores() {
        if ((currentQuestion == 4) || (currentQuestion == 9) || (currentQuestion == 14)) {
            if (setScoreMe > setScoreOpponent) {
                setMe++;
                setScoreMe = 0;
                setScoreOpponent = 0;
            } else if (setScoreMe < setScoreOpponent) {
                setOpponent++;
                setScoreMe = 0;
                setScoreOpponent = 0;
            } else {
                setMe++;
                setOpponent++;
            }
            txtSetsMe.setText(setMe + "");
            txtSetsOpponent.setText(setOpponent + "");
            txtScoreMe.setText("0");
            txtScoreOpponent.setText("0");
            String setNum = (currentQuestion == 4 ? "الأولى" : (currentQuestion == 9 ? "الثانية" : "الثالثة"));
            if (setMe > setOpponent) {
                person.like(1000);
                person.raiseEyeBrowsUp(1000, false, true);
                showDialog("انتهت الجولة " + setNum + " والنتيجة تقدمك " + setMe + " مقابل " + setOpponent, "", 2000, 3000, R.drawable.mouth_01, false);
            } else if (setMe < setOpponent) {
                showDialog("انتهت الجولة " + setNum + " والنتيجة تأخرك " + setMe + " مقابل " + setOpponent, "", 2000, 3000, R.drawable.mouth_01, false);
            } else {
                showDialog("انتهت الجولة " + setNum + " والنتيجة التعادل " + setMe + " - " + setOpponent, "", 2000, 3000, R.drawable.mouth_01, false);
            }
            return true;
        } else {
            return false;
        }
    }

    private int checkEndOfGame() {
        int res;
        int setNum = (currentQuestion == 4 ? 1 : (currentQuestion == 9 ? 2 : 3));
        if ((currentQuestion == 14) || ((3 - setNum) < Math.abs(setMe - setOpponent))) {
            if (setMe > setOpponent) {
                res = 1;
                person.moveShow2Hands(2000);
                person.raiseEyeBrowsUp(1000, false, true);
                showDialog("مبروك انتهت المباراة بفوزك بنتيجة " + setMe + " مقابل " + setOpponent, "", 2000, 3000, R.drawable.mouth_01, false);
            } else if (setMe < setOpponent) {
                res = -1;
                showDialog("للأسف انتهت المباراة بخسارتك بنتيجة " + setMe + " مقابل " + setOpponent, "", 2000, 3000, R.drawable.mouth_01, false);
            } else {
                res = 0;
                showDialog("انتهت المباراة بالتعادل بنتيجة " + setMe + " - " + setOpponent, "", 2000, 3000, R.drawable.mouth_01, false);
            }
            updateScoreAndLevel();
            return res;
        } else {
            return -2;
        }
    }

    private void updateScoreAndLevel() {
        if (gameScoreMe > 0) {
            int newScore = myScore + gameScoreMe;
            if (!myID.startsWith("guest_")) Data.setUserScore(myID, newScore);
            int newLevel = 1;
            if (newScore >= 200000000)
                newLevel = 10;
            else if (newScore >= 100000000)
                newLevel = 9;
            else if (newScore >= 50000000)
                newLevel = 8;
            else if (newScore >= 25000000)
                newLevel = 7;
            else if (newScore >= 15000000)
                newLevel = 6;
            else if (newScore >= 9000000)
                newLevel = 5;
            else if (newScore >= 6000000)
                newLevel = 4;
            else if (newScore >= 3000000)
                newLevel = 3;
            else if (newScore >= 1000000)
                newLevel = 2;

            AppPrefs.setUser(GameActivity.this, myID, myName, myPhoto, newLevel, newScore);
            myScore = newScore;
            if (newLevel > myLevel) {
                if (!myID.startsWith("guest_")) Data.setUserLevel(myID, newLevel);
                final Handler handler = new Handler();
                final int finalNewLevel = newLevel;
                Runnable runnable = new Runnable() {
                    @Override
                    public void run() {
                        playSound(R.raw.new_level, false, false);
                        showDialog("ممتاز.. لقد وصلت إلى المستوى " + finalNewLevel, "", 1000, 3000, R.drawable.mouth_01, false);
                    }
                };
                handler.postDelayed(runnable, 3000);
            }
        }
    }

    private void getQuestions(String gameID) {
        questionsReady = false;
        questionsLoadFailed = false;
        if (!modeOnline) {
            GameActivity.this.questions = LocalQuestions.load(this);
            questionsReady = !GameActivity.this.questions.isEmpty();
            return;
        }
        new Data().getQuestions(gameID, new OnGetQuestionsListener() {
            @Override
            public void onSuccess(ArrayList<Question> questions) {
                GameActivity.this.questions = questions;
                questionsReady = questions != null && !questions.isEmpty();
                questionsLoadFailed = false;
            }

            @Override
            public void onFailed(DatabaseError error) {
                questionsReady = false;
                questionsLoadFailed = true;
                startPending = false;
                Toast.makeText(GameActivity.this, "تعذر تحميل أسئلة المواجهة", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void getGame() {
        new Data().getGameID(myID, new OnGetGameIdListener() {
            @Override
            public void onSuccess(String gameID) {
                if (!gameID.equals("")) {
                    GameActivity.this.gameID = gameID;
                    beginOnlineGameSession();
                    Data.removeTempGameID(gameID);
                    new Data().getGameQuestions(GameActivity.this.gameID, new OnGetQuestionsListener() {
                        @Override
                        public void onSuccess(ArrayList<Question> questions) {
                            GameActivity.this.questions = questions;
                            questionsReady = questions != null && !questions.isEmpty();
                            questionsLoadFailed = false;
                        }

                        @Override
                        public void onFailed(DatabaseError error) {
                            questionsReady = false;
                            questionsLoadFailed = true;
                            startPending = false;
                            Toast.makeText(GameActivity.this, "تعذر تحميل أسئلة المواجهة", Toast.LENGTH_SHORT).show();
                        }
                    });
                }
            }

            @Override
            public void onFailed(DatabaseError error) {

            }
        });
    }

    private void startMatchFlow() {
        if (!modeOnline || questionsReady) {
            startPending = false;
            letsStart();
            return;
        }
        if (questionsLoadFailed) {
            startPending = false;
            Toast.makeText(GameActivity.this, "تعذر تحميل أسئلة المواجهة", Toast.LENGTH_SHORT).show();
            return;
        }
        if (startPending) {
            return;
        }
        startPending = true;
        Toast.makeText(GameActivity.this, "جارٍ تجهيز أسئلة المواجهة...", Toast.LENGTH_SHORT).show();
        final Handler handler = new Handler();
        handler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (EXITING) {
                    startPending = false;
                    return;
                }
                if (questionsLoadFailed) {
                    startPending = false;
                    Toast.makeText(GameActivity.this, "تعذر تحميل الأسئلة", Toast.LENGTH_SHORT).show();
                    CAN_CLICK = true;
                    return;
                }
                if (questionsReady) {
                    startPending = false;
                    letsStart();
                } else {
                    handler.postDelayed(this, 300);
                }
            }
        }, 300);
    }

    private void beginOnlineGameSession() {
        if (!modeOnline || gameID == null || gameID.trim().isEmpty()) {
            return;
        }
        attachServerTimeOffsetListener();
        myStatusRef = FirebaseDatabase.getInstance().getReference()
                .child("Games")
                .child(gameID)
                .child(myID)
                .child("status");
        try {
            myStatusRef.onDisconnect().setValue("left");
        } catch (Exception ignored) {
        }
        markMyGameState("active");
        attachOpponentStatusListener();
    }

    private void attachOpponentStatusListener() {
        if (gameID == null || gameID.trim().isEmpty()) {
            return;
        }
        detachOpponentStatusListener();
        for (final MatchOpponent opponent : opponents) {
            if (opponent.bot || opponent.id == null || opponent.id.trim().isEmpty()) {
                continue;
            }
            opponent.statusRef = FirebaseDatabase.getInstance().getReference()
                    .child("Games")
                    .child(gameID)
                    .child(opponent.id)
                    .child("status");
            opponent.statusListener = new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    if (EXITING || opponent.left || opponent.eliminated) {
                        return;
                    }
                    String status = snapshot.getValue(String.class);
                    if ("left".equals(status) || "left_timeout".equals(status)) {
                        convertOpponentToComputer(opponent);
                    } else if ("eliminated".equals(status)) {
                        opponent.eliminated = true;
                        refreshOpponentPanels();
                    }
                }

                @Override
                public void onCancelled(DatabaseError error) {
                }
            };
            opponent.statusRef.addValueEventListener(opponent.statusListener);
        }
    }

    private void detachOpponentStatusListener() {
        for (MatchOpponent opponent : opponents) {
            if (opponent.statusRef != null && opponent.statusListener != null) {
                opponent.statusRef.removeEventListener(opponent.statusListener);
            }
            opponent.statusRef = null;
            opponent.statusListener = null;
        }
    }

    private void markMyGameState(String status) {
        if (!modeOnline || gameID == null || gameID.trim().isEmpty()) {
            return;
        }
        if (myStatusRef == null) {
            myStatusRef = FirebaseDatabase.getInstance().getReference()
                    .child("Games")
                    .child(gameID)
                    .child(myID)
                    .child("status");
        }
        myStatusRef.setValue(status);
        if ("active".equals(status)) {
            try {
                myStatusRef.onDisconnect().setValue("left");
            } catch (Exception ignored) {
            }
        } else {
            try {
                myStatusRef.onDisconnect().cancel();
            } catch (Exception ignored) {
            }
        }
        if ("left".equals(status)
                || "left_timeout".equals(status)
                || "finished".equals(status)
                || "eliminated".equals(status)) {
            matchStateCommitted = true;
        }
    }

    private void leaveOnlineMatchIfNeeded() {
        if (!modeOnline || matchStateCommitted) {
            return;
        }
        markMyGameState("left");
        detachOpponentStatusListener();
        detachOpponentRoundListener();
        detachQuestionSyncListener();
    }

    private void attachServerTimeOffsetListener() {
        if (serverOffsetRef != null) {
            return;
        }
        serverOffsetRef = FirebaseDatabase.getInstance().getReference(".info/serverTimeOffset");
        serverOffsetListener = new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                Long offset = snapshot.getValue(Long.class);
                serverTimeOffsetMs = offset == null ? 0L : offset;
            }

            @Override
            public void onCancelled(DatabaseError error) {
            }
        };
        serverOffsetRef.addValueEventListener(serverOffsetListener);
    }

    private void detachServerTimeOffsetListener() {
        if (serverOffsetRef != null && serverOffsetListener != null) {
            serverOffsetRef.removeEventListener(serverOffsetListener);
        }
        serverOffsetRef = null;
        serverOffsetListener = null;
    }

    private void handleOpponentLeftMatch() {
        if (opponentExitHandled || EXITING) {
            return;
        }
        opponentExitHandled = true;
        stopTimer(true);
        stopSound(mpSound);
        mpSound = null;
        detachOpponentStatusListener();
        showDialog("انسحب منافسك من المباراة.\nهل تريد أن تكمل مع الكمبيوتر؟", "OpponentLeftContinue", 1000, 0, R.drawable.mouth_05, false);
    }

    private void openOnlineResultScreen(boolean opponentLeft) {
        if (!modeOnline) {
            return;
        }
        if (!opponentLeft) {
            markMyGameState("finished");
        }
        detachOpponentStatusListener();
        detachOpponentRoundListener();
        detachQuestionSyncListener();
        String leaderId = getMatchLeaderId();
        Intent intent = new Intent(GameActivity.this, ResultActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        intent.putExtra("myScore", gameScoreMe);
        intent.putExtra("myNewScore", myScore);
        intent.putExtra("opponentScore", getHighestOpponentScore());
        intent.putExtra("mySets", setMe);
        intent.putExtra("opponentSets", getLeaderSets());
        intent.putExtra("myName", myName);
        intent.putExtra("myPhoto", myPhoto);
        intent.putExtra("opponentName", opponentName);
        intent.putExtra("opponentPhoto", opponentPhoto);
        intent.putExtra("opponentLeft", opponentLeft);
        intent.putExtra("didWin", myID.equals(leaderId));
        intent.putExtra("winnerName", getPlayerDisplayName(leaderId));
        intent.putExtra("opponentsJson", buildOpponentsSummaryJson());
        startActivity(intent);
        finish();
    }

    private void continueMatchWithComputer() {
        detachOpponentStatusListener();
        detachOpponentRoundListener();
        cancelPendingFictitiousAnswer();
        opponentID = "fictitious";
        opponentName = "الكمبيوتر";
        opponentPhoto = "";
        opponentExitHandled = false;

        if (txtPlayer2 != null) {
            txtPlayer2.setText(opponentName);
        }

        Data.setImageSource(this, imgOpponent, opponentPhoto);
        Data.setImageSource(this, imgAnswer1Player2, opponentPhoto);
        Data.setImageSource(this, imgAnswer2Player2, opponentPhoto);
        Data.setImageSource(this, imgAnswer3Player2, opponentPhoto);
        Data.setImageSource(this, imgAnswer4Player2, opponentPhoto);

        if (currentQuestion >= 0) {
            Data.initQuestionPlayer(gameID, opponentID, currentQuestion);
            prepareOnlineQuestionSync(currentQuestion);
            scheduleFictitiousAnswerForCurrentQuestion();
        }

        Toast.makeText(this, "ستكمل المباراة الآن ضد الكمبيوتر", Toast.LENGTH_SHORT).show();
        CAN_HOME = true;
        if (myAnswer > 0) {
            CAN_PLAY = false;
        } else {
            CAN_PLAY = true;
            startTimer(false);
        }
    }

    private void scheduleFictitiousAnswerForCurrentQuestion() {
        cancelPendingFictitiousAnswer();
        if (!modeOnline || !"fictitious".equals(opponentID) || currentQuestion < 0 || currentQuestion >= questions.size()) {
            return;
        }
        if (opponentAnswer > 0) {
            return;
        }

        final int questionIndex = currentQuestion;
        int remainingMillis = Math.max(1000, ((PROGRESS_VALUE / 10) - 1) * 1000);
        int delayMillis = myAnswer > 0 ? 1200 : Math.min(remainingMillis, 3000);

        pendingFictitiousAnswerRunnable = new Runnable() {
            @Override
            public void run() {
                pendingFictitiousAnswerRunnable = null;
                if (EXITING || opponentExitHandled || !"fictitious".equals(opponentID)) {
                    return;
                }
                if (questionIndex != currentQuestion || opponentAnswerSubmitted || rightAnswer <= 0) {
                    return;
                }

                int randomAnswer = getFictitiousRandomAnswer();
                submitFictitiousRoundAnswer(randomAnswer);
            }
        };
        fictitiousAnswerHandler.postDelayed(pendingFictitiousAnswerRunnable, delayMillis);
    }

    private void submitFictitiousRoundAnswer(final int displayedAnswer) {
        if (!modeOnline || !"fictitious".equals(opponentID) || opponentAnswerSubmitted) {
            return;
        }
        final DatabaseReference fictitiousRef = getRoundSyncRef(currentQuestion);
        if (fictitiousRef == null) {
            return;
        }

        opponentAnswer = displayedAnswer;
        opponentSubmittedAnswerKey = getAnswerKeyForDisplayedIndex(displayedAnswer);
        opponentAnswerSubmitted = true;
        long elapsedMs = displayedAnswer <= 0 ? QUESTION_TIMEOUT_MS : getCurrentAnswerElapsedMs();
        HashMap<String, Object> payload = new HashMap<>();
        payload.put("players/" + opponentID + "/answerKey", opponentSubmittedAnswerKey);
        payload.put("players/" + opponentID + "/submitted", true);
        payload.put("players/" + opponentID + "/correct", opponentSubmittedAnswerKey == ANSWER_KEY_RIGHT);
        payload.put("players/" + opponentID + "/elapsedMs", elapsedMs);
        fictitiousRef.updateChildren(payload);
        if (myAnswerSubmitted) {
            resolveOnlineRoundIfReady();
        }
    }

    private void cancelPendingBotAnswers() {
        for (Runnable runnable : pendingBotAnswerRunnables.values()) {
            fictitiousAnswerHandler.removeCallbacks(runnable);
        }
        pendingBotAnswerRunnables.clear();
    }

    private void scheduleBotAnswersForCurrentQuestion() {
        cancelPendingBotAnswers();
        if (!modeOnline || currentQuestion < 0 || currentQuestion >= questions.size()) {
            return;
        }
        for (MatchOpponent opponent : opponents) {
            if (opponent.bot && !opponent.eliminated) {
                scheduleBotAnswer(opponent);
            }
        }
    }

    private void scheduleBotAnswer(final MatchOpponent opponent) {
        if (opponent == null || !opponent.bot || opponent.submitted || opponent.eliminated) {
            return;
        }
        final int questionIndex = currentQuestion;
        int remainingMillis = Math.max(1000, ((PROGRESS_VALUE / 10) - 1) * 1000);
        int delayMillis = myAnswer > 0 ? 1200 : Math.min(remainingMillis, getBotDelayMillis(opponent));

        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                pendingBotAnswerRunnables.remove(opponent.id);
                if (EXITING || currentQuestion != questionIndex || rightAnswer <= 0 || opponent.submitted) {
                    return;
                }
                int randomAnswer = getBotDisplayedAnswer(opponent);
                submitBotRoundAnswer(opponent, randomAnswer);
            }
        };
        pendingBotAnswerRunnables.put(opponent.id, runnable);
        fictitiousAnswerHandler.postDelayed(runnable, delayMillis);
    }

    private void submitBotRoundAnswer(final MatchOpponent opponent, final int displayedAnswer) {
        if (!modeOnline || opponent == null || !opponent.bot || opponent.eliminated) {
            return;
        }
        // Always get a fresh ref for the current question — don't rely on the
        // shared roundSyncRef which may have been reassigned for a different
        // question by the time this callback fires.
        final int botQuestion = currentQuestion;
        final DatabaseReference botRef = getRoundSyncRef(botQuestion);
        if (botRef == null) {
            return;
        }

        opponent.displayedAnswer = displayedAnswer;
        opponent.submittedAnswerKey = getAnswerKeyForDisplayedIndex(displayedAnswer);
        opponent.submitted = true;
        opponent.answerElapsedMs = displayedAnswer <= 0 ? QUESTION_TIMEOUT_MS : getCurrentAnswerElapsedMs();

        HashMap<String, Object> payload = new HashMap<>();
        payload.put("players/" + opponent.id + "/answerKey", opponent.submittedAnswerKey);
        payload.put("players/" + opponent.id + "/submitted", true);
        payload.put("players/" + opponent.id + "/correct", opponent.submittedAnswerKey == ANSWER_KEY_RIGHT);
        payload.put("players/" + opponent.id + "/elapsedMs", opponent.answerElapsedMs);
        botRef.updateChildren(payload);
        if (myAnswerSubmitted && botQuestion == currentQuestion) {
            resolveOnlineRoundIfReady();
        }
    }

    private void convertOpponentToComputer(MatchOpponent opponent) {
        if (opponent == null) {
            return;
        }
        opponent.left = true;
        applyBotIdentity(opponent, true);
        if (opponent.statusRef != null && opponent.statusListener != null) {
            opponent.statusRef.removeEventListener(opponent.statusListener);
        }
        opponent.statusRef = null;
        opponent.statusListener = null;
        refreshOpponentPanels();
        if (currentQuestion >= 0 && !opponent.submitted) {
            scheduleBotAnswer(opponent);
        }
    }

    private int getHighestOpponentScore() {
        int bestScore = 0;
        for (MatchOpponent opponent : opponents) {
            bestScore = Math.max(bestScore, opponent.gameScore);
        }
        return bestScore;
    }

    private String buildOpponentsSummaryJson() {
        JSONArray array = new JSONArray();
        try {
            for (MatchOpponent opponent : opponents) {
                JSONObject object = new JSONObject();
                object.put("id", opponent.id);
                object.put("name", opponent.name);
                object.put("photo", opponent.photo);
                object.put("score", opponent.gameScore);
                object.put("sets", opponent.sets);
                object.put("bot", opponent.bot);
                object.put("left", opponent.left);
                object.put("intelligence", opponent.intelligence);
                array.put(object);
            }
        } catch (Exception ignored) {
        }
        return array.toString();
    }

    private boolean checkScoresMulti() {
        if ((currentQuestion != 4) && (currentQuestion != 9) && (currentQuestion != 14)) {
            return false;
        }

        String setWinnerId = getSetLeaderId();
        if (myID.equals(setWinnerId)) {
            setMe++;
        } else {
            MatchOpponent winner = findOpponentById(setWinnerId);
            if (winner != null) {
                winner.sets++;
            }
        }
        for (MatchOpponent opponent : opponents) {
            opponent.roundScore = 0;
            opponent.setCorrectAnswers = 0;
            opponent.setAnswerTimeMs = 0L;
        }
        setScoreMe = 0;
        mySetCorrectAnswers = 0;
        mySetAnswerTimeMs = 0L;
        txtSetsMe.setText(String.valueOf(setMe));
        txtScoreMe.setText("0");
        refreshOpponentPanels();
        String setNumLabelResolved = (currentQuestion == 4 ? "الأولى" : (currentQuestion == 9 ? "الثانية" : "الثالثة"));
        if (myID.equals(setWinnerId)) {
            person.like(1000);
            person.raiseEyeBrowsUp(1000, false, true);
            showDialog("انتهت الجولة " + setNumLabelResolved + " وحسمتها لصالحك", "", 2000, 3000, R.drawable.mouth_01, false);
        } else {
            showDialog("انتهت الجولة " + setNumLabelResolved + " وفاز بها " + getPlayerDisplayName(setWinnerId), "", 2000, 3000, R.drawable.mouth_01, false);
        }
        return true;
        /*

        String setNumLabel = (currentQuestion == 4 ? "الأولى" : (currentQuestion == 9 ? "الثانية" : "الثالثة"));
        if (myID.equals(setWinnerId)) {
            person.like(1000);
            person.raiseEyeBrowsUp(1000, false, true);
            showDialog("انتهت الجولة " + setNumLabel + " وأنت المتصدر بـ " + setMe + " جولات", "", 2000, 3000, R.drawable.mouth_01, false);
        } else {
            showDialog("انتهت الجولة " + setNumLabel + " وأنت في الصدارة مع " + leadersCount + " لاعبين", "", 2000, 3000, R.drawable.mouth_01, false);
        } else {
            showDialog("انتهت الجولة " + setNumLabel + " وأنت خلف المتصدر بـ " + setMe + " جولات", "", 2000, 3000, R.drawable.mouth_01, false);
        }
        return true;
        */
    }

    private int checkEndOfGameMulti() {
        String leaderIdResolved = getMatchLeaderId();
        int setNumResolved = (currentQuestion == 4 ? 1 : (currentQuestion == 9 ? 2 : 3));
        int leaderSetsResolved = getSetsForPlayer(leaderIdResolved);

        // إنهاء مبكر: بعد الجولة الثانية فقط إذا فاز أحد بجولتين (لا يمكن اللحاق به)
        boolean earlyEnd = (setNumResolved == 2 && leaderSetsResolved >= 2);
        if (currentQuestion != 14 && !earlyEnd) {
            return -2;
        }

        // تعادل في الجولات بعد الجولة الثالثة (مثلاً 1-1-1) → الفاصل النقاط الكلية
        boolean tiedOnSets = (currentQuestion == 14 && leaderSetsResolved == 1);

        int resolvedResult;
        if (myID.equals(leaderIdResolved)) {
            resolvedResult = 1;
            person.moveShow2Hands(2000);
            person.raiseEyeBrowsUp(1000, false, true);
            if (earlyEnd) {
                showDialog("مبروك! فزت بجولتين وحسمت المباراة مبكراً", "", 2000, 3000, R.drawable.mouth_01, false);
            } else if (tiedOnSets) {
                showDialog("تعادلنا في الجولات.. لكن نقاطك الأعلى تجعلك الفائز! مبروك", "", 2000, 3000, R.drawable.mouth_01, false);
            } else {
                showDialog("مبروك انتهت المباراة وأنت الفائز", "", 2000, 3000, R.drawable.mouth_01, false);
            }
        } else {
            resolvedResult = -1;
            if (earlyEnd) {
                showDialog("انتهت المباراة مبكراً. " + getPlayerDisplayName(leaderIdResolved) + " فاز بجولتين متتاليتين", "", 2000, 3000, R.drawable.mouth_01, false);
            } else if (tiedOnSets) {
                showDialog("تعادلنا في الجولات! الفائز بأعلى نقاط: " + getPlayerDisplayName(leaderIdResolved), "", 2000, 3000, R.drawable.mouth_01, false);
            } else {
                showDialog("انتهت المباراة. الفائز هو " + getPlayerDisplayName(leaderIdResolved), "", 2000, 3000, R.drawable.mouth_01, false);
            }
        }
        updateScoreAndLevel();
        return resolvedResult;
        /*
        int setNum = (currentQuestion == 4 ? 1 : (currentQuestion == 9 ? 2 : 3));
        int leaderSets = getLeaderSets();
        int leadersCount = getLeadersCount(leaderSets);
        if ((currentQuestion != 14) && ((3 - setNum) >= Math.max(0, leaderSets - setMe))) {
            return -2;
        }

        int res;
        if (setMe == leaderSets && leadersCount == 1) {
            res = 1;
            person.moveShow2Hands(2000);
            person.raiseEyeBrowsUp(1000, false, true);
            showDialog("مبروك انتهت المباراة وأنت الفائز بـ " + setMe + " جولات", "", 2000, 3000, R.drawable.mouth_01, false);
        } else if (setMe == leaderSets) {
            res = 0;
            showDialog("انتهت المباراة بتعادلك في الصدارة مع " + leadersCount + " لاعبين", "", 2000, 3000, R.drawable.mouth_01, false);
        } else {
            res = -1;
            showDialog("للأسف انتهت المباراة وأنت خلف المتصدر بـ " + setMe + " جولات", "", 2000, 3000, R.drawable.mouth_01, false);
        }
        updateScoreAndLevel();
        return res;
        */
    }

    private int getLeaderSets() {
        return getSetsForPlayer(getMatchLeaderId());
    }

    private int getLeadersCount(int leaderSets) {
        return 1;
    }

    private String getSetLeaderId() {
        String leaderId = myID;
        for (MatchOpponent opponent : opponents) {
            if (compareSetStanding(opponent.id, leaderId) < 0) {
                leaderId = opponent.id;
            }
        }
        return leaderId;
    }

    private String getMatchLeaderId() {
        String leaderId = myID;
        for (MatchOpponent opponent : opponents) {
            if (compareMatchStanding(opponent.id, leaderId) < 0) {
                leaderId = opponent.id;
            }
        }
        return leaderId;
    }

    private int compareSetStanding(String leftPlayerId, String rightPlayerId) {
        int scoreCompare = Integer.compare(getSetScoreForPlayer(rightPlayerId), getSetScoreForPlayer(leftPlayerId));
        if (scoreCompare != 0) {
            return scoreCompare;
        }
        int correctCompare = Integer.compare(getSetCorrectAnswersForPlayer(rightPlayerId), getSetCorrectAnswersForPlayer(leftPlayerId));
        if (correctCompare != 0) {
            return correctCompare;
        }
        int timeCompare = Long.compare(getSetAnswerTimeForPlayer(leftPlayerId), getSetAnswerTimeForPlayer(rightPlayerId));
        if (timeCompare != 0) {
            return timeCompare;
        }
        return Integer.compare(stableHash(leftPlayerId), stableHash(rightPlayerId));
    }

    private int compareMatchStanding(String leftPlayerId, String rightPlayerId) {
        int setsCompare = Integer.compare(getSetsForPlayer(rightPlayerId), getSetsForPlayer(leftPlayerId));
        if (setsCompare != 0) {
            return setsCompare;
        }
        int scoreCompare = Integer.compare(getGameScoreForPlayer(rightPlayerId), getGameScoreForPlayer(leftPlayerId));
        if (scoreCompare != 0) {
            return scoreCompare;
        }
        int correctCompare = Integer.compare(getTotalCorrectAnswersForPlayer(rightPlayerId), getTotalCorrectAnswersForPlayer(leftPlayerId));
        if (correctCompare != 0) {
            return correctCompare;
        }
        int timeCompare = Long.compare(getTotalAnswerTimeForPlayer(leftPlayerId), getTotalAnswerTimeForPlayer(rightPlayerId));
        if (timeCompare != 0) {
            return timeCompare;
        }
        return Integer.compare(stableHash(leftPlayerId), stableHash(rightPlayerId));
    }

    private int getSetsForPlayer(String playerId) {
        if (myID.equals(playerId)) {
            return setMe;
        }
        MatchOpponent opponent = findOpponentById(playerId);
        return opponent == null ? 0 : opponent.sets;
    }

    private int getSetScoreForPlayer(String playerId) {
        if (myID.equals(playerId)) {
            return setScoreMe;
        }
        MatchOpponent opponent = findOpponentById(playerId);
        return opponent == null ? 0 : opponent.roundScore;
    }

    private int getGameScoreForPlayer(String playerId) {
        if (myID.equals(playerId)) {
            return gameScoreMe;
        }
        MatchOpponent opponent = findOpponentById(playerId);
        return opponent == null ? 0 : opponent.gameScore;
    }

    private int getSetCorrectAnswersForPlayer(String playerId) {
        if (myID.equals(playerId)) {
            return mySetCorrectAnswers;
        }
        MatchOpponent opponent = findOpponentById(playerId);
        return opponent == null ? 0 : opponent.setCorrectAnswers;
    }

    private int getTotalCorrectAnswersForPlayer(String playerId) {
        if (myID.equals(playerId)) {
            return myTotalCorrectAnswers;
        }
        MatchOpponent opponent = findOpponentById(playerId);
        return opponent == null ? 0 : opponent.totalCorrectAnswers;
    }

    private long getSetAnswerTimeForPlayer(String playerId) {
        if (myID.equals(playerId)) {
            return mySetAnswerTimeMs;
        }
        MatchOpponent opponent = findOpponentById(playerId);
        return opponent == null ? Long.MAX_VALUE : opponent.setAnswerTimeMs;
    }

    private long getTotalAnswerTimeForPlayer(String playerId) {
        if (myID.equals(playerId)) {
            return myTotalAnswerTimeMs;
        }
        MatchOpponent opponent = findOpponentById(playerId);
        return opponent == null ? Long.MAX_VALUE : opponent.totalAnswerTimeMs;
    }

    private String getPlayerDisplayName(String playerId) {
        if (myID.equals(playerId)) {
            return "أنت";
        }
        MatchOpponent opponent = findOpponentById(playerId);
        return opponent == null ? "Player" : opponent.name;
    }

    private void cancelPendingFictitiousAnswer() {
        cancelPendingBotAnswers();
        if (pendingFictitiousAnswerRunnable != null) {
            fictitiousAnswerHandler.removeCallbacks(pendingFictitiousAnswerRunnable);
            pendingFictitiousAnswerRunnable = null;
        }
    }

    private String getRoundKey(int questionIndex) {
        return "q" + questionIndex;
    }

    private DatabaseReference getQuestionSyncRef(int questionIndex) {
        if (gameID == null || gameID.trim().isEmpty()) {
            return null;
        }
        return FirebaseDatabase.getInstance().getReference()
                .child("Games")
                .child(gameID)
                .child("questionSync")
                .child(getRoundKey(questionIndex));
    }

    private DatabaseReference getRoundSyncRef(int questionIndex) {
        if (gameID == null || gameID.trim().isEmpty()) {
            return null;
        }
        return FirebaseDatabase.getInstance().getReference()
                .child("Games")
                .child(gameID)
                .child("rounds")
                .child(getRoundKey(questionIndex));
    }

    private void prepareOnlineQuestionSync(int questionIndex) {
        if (!modeOnline) {
            return;
        }
        roundSyncRef = getRoundSyncRef(questionIndex);
        if (roundSyncRef == null) {
            return;
        }
        // IMPORTANT: only write OWN data — writing opponent's data causes a race
        // condition where a late reset can overwrite an already-submitted opponent
        // answer, causing the game to freeze waiting for a re-submission that
        // will never come.
        HashMap<String, Object> payload = new HashMap<>();
        payload.put("players/" + myID + "/answerKey", 0);
        payload.put("players/" + myID + "/submitted", false);
        payload.put("players/" + myID + "/correct", false);
        payload.put("players/" + myID + "/elapsedMs", QUESTION_TIMEOUT_MS);
        roundSyncRef.updateChildren(payload);
    }

    private void requestSynchronizedQuestion(final int questionIndex) {
        if (!modeOnline) {
            showQuestionNow(questionIndex);
            return;
        }
        if (questionIndex < 0 || questionIndex >= questions.size()) {
            return;
        }
        pendingQuestionIndex = questionIndex;
        scheduledQuestionStartAt = 0L;
        attachQuestionSyncListener(questionIndex);
        ensureQuestionStartScheduled(questionIndex);
    }

    private void attachQuestionSyncListener(final int questionIndex) {
        detachQuestionSyncListener();
        questionSyncRef = getQuestionSyncRef(questionIndex);
        if (questionSyncRef == null) {
            return;
        }

        questionSyncListener = new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                if (EXITING || pendingQuestionIndex != questionIndex) {
                    return;
                }
                Long startAt = snapshot.child("startAt").getValue(Long.class);
                if (startAt == null || startAt <= 0L) {
                    ensureQuestionStartScheduled(questionIndex);
                    return;
                }
                scheduleQuestionDisplay(questionIndex, startAt);
            }

            @Override
            public void onCancelled(DatabaseError error) {
            }
        };
        questionSyncRef.addValueEventListener(questionSyncListener);
    }

    private void detachQuestionSyncListener() {
        cancelPendingQuestionStart();
        if (questionSyncRef != null && questionSyncListener != null) {
            questionSyncRef.removeEventListener(questionSyncListener);
        }
        questionSyncRef = null;
        questionSyncListener = null;
    }

    private void cancelPendingQuestionStart() {
        if (pendingQuestionStartRunnable != null) {
            questionSyncHandler.removeCallbacks(pendingQuestionStartRunnable);
            pendingQuestionStartRunnable = null;
        }
    }

    private void ensureQuestionStartScheduled(final int questionIndex) {
        if (questionSyncRef == null) {
            questionSyncRef = getQuestionSyncRef(questionIndex);
        }
        if (questionSyncRef == null) {
            return;
        }

        final long candidateStartAt = getServerNowMs() + (questionIndex == 0
                ? FIRST_QUESTION_SYNC_BUFFER_MS
                : NEXT_QUESTION_SYNC_BUFFER_MS);

        questionSyncRef.runTransaction(new Transaction.Handler() {
            @NonNull
            @Override
            public Transaction.Result doTransaction(@NonNull MutableData currentData) {
                Long existingStartAt = currentData.child("startAt").getValue(Long.class);
                Long existingQuestionIndex = currentData.child("questionIndex").getValue(Long.class);
                if (existingStartAt == null
                        || existingStartAt <= 0L
                        || existingQuestionIndex == null
                        || existingQuestionIndex.intValue() != questionIndex) {
                    currentData.child("questionIndex").setValue(questionIndex);
                    currentData.child("startAt").setValue(candidateStartAt);
                }
                return Transaction.success(currentData);
            }

            @Override
            public void onComplete(@Nullable DatabaseError error, boolean committed, @Nullable DataSnapshot currentData) {
                if (error != null || !committed || currentData == null) {
                    return;
                }
                Long startAt = currentData.child("startAt").getValue(Long.class);
                if (startAt != null) {
                    scheduleQuestionDisplay(questionIndex, startAt);
                }
            }
        });
    }

    private void scheduleQuestionDisplay(final int questionIndex, long startAt) {
        if (currentQuestion >= questionIndex || scheduledQuestionStartAt == startAt) {
            return;
        }
        scheduledQuestionStartAt = startAt;
        cancelPendingQuestionStart();
        final long delay = Math.max(0L, startAt - getServerNowMs());
        pendingQuestionStartRunnable = new Runnable() {
            @Override
            public void run() {
                pendingQuestionStartRunnable = null;
                if (EXITING || currentQuestion >= questionIndex || pendingQuestionIndex != questionIndex) {
                    return;
                }
                detachQuestionSyncListener();
                showQuestionNow(questionIndex);
            }
        };
        questionSyncHandler.postDelayed(pendingQuestionStartRunnable, delay);
    }

    private void attachOpponentRoundListener(final int questionIndex) {
        if (!modeOnline) {
            return;
        }
        detachOpponentRoundListener();
        roundSyncRef = getRoundSyncRef(questionIndex);
        if (roundSyncRef == null) {
            return;
        }

        roundSyncListener = new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                if (EXITING || questionIndex != currentQuestion) {
                    return;
                }
                for (MatchOpponent opponent : opponents) {
                    DataSnapshot opponentSnapshot = snapshot.child("players").child(opponent.id);
                    Long answerValue = opponentSnapshot.child("answerKey").getValue(Long.class);
                    Long elapsedValue = opponentSnapshot.child("elapsedMs").getValue(Long.class);
                    Boolean submittedValue = opponentSnapshot.child("submitted").getValue(Boolean.class);
                    opponent.submittedAnswerKey = answerValue == null ? 0 : answerValue.intValue();
                    opponent.submitted = submittedValue != null && submittedValue;
                    opponent.displayedAnswer = getDisplayedIndexForAnswerKey(opponent.submittedAnswerKey);
                    opponent.answerElapsedMs = elapsedValue == null ? QUESTION_TIMEOUT_MS : elapsedValue;
                }

                if (resolvingRound) {
                    resolveOnlineRoundIfReady();
                }
            }

            @Override
            public void onCancelled(DatabaseError error) {
            }
        };
        roundSyncRef.addValueEventListener(roundSyncListener);
    }

    private void detachOpponentRoundListener() {
        if (roundSyncRef != null && roundSyncListener != null) {
            roundSyncRef.removeEventListener(roundSyncListener);
        }
        roundSyncListener = null;
    }

    private void submitOnlineAnswer(final int answerKey) {
        if (!modeOnline || gameID == null || gameID.trim().isEmpty()) {
            return;
        }
        roundSyncRef = getRoundSyncRef(currentQuestion);
        if (roundSyncRef == null) {
            return;
        }

        mySubmittedAnswerKey = answerKey;
        myAnswerSubmitted = true;
        resolvingRound = true;
        myAnswerElapsedMs = answerKey == 0 ? QUESTION_TIMEOUT_MS : getCurrentAnswerElapsedMs();

        HashMap<String, Object> payload = new HashMap<>();
        payload.put("players/" + myID + "/answerKey", answerKey);
        payload.put("players/" + myID + "/submitted", true);
        payload.put("players/" + myID + "/correct", answerKey == ANSWER_KEY_RIGHT);
        payload.put("players/" + myID + "/elapsedMs", myAnswerElapsedMs);
        roundSyncRef.updateChildren(payload, (error, ref) -> {
            if (error != null || EXITING) {
                return;
            }
            if (resolvingRound) {
                resolveOnlineRoundIfReady();
            }
        });
    }

    private void resolveOnlineRoundIfReady() {
        if (!modeOnline || roundResolved || resolvingFinal || !resolvingRound || !myAnswerSubmitted || !allOpponentsSubmitted()) {
            return;
        }
        if (roundSyncRef == null) {
            roundSyncRef = getRoundSyncRef(currentQuestion);
        }
        if (roundSyncRef == null) {
            return;
        }
        resolvingFinal = true;  // prevent duplicate Firebase reads

        roundSyncRef.addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                if (EXITING || roundResolved) {
                    resolvingFinal = false;
                    return;
                }
                DataSnapshot mySnapshot = snapshot.child("players").child(myID);
                Long myAnswerKeyValue = mySnapshot.child("answerKey").getValue(Long.class);
                Long myElapsedValue = mySnapshot.child("elapsedMs").getValue(Long.class);
                mySubmittedAnswerKey = myAnswerKeyValue == null ? 0 : myAnswerKeyValue.intValue();
                myAnswerElapsedMs = myElapsedValue == null ? QUESTION_TIMEOUT_MS : myElapsedValue;

                ArrayList<RoundRankEntry> rankedCorrectAnswers = new ArrayList<>();
                if (mySubmittedAnswerKey == ANSWER_KEY_RIGHT) {
                    rankedCorrectAnswers.add(new RoundRankEntry(myID, myAnswerElapsedMs));
                }
                for (MatchOpponent opponent : opponents) {
                    DataSnapshot opponentSnapshot = snapshot.child("players").child(opponent.id);
                    Long answerValue = opponentSnapshot.child("answerKey").getValue(Long.class);
                    Long elapsedValue = opponentSnapshot.child("elapsedMs").getValue(Long.class);
                    opponent.submittedAnswerKey = answerValue == null ? 0 : answerValue.intValue();
                    opponent.answerElapsedMs = elapsedValue == null ? QUESTION_TIMEOUT_MS : elapsedValue;
                    opponent.displayedAnswer = getDisplayedIndexForAnswerKey(opponent.submittedAnswerKey);
                    if (opponent.submittedAnswerKey == ANSWER_KEY_RIGHT) {
                        rankedCorrectAnswers.add(new RoundRankEntry(opponent.id, opponent.answerElapsedMs));
                    }
                }

                Collections.sort(rankedCorrectAnswers, new Comparator<RoundRankEntry>() {
                    @Override
                    public int compare(RoundRankEntry left, RoundRankEntry right) {
                        int byElapsed = Long.compare(left.elapsedMs, right.elapsedMs);
                        if (byElapsed != 0) {
                            return byElapsed;
                        }
                        return Integer.compare(
                                getQuestionTieBreaker(left.playerId, currentQuestion),
                                getQuestionTieBreaker(right.playerId, currentQuestion)
                        );
                    }
                });

                myRoundPoints = getSpeedPoints(myID, rankedCorrectAnswers);
                for (MatchOpponent opponent : opponents) {
                    opponent.roundPoints = getSpeedPoints(opponent.id, rankedCorrectAnswers);
                }
                roundResolved = true;
                resolvingRound = false;
                resolvingFinal = false;

                for (MatchOpponent opponent : opponents) {
                    if (opponent.displayedAnswer > 0) {
                        showThumbPlayerAnswer(opponent, opponent.displayedAnswer);
                    }
                }
                checkAnswer(myAnswer <= 0);
            }

            @Override
            public void onCancelled(DatabaseError error) {
                resolvingFinal = false;  // allow retry on network error
            }
        });
    }

    private int getSpeedPoints(String playerId, ArrayList<RoundRankEntry> rankedCorrectAnswers) {
        if (playerId == null || playerId.trim().isEmpty()) return 0;
        for (int i = 0; i < rankedCorrectAnswers.size(); i++) {
            if (playerId.equals(rankedCorrectAnswers.get(i).playerId)) {
                // 1st=10, 2nd=7, 3rd=5, 4th-10th=3
                return i < ONLINE_SPEED_POINTS.length ? ONLINE_SPEED_POINTS[i] : 3;
            }
        }
        return 0;
    }

    private long getCurrentAnswerElapsedMs() {
        if (questionStartTimeMs > 0L) {
            long elapsedMs = System.currentTimeMillis() - questionStartTimeMs;
            if (elapsedMs <= 0L) {
                return 1L;
            }
            return Math.min(QUESTION_TIMEOUT_MS, elapsedMs);
        }
        // Fallback: use progress counter (100ms resolution)
        long elapsedMs = (300L - Math.max(0, PROGRESS_VALUE)) * 100L;
        if (elapsedMs <= 0L) {
            return 1L;
        }
        return Math.min(QUESTION_TIMEOUT_MS, elapsedMs);
    }

    private int getQuestionTieBreaker(String playerId, int questionIndex) {
        return Math.abs(stableHash((gameID == null ? "" : gameID) + "|" + questionIndex + "|" + playerId));
    }

    private int stableHash(String value) {
        if (value == null) {
            return 0;
        }
        int hash = 5381;
        for (int i = 0; i < value.length(); i++) {
            hash = ((hash << 5) + hash) ^ value.charAt(i);
        }
        return hash & 0x7fffffff;
    }

    private long getServerNowMs() {
        return System.currentTimeMillis() + serverTimeOffsetMs;
    }

    private String safeString(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    private void confirmExit() {
        if (!txtAmount.getText().toString().equals("$0")) {
            showDialog("هل تريد الخروج والاكتفاء بالمبلغ الحالي ؟", "ConfirmHome", 2000, 0, R.drawable.mouth_05, false);
        } else {
            showDialog("هل تريد الانسحاب من المباراة ؟", "ConfirmExit", 2000, 0, R.drawable.mouth_05, false);
        }
    }

    private void showInterstitialAd() {
        AppPrefs.recordInterstitialOpportunity(this);
        if (mInterstitialAd != null && AppPrefs.canShowInterstitialNow(this)) {
            Log.d("TestAdmob", "Ad loaded");
            AppPrefs.markInterstitialShown(this);
            mInterstitialAd.show(this);
        } else {
            Log.d("TestAdmob", "Ad not loaded");
            navigateToHome();
        }
    }

    private void navigateToHome() {
        Intent intent = new Intent(GameActivity.this, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        startActivity(intent);
    }

    private void showThumbPlayerAnswer(int player, int answer) {
        int resId = getResources().getIdentifier("imgAnswer" + answer + "Player" + player, "id", this.getPackageName());
        findViewById(resId).setVisibility(View.VISIBLE);
    }

    private void showThumbPlayerAnswer(MatchOpponent opponent, int answer) {
        if (opponent == null || answer <= 0 || answer > opponentAnswerContainers.size()) {
            return;
        }
        int index = answer - 1;
        if (index >= opponent.answerThumbViews.size()) {
            return;
        }
        opponent.answerThumbViews.get(index).setVisibility(View.VISIBLE);
    }

    private void letsStart() {
        CAN_HOME = true;
        final Handler handler = new Handler();
        handler.postDelayed(new Runnable() {
            int t = 0;

            @Override
            public void run() {
                t++;
                switch (t) {
                    case 1:
                        person.raiseEyeBrowsUp(2000, false, true);
                        person.like(2000);
                        if (modeOnline)
                            showDialog("نبدأ الآن.. استعدوا للمباراة", "", 1000, 3000, R.drawable.mouth_01, false);
                        else
                            showDialog("نبدأ الآن.. استعد للحصول على المليون", "", 1000, 3000, R.drawable.mouth_01, false);
                        handler.postDelayed(this, 5000);
                        break;
                    case 2:
                        playSound(R.raw.lets_play, true, false);
                        person.moveHead(2000);
                        person.lookAside(2500);
                        showDialog("السؤال الأول يقول ..", "", 1000, 2000, R.drawable.mouth_01, false);
                        handler.postDelayed(this, 2000);
                        break;
                    case 3:
                        if (modeOnline) {
                            requestSynchronizedQuestion(0);
                        } else {
                            nextQuestion();
                        }
                        break;
                }

            }
        }, 1000);
    }

    private void finishGame() {
        leaveOnlineMatchIfNeeded();
        stopSound(mpSound);
        stopTimer(false);
        if (!txtAmount.getText().toString().equals("$0")) {
            person.like(1000);
            person.raiseEyeBrowsUp(1000, true, true);
            showDialog("تهانينا.. لقد حصلت على مبلغ " + txtAmount.getText().toString(), "", 2000, 3000, R.drawable.mouth_01, false);
        } else {
            person.moveShowHandGrip(1000);
            person.raiseEyeBrowsUp(1000, true, false);
            showDialog("حظا أفضل في المرة القادمة", "", 2000, 2000, R.drawable.mouth_05, false);
        }
        (new Handler()).postDelayed(new Runnable() {
            @Override
            public void run() {
                try {
                    int prize = Integer.parseInt(txtAmount.getText().toString().replace("$", "").trim());
                    PlayerStats.recordGameEnd(GameActivity.this, false, prize);
                    PlayerProgress.onGameFinished(GameActivity.this, false, prize, PlayerStats.getBestStreak(GameActivity.this), usedAllHelps(), usedAnyHelp());
                } catch (Exception ignored) {}
                stopSound(mpSound);
                if (cdtProgress != null) cdtProgress.cancel();
                showInterstitialAd();
            }
        }, 2000);
    }

    private void startTimer(boolean start) {
        int randomTime = 15;
        if (!EXITING) {
            if (start) {
                PROGRESS_VALUE = 300;
                //TIMER_VALUE = 10000;
                pbTime.setRingProgressColor(getResources().getColor(R.color.progressGreen));
                pbTime.setProgress(0);
                txtProgress.setText("30");
                if (modeOnline && hasBotOpponents()) {
                    randomTime = getFictitiousRandomTime();
                }
                Animations.progressZoomIn(rlyProgress);
                if (modeOnline) {
                    scheduleBotAnswersForCurrentQuestion();
                }
            }
            final int finalRandomTime = randomTime;
            cdtProgress = new CountDownTimer(50000, 100) {
                int pbText;

                @Override
                public void onTick(long l) {
                    //TIMER_VALUE = l;
                    PROGRESS_VALUE--;
                    if (PROGRESS_VALUE > 0) pbTime.setProgress(PROGRESS_VALUE);
                    if ((PROGRESS_VALUE % 10) == 0) {
                        pbText = PROGRESS_VALUE / 10;
                        txtProgress.setText(pbText + "");
                        if (pbText > 10)
                            pbTime.setRingProgressColor(getResources().getColor(R.color.progressGreen));
                        else if (pbText > 5) {
                            if (SOUND_ON)
                            mpBeep.start();
                            pbTime.setRingProgressColor(getResources().getColor(R.color.progressOrange));
                        } else if (pbText > 0) {
                            if (SOUND_ON)
                            mpBeep1.start();
                            pbTime.setRingProgressColor(getResources().getColor(R.color.progressRed));
                        } else {
                            this.cancel();
                            PROGRESS_VALUE = 300;
                            //TIMER_VALUE = 10000;
                            if (modeOnline) {
                                CAN_PLAY = false;
                                // Only submit timeout if the player hasn't already
                                // submitted (or selected an answer awaiting confirm).
                                // This prevents the timer from overwriting a valid
                                // answer with a timeout right before resolution.
                                if (!myAnswerSubmitted) {
                                    submitOnlineAnswer(0);
                                    resolveOnlineRoundIfReady();
                                }
                            } else {
                                checkAnswer(true);
                            }
                            //onWrongAnswer(true);
                            /*if(modeOnline) {
                                if(opponentAnswer>0) {
                                    showThumbPlayerAnswer(2, opponentAnswer);
                                    checkAnswer();
                                    //Toast.makeText(GameActivity.this, "Opponent answer : "+opponentAnswer, Toast.LENGTH_SHORT).show();
                                }

                            }*/
                        }
                    }
                }

                @Override
                public void onFinish() {
                }
            }.start();
        }
    }

    private void stopTimer(boolean pause) {
        if (cdtProgress != null) {
            cdtProgress.cancel();
        }
        if (!pause) {
            Animations.progressZoomOut(rlyProgress);
            //TIMER_VALUE = 10000;
            PROGRESS_VALUE = 300;
        }
    }

    private void animLights() {
        final ImageView imgLight1, imgLight2, imgLight3, imgLight4;

        final ImageView imgShadow;
        imgShadow = findViewById(R.id.imgShadow);
        imgLight1 = findViewById(R.id.imgLight1);
        imgLight2 = findViewById(R.id.imgLight2);
        imgLight3 = findViewById(R.id.imgLight3);
        imgLight4 = findViewById(R.id.imgLight4);


        final Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            boolean toLeft = true;
            int d;

            @Override
            public void run() {
                T_LIGHTS++;
                d = FAST_LIGHTS ? 250 : 1000;
                if ((FAST_LIGHTS) || ((!FAST_LIGHTS) && (T_LIGHTS == 4))) {
                    T_LIGHTS = 0;
                    if (toLeft) {
                        Animations.rotateLight(imgLight1, -20f, 20f, d);
                        Animations.rotateLight(imgLight2, 20f, -20f, d);
                        Animations.rotateLight(imgLight3, -20f, 20f, d);
                        Animations.rotateLight(imgLight4, 20f, -20f, d);
                        toLeft = false;
                    } else {
                        if (FAST_LIGHTS) Animations.fadeShadow(imgShadow);
                        Animations.rotateLight(imgLight1, 20f, -20f, d);
                        Animations.rotateLight(imgLight2, -20f, 20f, d);
                        Animations.rotateLight(imgLight3, 20f, -20f, d);
                        Animations.rotateLight(imgLight4, -20f, 20f, d);
                        toLeft = true;
                    }
                }
                handler.postDelayed(this, 250);
            }
        };
        handler.postDelayed(runnable, 0);
    }

    private void goBlinking() {
        final Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                int times = (new Random()).nextInt(2) + 1;
                int delay = (new Random()).nextInt(5) + 3;
                person.blinkEyes(times);
                handler.postDelayed(this, delay * 1000);
            }
        };
        handler.postDelayed(runnable, 1000);
    }

    private void onWrongAnswer(boolean timeOut) {
        CAN_HOME = false;
        CAN_CLICK = false;
        CAN_PLAY = false;
        PlayerStats.recordWrongAnswer(GameActivity.this);
        playSound(R.raw.wrong_answer, false, false);
        person.sad();
        imgRight.setImageResource(R.drawable.frame_right);
        if (timeOut) {
            showDialog("انتهى الوقت للأسف", "", 1000, 2000, R.drawable.mouth_05, false);
        } else {
            imgSelected.setImageResource(R.drawable.frame_wrong);
            showDialog("إجابة خاطئة للأسف", "", 1000, 2000, R.drawable.mouth_05, false);
        }

        if (!modeOnline) {
            final Handler handler = new Handler();
            Runnable runnable = new Runnable() {
                int t = 0;

                @Override
                public void run() {
                    t++;
                    switch (t) {
                        case 1:
                            if (currentQuestion > 9) {
                                txtAmount.setText("$32000");
                                person.moveShow2Hands(2000);
                                person.raiseEyeBrowsUp(2000, true, true);
                                showDialog("على كل حال لقد فزت بمبلغ $32000\nألف مبروك", "", 2000, 3000, R.drawable.mouth_01, false);
                            } else if (currentQuestion > 4) {
                                txtAmount.setText("$1000");
                                person.moveShow2Hands(2000);
                                person.raiseEyeBrowsUp(2000, true, true);
                                showDialog("على كل حال لقد فزت بمبلغ $1000\nألف مبروك", "", 2000, 3000, R.drawable.mouth_01, false);
                            } else {
                                txtAmount.setText("$0");
                                person.moveShowHand(2000);
                                showDialog("للأسف لم تصل إلى مرحلة تثبيت المبلغ\n حظا أفضل في المرة القادمة", "", 2000, 3000, R.drawable.mouth_01, false);
                            }
                            CAN_HOME = false;
                            handler.postDelayed(this, 4000);
                            break;
                        case 2:
                            // سجّل نتيجة اللعبة مع المبلغ المثبت (إن لم يخرج اللاعب يدوياً)
                            if (!EXITING) {
                                try {
                                    int safeHavenPrize = Integer.parseInt(
                                        txtAmount.getText().toString().replace("$", "").trim());
                                    PlayerStats.recordGameEnd(GameActivity.this, false, safeHavenPrize);
                                    PlayerProgress.onGameFinished(GameActivity.this, false, safeHavenPrize,
                                        PlayerStats.getBestStreak(GameActivity.this), usedAllHelps(), usedAnyHelp());
                                } catch (Exception ignored) {}
                            }
                            showInterstitialAd();
                            break;
                    }

                }
            };
            handler.postDelayed(runnable, 3000);
        }
    }



        /*else {
            if(opponentAnswer>0) {
                showThumbPlayerAnswer(2, opponentAnswer);
                if (opponentAnswer == rightAnswer) {
                    int amount = Integer.parseInt(getCurrentStepAmount().replace("$",""));
                    setScoreOpponent += amount;
                    gameScoreOpponent += amount;
                    txtScoreOpponent.setText(gameScoreOpponent+"");
                }
            }
            final Handler handler = new Handler();
            Runnable runnable = new Runnable() {
                int t = 0;
                @Override
                public void run() {
                    t++;
                    switch(t) {
                        case 1:
                            if (checkScores()) {
                                if(checkEndOfGame()) {
                                    t=3;
                                }
                                handler.postDelayed(this, 3000);
                            } else {
                                handler.postDelayed(this, 1000);
                            }
                            break;
                        case 2:
                            initQuestion();
                            nextStep();
                            playSound(R.raw.lets_play, true, false);
                            String currentStepAmount = getCurrentStepAmount();
                            person.moveHead(1000);
                            person.lookAside(600);
                            showDialog("السؤال التالي قيمته\n" + currentStepAmount, "", 1000, 3000, R.drawable.mouth_02, false);
                            CAN_HOME = true;
                            handler.postDelayed(this, 4000);
                            break;
                        case 3:
                            nextQuestion();
                            break;
                        case 4:
                            goToWinnerScreen(gameScoreMe+"$");
                            break;
                    }
                }
            };
            handler.postDelayed(runnable, 3000);
        }*/


    public static void  setGreyscale(ImageView v)
    {
        ColorMatrix matrix = new ColorMatrix();
        matrix.setSaturation(0);  //0 means grayscale
        ColorMatrixColorFilter cf = new ColorMatrixColorFilter(matrix);
        v.setColorFilter(cf);
    }

    public static void  setColored(ImageView v)
    {
        v.setColorFilter(null);
        v.setImageAlpha(255);
    }

    private void initQuestion() {
        rightAnswer=0;
        txtQ.setText("");
        txtA1.setVisibility(View.VISIBLE);
        txtA2.setVisibility(View.VISIBLE);
        txtA3.setVisibility(View.VISIBLE);
        txtA4.setVisibility(View.VISIBLE);
        txtA1.setText("");
        txtA2.setText("");
        txtA3.setText("");
        txtA4.setText("");
        imgA1.setImageResource(R.drawable.frame);
        imgA2.setImageResource(R.drawable.frame);
        imgA3.setImageResource(R.drawable.frame);
        imgA4.setImageResource(R.drawable.frame);
        imgVote1.setTag(0);
        imgVote2.setTag(0);
        imgVote3.setTag(0);
        imgVote4.setTag(0);
        setVote(imgVote1);
        setVote(imgVote2);
        setVote(imgVote3);
        setVote(imgVote4);
        if(modeOnline) {
            imgAnswer1Player1.setVisibility(View.INVISIBLE);
            imgAnswer2Player1.setVisibility(View.INVISIBLE);
            imgAnswer3Player1.setVisibility(View.INVISIBLE);
            imgAnswer4Player1.setVisibility(View.INVISIBLE);
            myAnswer = 0;
            opponentAnswer = 0;
            myAnswerSubmitted = false;
            resolvingRound = false;
            roundResolved = false;
            resolvingFinal = false;
            mySubmittedAnswerKey = 0;
            myRoundPoints = 0;
            myAnswerElapsedMs = QUESTION_TIMEOUT_MS;
            questionStartTimeMs = 0L;
            currentAnswerOrder.clear();
            cancelPendingFictitiousAnswer();
            detachOpponentRoundListener();
            detachQuestionSyncListener();
            for (MatchOpponent opponent : opponents) {
                opponent.displayedAnswer = 0;
                opponent.submitted = false;
                opponent.submittedAnswerKey = 0;
                opponent.roundPoints = 0;
                opponent.answerElapsedMs = QUESTION_TIMEOUT_MS;
            }
            refreshOpponentPanels();
        }
        //imgHelp5050.setImageResource(R.drawable.help_5050);
        //imgHelpCall.setImageResource(R.drawable.help_call);
        //imgHelpAudience.setImageResource(R.drawable.help_audience);
    }

    private String getStepAmount(int nStep) {
        TextView txtAmount = (TextView) steps.get(nStep).getChildAt(1);
        return txtAmount.getText().toString();
    }

    private String getCurrentStepAmount() {
        TextView txtAmount = (TextView) steps.get(currentStep).getChildAt(1);
        return txtAmount.getText().toString();
    }

    private void nextStep() {
        steps.get(currentStep).setBackgroundResource(R.color.darkBlueApp);
        currentStep++;
        if(currentStep < steps.size())
            steps.get(currentStep).setBackgroundResource(R.color.stepSelected);
    }

    private void nextQuestion() {
        showQuestionNow(currentQuestion + 1);
    }

    private void showQuestionNow(final int questionIndex) {
        if(!EXITING) {
            currentQuestion = questionIndex;
            spectatorEliminationRound = eliminationMode && localPlayerEliminated;
            scheduledQuestionStartAt = 0L;
            pendingQuestionIndex = -1;
            if (currentQuestion < questions.size()) {
                CAN_HOME = true;
                final Question question = questions.get(currentQuestion);
                if (currentQuestion < 9) {
                    playSound(R.raw.s_32000, true, true);
                } else if (currentQuestion == 10) {
                    playSound(R.raw.s_32000, true, true);
                } else if (currentQuestion == 11) {
                    playSound(R.raw.s_64000, true, true);
                } else if (currentQuestion == 12) {
                    playSound(R.raw.s_250000, true, true);
                } else if (currentQuestion == 13) {
                    playSound(R.raw.s_5000000, true, true);
                } else {
                    playSound(R.raw.s_1000000, true, true);
                }

                txtQ.setText(question.Q);
                applyQuestionTextSize(question.Q);

                final ArrayList<Integer> answerOrder = getQuestionShuffled(question);
                currentAnswerOrder.clear();
                currentAnswerOrder.addAll(answerOrder);

                final Handler handler = new Handler();
                Runnable runnable = new Runnable() {
                    int i = -1;

                    @Override
                    public void run() {
                        if(!EXITING) {
                            i++;
                            switch (i) {
                                case 0:
                                case 1:
                                case 2:
                                case 3:
                                    int answerKey = answerOrder.get(i);
                                    String answerText = getAnswerText(question, answerKey);
                                    listAnswerViews.get(i).setText(getLetter(i + 1) + " - " + answerText);
                                    applyAnswerTextSize(listAnswerViews.get(i), answerText);
                                    if (answerKey == ANSWER_KEY_RIGHT) {
                                        rightAnswer = i+1;
                                        listAnswerViews.get(i).setTag("1");
                                        txtRight = listAnswerViews.get(i);
                                        rlyRight = (RelativeLayout) ((ViewGroup) txtRight.getParent());
                                        imgRight = (ImageView) rlyRight.getChildAt(0);
                                    } else {
                                        listAnswerViews.get(i).setTag("0");
                                    }
                                    handler.postDelayed(this, 1000);
                                    break;
                                case 4:
                                    CAN_PLAY = !spectatorEliminationRound;
                                    questionStartTimeMs = System.currentTimeMillis();
                                    startTimer(true);
                                    if(modeOnline) {
                                        Data.initQuestionPlayer(gameID, myID, currentQuestion);
                                        for (MatchOpponent opponent : opponents) {
                                            Data.initQuestionPlayer(gameID, opponent.id, currentQuestion);
                                        }
                                        opponentAnswer = 0;
                                        prepareOnlineQuestionSync(currentQuestion);
                                        attachOpponentRoundListener(currentQuestion);
                                        autoSubmitSpectatorEliminationRound();
                                    }
                                    break;
                            }
                        }
                    }
                };
                handler.postDelayed(runnable, 1000);

            } else {
                Toast.makeText(this,
                        "خطأ أثناء الانصال .. لا يمكنك الاتصال بالخادم. تحقق من اتصالك بالانترنت ثم حاول مرة أخرى.",
                        Toast.LENGTH_LONG).show();
            }
        }
    }

    private String getLetter(int index) {
        String res = "";
        switch (index) {
            case 1: res = "أ"; break;
            case 2: res = "ب"; break;
            case 3: res = "ج"; break;
            case 4: res = "د"; break;
        }
        return  res;
    }

    private ArrayList<Integer> getQuestionShuffled(Question question) {
        ArrayList<Integer> list = new ArrayList<>();
        list.add(ANSWER_KEY_RIGHT);
        list.add(ANSWER_KEY_WRONG_1);
        list.add(ANSWER_KEY_WRONG_2);
        list.add(ANSWER_KEY_WRONG_3);
        if (modeOnline) {
            long seed = 17L;
            seed = (31L * seed) + currentQuestion;
            seed = (31L * seed) + (gameID == null ? 0 : gameID.hashCode());
            seed = (31L * seed) + (question == null || question.Q == null ? 0 : question.Q.hashCode());
            Collections.shuffle(list, new Random(seed));
        } else {
            Collections.shuffle(list);
        }
        return list;
    }

    private String getAnswerText(Question question, int answerKey) {
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

    private int getAnswerKeyForDisplayedIndex(int displayedIndex) {
        if (displayedIndex <= 0 || displayedIndex > currentAnswerOrder.size()) {
            return 0;
        }
        return currentAnswerOrder.get(displayedIndex - 1);
    }

    private int getDisplayedIndexForAnswerKey(int answerKey) {
        for (int i = 0; i < currentAnswerOrder.size(); i++) {
            if (currentAnswerOrder.get(i) == answerKey) {
                return i + 1;
            }
        }
        return 0;
    }

    private int getRightAnswer() {
        int id = txtRight.getId();
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

    private void playSound(int resID, boolean fading, boolean looping) {
        if(!EXITING) {
            boolean targetIsMusic = isMusicTrack(resID, looping);
            if (targetIsMusic) {
                MUSIC_ON = AppPrefs.isMusicEnabled(this);
                if (!MUSIC_ON) {
                    stopSound(mpSound);
                    mpSound = null;
                    currentSoundIsMusic = false;
                    return;
                }
            } else {
                SOUND_ON = AppPrefs.isSoundEnabled(this);
                if (!SOUND_ON) {
                    return;
                }
            }
            if (fading) {
                if (targetIsMusic ? MUSIC_ON : SOUND_ON) {
                    fadeSound(mpSound);
                } else {
                    stopSound(mpSound);
                }
            } else {
                stopSound(mpSound);
            }
            //stopSound(mpSound);
            mpSound = MediaPlayer.create(GameActivity.this, resID);
            currentSoundIsMusic = targetIsMusic;
            mpSound.setLooping(looping);
            mpSound.start();
        }
    }

    private boolean isMusicTrack(int resID, boolean looping) {
        return looping
                || resID == R.raw.main_theme_0
                || resID == R.raw.main_theme_1
                || resID == R.raw.main_theme_2
                || resID == R.raw.main_theme_3
                || resID == R.raw.main_theme_4
                || resID == R.raw.main_theme_5
                || resID == R.raw.commerical_break
                || resID == R.raw.s_32000
                || resID == R.raw.s_64000
                || resID == R.raw.s_250000
                || resID == R.raw.s_5000000
                || resID == R.raw.s_1000000;
    }

    private void fadeSound(MediaPlayer mpSound) {
        if(mpSound != null) {
            try {
                final MediaPlayer mps = mpSound;
                final Handler handler = new Handler();
                final Runnable runnable = new Runnable() {
                    int currentVolumeStep = 10;
                    float currentVolume;
                    MediaPlayer mp = mps;

                    @Override
                    public void run() {
                        currentVolumeStep--;
                        currentVolume = (float) (1 - (Math.log(10 - currentVolumeStep) / Math.log(10)));
                        mp.setVolume(currentVolume, currentVolume);
                        if (currentVolumeStep > 0)
                            handler.postDelayed(this, 100);
                        else
                            stopSound(mp);
                    }
                };
                handler.postDelayed(runnable, 100);

            } catch (Exception e) {

            }
        }
    }

    private void stopSound(MediaPlayer mp) {
        if (mp != null) {
            try {
                if (mp.isPlaying()) {
                    mp.stop();
                }
                mp.release();
                if (mp == mpSound) {
                    currentSoundIsMusic = false;
                }
            } catch (Exception ignored) {
            }
        }
    }

    private void showDialog(final String message, final String tag, final int timeTalk, final int timeDialog, final int nextMouthId, final boolean gameStatusAfter) {
        if(!EXITING) {
            btnDialogYes.setVisibility(View.INVISIBLE);
            btnDialogNo.setVisibility(View.INVISIBLE);
            final Handler handler = new Handler();
            Runnable runnable = new Runnable() {
                boolean firstRun = true;

                @Override
                public void run() {
                    if (firstRun) {
                        firstRun = false;
                        CAN_PLAY = false;
                        CAN_HOME = false;
                        currentDialog = tag;
                        int msgLen = message.replace("\n", "").length();
                        if (msgLen <= 25)
                            txtDialog.setTextSize(TypedValue.COMPLEX_UNIT_SP, 15);
                        else if (msgLen <= 40)
                            txtDialog.setTextSize(TypedValue.COMPLEX_UNIT_SP, 13);
                        else if (msgLen <= 55)
                            txtDialog.setTextSize(TypedValue.COMPLEX_UNIT_SP, 11);
                        else
                            txtDialog.setTextSize(TypedValue.COMPLEX_UNIT_SP, 9);
                        txtDialog.setCharacterDelay(18);
                        txtDialog.animateText(message);
                        rlyDialog.setVisibility(View.VISIBLE);
                        rlyDialog.bringToFront();
                        Animations.dialogZoom(rlyDialog, 4, 150, 1.05f);
                        person.talk(timeTalk, nextMouthId);
                        if (timeDialog > 0) {
                            btnDialogYes.setVisibility(View.INVISIBLE);
                            btnDialogNo.setVisibility(View.INVISIBLE);
                            txtDialog.setPadding(30, 10, 20, 30);
                            handler.postDelayed(this, timeDialog);
                        } else {
                            CAN_CLICK = true;
                            btnDialogYes.setVisibility(View.VISIBLE);
                            btnDialogNo.setVisibility(View.VISIBLE);
                            txtDialog.setPadding(30, 10, 20, 50);
                            if ("OpponentLeftContinue".equals(tag)) {
                                btnDialogYes.setText("أكمل");
                                btnDialogNo.setText("إنهاء");
                            } else if ("EliminationSpectatorChoice".equals(tag)) {
                                btnDialogYes.setText("متابعة");
                                btnDialogNo.setText("خروج");
                            } else if (timeDialog == 0) {
                                btnDialogYes.setText("نعم");
                                btnDialogNo.setText("لا");
                            } else {
                                btnDialogYes.setText("التالي");
                                btnDialogNo.setText("شكرا");
                            }
                        }
                    } else {
                        rlyDialog.setVisibility(View.INVISIBLE);
                        CAN_PLAY = gameStatusAfter;
                        CAN_HOME = true;
                    }

                }
            };
            handler.postDelayed(runnable, 0);
        }
    }

    public void phoneTalk(int duration) {
        imgCallerMouth.setImageResource(R.drawable.smile_02);
        CountDownTimer cdt = new CountDownTimer(duration, 100) {
            int status_mouth = 0;
            @Override
            public void onTick(long l) {
                switch (status_mouth) {
                    case 0:
                        imgCallerMouth.setImageResource(R.drawable.smile_02);
                        status_mouth++;
                        break;
                    case 1:
                        imgCallerMouth.setImageResource(R.drawable.smile_04);
                        status_mouth++;
                        break;
                    case 2:
                        imgCallerMouth.setImageResource(R.drawable.smile_03);
                        status_mouth++;
                        break;
                    case 3:
                        imgCallerMouth.setImageResource(R.drawable.smile_05);
                        status_mouth = 0;
                        break;
                }
            }

            @Override
            public void onFinish() {
                imgCallerMouth.setImageResource(R.drawable.smile_01);
            }
        }.start();
    }


    private void help_hideTwoAnswers() {
        ArrayList<Integer> idxs = new ArrayList<>();
        int idx;
        while (idxs.size()<2) {
            do {
                idx = (new Random()).nextInt(4);
            } while ((idxs.contains(idx)) || (listAnswerViews.get(idx).getTag().toString().equals("1")));
            idxs.add(idx);
        }
        listAnswerViews.get(idxs.get(0)).setVisibility(View.INVISIBLE);
        listAnswerViews.get(idxs.get(1)).setVisibility(View.INVISIBLE);

        CAN_PLAY = true;
    }

    private void help_getVoteAudience() {
        playSound(R.raw.main_theme_2,true, false);
        rlyVotes.setVisibility(View.VISIBLE);
        boolean audienceSure = (currentQuestion < 5) ? true : (((new Random()).nextInt(2)+1) == 1);
        int[] vote = new int[4];
        int tmp;
        if (audienceSure) {
            vote[0] = (new Random()).nextInt(20)+70;
            tmp=100-vote[0];
            vote[1] = (new Random()).nextInt(tmp)+1;
            tmp=100-(vote[0]+vote[1]);
            if (tmp > 0) {
                vote[2] = (new Random()).nextInt(tmp)+1;
                tmp=100-(vote[0]+vote[1]+vote[2]);
                if (tmp > 0) vote[3] = tmp;
            }

            int idVote;
            int rightAnswer = getRightAnswer();
            int idxVotes = 0;
            ImageView imgVote;
            for(int i=1;i<=4;i++){
                idVote = getResources().getIdentifier("imgVote"+i,"id",this.getPackageName());
                imgVote =(ImageView) findViewById(idVote);
                if(i == rightAnswer) {
                    imgVote.setTag(vote[0]);
                } else {
                    idxVotes ++;
                    imgVote.setTag(vote[idxVotes]);
                }
            }
        } else {
            vote[0] = (new Random()).nextInt(20)+20;
            tmp=(100-vote[0])/3;
            vote[1] = (new Random()).nextInt(tmp)+1;
            tmp=(100-(vote[0]+vote[1]))/2;
            vote[2] = (new Random()).nextInt(tmp)+1;
            vote[3]=100-(vote[0]+vote[1]+vote[2]);
            imgVote1.setTag(vote[0]);
            imgVote2.setTag(vote[1]);
            imgVote3.setTag(vote[2]);
            imgVote4.setTag(vote[3]);
        }

        setVote(imgVote1);
        setVote(imgVote2);
        setVote(imgVote3);
        setVote(imgVote4);

        (new Handler()).postDelayed(new Runnable() {
            @Override
            public void run() {
                btnCloseVote.setVisibility(View.VISIBLE);
                playSound(R.raw.s_32000,true, false);
                startTimer(false);
                CAN_PLAY = true;
                showDialog("ماهي إجابتك ؟", "", 1000, 2000, R.drawable.mouth_06, true);
            }
        }, 6000);

    }

    private void setVote(ImageView img) {
        int vote = (Integer)img.getTag();
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) img.getLayoutParams();
        final float scale = this.getResources().getDisplayMetrics().density;
        int pVote = (int) (vote * scale + 0.5f);
        params.height = pVote;
        img.setLayoutParams(params);

        TranslateAnimation anim = new TranslateAnimation(0, 0, pVote, 0);
        anim.setFillAfter(true);
        anim.setDuration(5000);
        img.startAnimation(anim);
    }

    private void help_call() {

        final LinearLayout llyWavesR, llyWavesL;
        final ImageView imgWaveR1, imgWaveR2, imgWaveR3, imgWaveL1, imgWaveL2, imgWaveL3;

        llyWavesR = findViewById(R.id.llyWavesR);
        llyWavesL = findViewById(R.id.llyWavesL);
        imgWaveR1 = findViewById(R.id.imgWaveR1);
        imgWaveR2 = findViewById(R.id.imgWaveR2);
        imgWaveR3 = findViewById(R.id.imgWaveR3);
        imgWaveL1 = findViewById(R.id.imgWaveL1);
        imgWaveL2 = findViewById(R.id.imgWaveL2);
        imgWaveL3 = findViewById(R.id.imgWaveL3);


        int rnd, idImage;
        rnd = (new Random()).nextInt(6)+1;
        idImage = this.getResources().getIdentifier("face_0"+rnd, "drawable", this.getPackageName());
        imgCallerFace.setImageResource(idImage);
        rnd = (new Random()).nextInt(3)+1;
        idImage = this.getResources().getIdentifier("circle_body_0"+rnd, "drawable", this.getPackageName());
        imgCallerBody.setImageResource(idImage);

        playSound(R.raw.phone_friend, true, false);
        setGreyscale(imgCallerBody);
        setGreyscale(imgCallerFace);
        setGreyscale(imgCallerMouth);
        rlyCall.setVisibility(View.VISIBLE);
        llyWavesR.setVisibility(View.VISIBLE);
        llyWavesL.setVisibility(View.VISIBLE);
        imgWaveR1.setImageAlpha(0);
        imgWaveR2.setImageAlpha(0);
        imgWaveR3.setImageAlpha(0);
        imgWaveL1.setImageAlpha(0);
        imgWaveL2.setImageAlpha(0);
        imgWaveL3.setImageAlpha(0);
        new CountDownTimer(20000, 200) {
            int t=0;
            @Override
            public void onTick(long l) {
                t++;
                switch (t) {
                    case 1:
                    case 6:
                    case 11:
                        imgWaveR1.setImageAlpha(255);
                        imgWaveL1.setImageAlpha(255);
                        imgWaveR2.setImageAlpha(0);
                        imgWaveL2.setImageAlpha(0);
                        imgWaveR3.setImageAlpha(0);
                        imgWaveL3.setImageAlpha(0);
                        break;
                    case 2:
                    case 7:
                    case 12:
                        imgWaveR1.setImageAlpha(128);
                        imgWaveL1.setImageAlpha(128);
                        imgWaveR2.setImageAlpha(255);
                        imgWaveL2.setImageAlpha(255);
                        imgWaveR3.setImageAlpha(0);
                        imgWaveL3.setImageAlpha(0);
                        break;
                    case 3:
                    case 8:
                    case 13:
                        imgWaveR1.setImageAlpha(0);
                        imgWaveL1.setImageAlpha(0);
                        imgWaveR2.setImageAlpha(128);
                        imgWaveL2.setImageAlpha(128);
                        imgWaveR3.setImageAlpha(255);
                        imgWaveL3.setImageAlpha(255);
                        break;
                    case 4:
                    case 9:
                    case 14:
                        imgWaveR1.setImageAlpha(0);
                        imgWaveL1.setImageAlpha(0);
                        imgWaveR2.setImageAlpha(0);
                        imgWaveL2.setImageAlpha(0);
                        imgWaveR3.setImageAlpha(128);
                        imgWaveL3.setImageAlpha(128);
                        break;
                    case 5:
                    case 10:
                    case 15:
                        imgWaveR1.setImageAlpha(0);
                        imgWaveL1.setImageAlpha(0);
                        imgWaveR2.setImageAlpha(0);
                        imgWaveL2.setImageAlpha(0);
                        imgWaveR3.setImageAlpha(0);
                        imgWaveL3.setImageAlpha(0);
                        break;
                    case 20:
                        llyWavesR.setVisibility(View.INVISIBLE);
                        llyWavesL.setVisibility(View.INVISIBLE);
                        setColored(imgCallerBody);
                        setColored(imgCallerFace);
                        setColored(imgCallerMouth);
                        break;
                    case 25:
                        int rndSure = (currentQuestion < 5) ? 10 : (new Random().nextInt(10)+1);
                        String answer;
                        if(rndSure > 7) {
                            answer = "أنا متأكد أن الجواب هو "+getLetter(getRightAnswer());
                        } else if (rndSure > 2) {
                            int rnd = new Random().nextInt(4)+1;
                            answer = "ممممم.. أعتقد أن الإجابة هي "+getLetter(rnd);
                        } else {
                            answer = "في الحقيقة لا أعرف الإجابة";
                        }
                        txtCallAnswer.setVisibility(View.VISIBLE);
                        txtCallAnswer.setCharacterDelay(18);
                        txtCallAnswer.animateText(answer);
                        playSound(R.raw.blabla,false, false);
                        phoneTalk(3000);
                        break;
                    case 40:
                        mpSound.stop();
                        txtCallAnswer.setVisibility(View.INVISIBLE);
                        break;
                    case 45:
                        setGreyscale(imgCallerBody);
                        setGreyscale(imgCallerFace);
                        setGreyscale(imgCallerMouth);
                        break;
                    case 50:
                        this.cancel();
                        rlyCall.setVisibility(View.INVISIBLE);
                        playSound(R.raw.s_32000,true, false);
                        startTimer(false);
                        CAN_PLAY = true;
                        showDialog("ماهي إجابتك ؟", "", 1000, 2000, R.drawable.mouth_06, true);
                        break;
                }
            }

            @Override
            public void onFinish() {}
        }.start();
    }

    @Override
    protected void onPause() {
        if(cdtProgress != null) cdtProgress.cancel();
        releasePlayer(mpSound);
        mpSound = null;
        releasePlayer(mpBeep);
        mpBeep = null;
        releasePlayer(mpBeep1);
        mpBeep1 = null;
        super.onPause();
    }

    @Override
    protected void onDestroy() {
        cancelPendingFictitiousAnswer();
        if (isFinishing()) {
            leaveOnlineMatchIfNeeded();
        }
        detachOpponentStatusListener();
        detachOpponentRoundListener();
        detachQuestionSyncListener();
        detachServerTimeOffsetListener();
        if(cdtProgress != null) cdtProgress.cancel();
        releasePlayer(mpSound);
        mpSound = null;
        releasePlayer(mpBeep);
        mpBeep = null;
        releasePlayer(mpBeep1);
        mpBeep1 = null;
        super.onDestroy();
    }

    @Override
    public void onWindowFocusChanged(boolean hasFocus) {
        super.onWindowFocusChanged(hasFocus);
        if (hasFocus) {
            getWindow().getDecorView().setSystemUiVisibility(
                    View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                            | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                            | View.SYSTEM_UI_FLAG_FULLSCREEN
                            | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }

    @Override
    public void onBackPressed() {
        confirmExit();

        /*
        AlertDialog.Builder builder = new AlertDialog.Builder(this);
        builder.setMessage("هل تريد حقا الخروج من المباراة ؟")
                .setPositiveButton("نعم", dialogClickListener)
                .setNegativeButton("لا", dialogClickListener)
                .show();

        stopSound(mpSound);
        if(cdtProgress != null) cdtProgress.cancel();
        showInterstitialAd();
        */
    }

    private void initAdsIfNeeded() {
        try {
            if (mInterstitialAd == null) {
                MobileAds.initialize(this, initializationStatus -> {});
                InterstitialAd.load(this,
                    getResources().getString(R.string.interstitial_ad_id),
                    new AdRequest.Builder().build(),
                    new InterstitialAdLoadCallback() {
                        @Override
                        public void onAdLoaded(InterstitialAd ad) {
                            mInterstitialAd = ad;
                            mInterstitialAd.setFullScreenContentCallback(new FullScreenContentCallback() {
                                @Override
                                public void onAdDismissedFullScreenContent() {
                                    mInterstitialAd = null;
                                    navigateToHome();
                                }
                            });
                        }
                        @Override
                        public void onAdFailedToLoad(LoadAdError error) {
                            mInterstitialAd = null;
                        }
                    });
            }
        } catch (Exception e) {
            Log.w("GameActivity", "initAdsIfNeeded failed", e);
        }
    }

    private void updateInventoryBadges() {
        updateBadge(R.id.badge5050,    PlayerProgress.getInventory5050(this));
        updateBadge(R.id.badgeCall,    PlayerProgress.getInventoryCall(this));
        updateBadge(R.id.badgeAudience, PlayerProgress.getInventoryAudience(this));
    }

    private void updateBadge(int badgeId, int count) {
        android.widget.TextView badge = findViewById(badgeId);
        if (badge == null) return;
        if (count > 0) {
            badge.setText(String.valueOf(count));
            badge.setVisibility(View.VISIBLE);
        } else {
            badge.setVisibility(View.GONE);
        }
    }

    private void releasePlayer(MediaPlayer player) {
        if (player == null) return;
        try {
            if (player.isPlaying()) {
                player.stop();
            }
        } catch (Exception ignored) {
        }
        try {
            player.reset();
        } catch (Exception ignored) {
        }
        try {
            player.release();
        } catch (Exception ignored) {
        }
    }


}





