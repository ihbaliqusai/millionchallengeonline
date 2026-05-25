package net.androidgaming.millionaire2024;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;
import android.content.DialogInterface;
import android.content.Intent;
import android.graphics.Color;
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
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;
import android.widget.TextView;
import android.widget.Toast;
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
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.MutableData;
import com.google.firebase.database.Query;
import com.google.firebase.database.Transaction;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Locale;

import static net.androidgaming.millionaire2024.GameRules.ANSWER_KEY_RIGHT;
import static net.androidgaming.millionaire2024.GameRules.ANSWER_KEY_WRONG_1;
import static net.androidgaming.millionaire2024.GameRules.ANSWER_KEY_WRONG_2;
import static net.androidgaming.millionaire2024.GameRules.ANSWER_KEY_WRONG_3;
import static net.androidgaming.millionaire2024.GameRules.FIRST_QUESTION_SYNC_BUFFER_MS;
import static net.androidgaming.millionaire2024.GameRules.MAX_TIMEOUT_STREAK;
import static net.androidgaming.millionaire2024.GameRules.NEXT_QUESTION_SYNC_BUFFER_MS;
import static net.androidgaming.millionaire2024.GameRules.ONLINE_SPEED_POINTS;
import static net.androidgaming.millionaire2024.GameRules.QUESTION_TIMEOUT_MS;

public class GameActivity extends AppCompatActivity {
    private static final int DIALOG_CHARACTER_DELAY_MS = 18;
    private static final int CAMPAIGN_FEEDBACK_TALK_MS = 900;
    private static final int CAMPAIGN_FEEDBACK_MIN_READ_MS = 2200;
    private static final int CAMPAIGN_FEEDBACK_TRANSITION_GAP_MS = 450;

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
    GameBackgroundVideoController backgroundVideoController;
    GameSoundController soundController;
    GameInterstitialAdController interstitialAdController;
    GameLifelineController lifelineController;
    GameLayoutController layoutController;
    GameOpponentHudController opponentHudController;
    GameCampaignHudController campaignHudController;
    GameCampaignResultStore campaignResultStore;
    CountDownTimer cdtProgress;
    MediaPlayer mpBeep, mpBeep1;
    CircleImageView imgPlayer1, imgPlayer2, imgMe, imgOpponent;
    boolean FAST_LIGHTS,
            CAN_PLAY = false,
            CAN_CLICK = false,
            CAN_HOME = false,
            EXITING = false,
            SOUND_ON = true,
            MUSIC_ON = true,
            campaignMode = false,
            campaignResultPersisted = false,
            modeOnline = false,
            eliminationMode = false,
            meOwner;
    Person person;
    Data dataAnswer;
    String myID, opponentID, myName, opponentName, myPhoto, opponentPhoto,
            currentDialog, gameID;
    int myLevel = 1, opponentLevel = 1, myScore = 0, opponentScore = 0,
            currentQuestion, currentStep, PROGRESS_VALUE, T_LIGHTS = 0,
            setMe = 0, setOpponent = 0,
            setScoreMe = 0, setScoreOpponent = 0,
            gameScoreMe = 0, gameScoreOpponent = 0,
            rightAnswer, myAnswer, opponentAnswer, myResult;
    boolean usedHelp5050 = false, usedHelpAudience = false, usedHelpCall = false;
    String campaignId = "main_campaign";
    String campaignStageId = "";
    String campaignStageType = "classic";
    String campaignStageMode = "classic";
    String campaignWinCondition = "completeQuestions";
    int campaignQuestionCount = 15;
    int campaignTimeLimitSeconds = 0;
    boolean campaignAllow5050 = true;
    boolean campaignAllowAudience = true;
    boolean campaignAllowCall = true;
    int campaignLives = 0;
    int campaignLivesRemaining = 0;
    int campaignMaxWrongAnswers = 0;
    int campaignTargetScore = 0;
    String campaignOpponentName = "";
    int campaignOpponentAccuracy = 0;
    int campaignOpponentStartScore = 0;
    int campaignOpponentScore = 0;
    int campaignOpponentCorrectAnswers = 0;
    int campaignOpponentWrongAnswers = 0;
    int campaignSeriesRounds = 0;
    int campaignSeriesWinsRequired = 0;
    int campaignPlayerSeriesWins = 0;
    int campaignOpponentSeriesWins = 0;
    String campaignTeamAllyName = "";
    String campaignTeamEnemyName = "";
    int campaignAllyScore = 0;
    int campaignTeamScore = 0;
    int campaignEnemyTeamScore = 0;
    String campaignFailureReason = "";
    String campaignBossBotName = "";
    int campaignBossBotIntelligence = 0;
    long campaignStartedAtMs = 0L;
    final ArrayList<Integer> campaignQuestionIds = new ArrayList<>();
    final ArrayList<String> campaignAllowedLevels = new ArrayList<>();
    CountDownTimer campaignStageTimer;
    TextView txtCampaignTimer;
    LinearLayout campaignHudPanel;
    TextView txtCampaignHudQuestion;
    TextView txtCampaignHudCorrect;
    TextView txtCampaignHudBattle;
    TextView txtCampaignHudBadge;
    FrameLayout campaignHudProgressTrack;
    View campaignHudProgressFill;
    final ArrayList<TextView> campaignHudStars = new ArrayList<>();
    int campaignCorrectAnswers = 0;
    int campaignWrongAnswers = 0;
    int campaignAnsweredQuestions = 0;
    int campaignUsed5050 = 0;
    int campaignUsedAudience = 0;
    int campaignUsedCall = 0;
    int campaignLastCorrectQuestion = -1;
    int campaignLastWrongQuestion = -1;
    int campaignLastDisplayedStars = 0;

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
    boolean localPlayerRemoved = false;
    boolean localPlayerEliminated = false;
    boolean spectatorEliminationRound = false;
    boolean campaignBossBattle = false;
    MatchOpponent campaignBossOpponent;
    private int pendingQuestionIndex = -1;
    private long scheduledQuestionStartAt = 0L;
    final ArrayList<MatchOpponent> opponents = new ArrayList<>();
    final ArrayList<LinearLayout> opponentAnswerContainers = new ArrayList<>();
    private final HashMap<String, Runnable> pendingBotAnswerRunnables = new HashMap<>();
    LinearLayout llyOpponents;
    LinearLayout llyOpponentScores;
    LinearLayout scoreHeaderRow;
    LinearLayout scoreMeRow;
    TextView txtMeName;
    TextView labScore;
    TextView labSets;
    TextView labScoreGame;
    int scoreboardPanelWidthDp = 270;
    int scoreboardHeaderHeightDp = 28;
    int scoreboardRowHeightDp = 48;
    int scoreboardAvatarColumnWidthDp = 44;
    int scoreboardAvatarSizeDp = 28;
    int scoreboardAvatarBorderDp = 2;
    int scoreboardHorizontalPaddingDp = 6;
    float scoreboardHeaderTextSp = 11f;
    float scoreboardNameTextSp = 8f;
    float scoreboardValueTextSp = 14f;

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
        backgroundVideoController = new GameBackgroundVideoController(this, R.id.gameBackgroundVideo, R.raw.bkgame);
        backgroundVideoController.setup();
        soundController = new GameSoundController(this);
        interstitialAdController = new GameInterstitialAdController(this);
        lifelineController = new GameLifelineController(this);
        layoutController = new GameLayoutController(this);
        opponentHudController = new GameOpponentHudController(this);
        campaignHudController = new GameCampaignHudController(this);
        campaignResultStore = new GameCampaignResultStore(this);

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
        GameCampaignLaunchConfig.load(this, modeExtra, matchModeExtra);


        findViewById(android.R.id.content).post(new Runnable() {
            @Override
            public void run() {
                initAdsIfNeeded();
            }
        });

        person = new Person((RelativeLayout) (findViewById(R.id.rlyPerson)));
        playSound(R.raw.main_theme_4, false, false);

        if (modeOnline || campaignBossBattle) {
            opponentHudController.initCompetitiveHudViews();
        }

        if (modeOnline) {
            if (Data.isNetworkAvailable(GameActivity.this)) {
                parseOpponentsFromIntent();

                if (eliminationMode) {
                    labScore.setText("الصحيح");
                    labSets.setText("الحالة");
                    labScoreGame.setText("النقاط");
                    txtSetsMe.setText("نشط");
                }
                if (txtMeName != null) txtMeName.setText(myName);

                Data.setImageSource(this, imgMe, myPhoto);
                Data.setImageSource(this, imgAnswer1Player1, myPhoto);
                Data.setImageSource(this, imgAnswer2Player1, myPhoto);
                Data.setImageSource(this, imgAnswer3Player1, myPhoto);
                Data.setImageSource(this, imgAnswer4Player1, myPhoto);
                opponentHudController.configureScoreboardLayout();
                opponentHudController.buildOpponentPanels();
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
            if (campaignBossBattle) {
                setupCampaignBossBattle();
            }
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
        applyCampaignLifelineRestrictions();
        createCampaignTimerViewIfNeeded();

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
        layoutController.configureAnswerTextSizing();
        layoutController.configureGameSurfaceLayout();
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
        campaignHudController.configureGameplayHud();

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
                        } else if (campaignMode) {
                            campaignHudController.hideMoneyBox();
                            campaignHudController.showGameplayHud();
                            showDialog(getCampaignOpeningMessage(), "", 800, 2200, R.drawable.mouth_01, false);
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
                            recordCampaignLifelineUse("5050");
                            lifelineController.hideTwoAnswers();
                            startTimer(false);
                            imgHelp5050.setTag("0");
                            imgHelp5050.setImageResource(R.drawable.help_5050_0);
                            break;
                        case "ConfirmHelpAudience":
                            usedHelpAudience = true;
                            recordCampaignLifelineUse("audience");
                            stopTimer(true);
                            lifelineController.showAudienceVote();
                            imgHelpAudience.setTag("0");
                            imgHelpAudience.setImageResource(R.drawable.help_audience_0);
                            break;
                        case "ConfirmHelpCall":
                            usedHelpCall = true;
                            recordCampaignLifelineUse("call");
                            stopTimer(true);
                            lifelineController.callFriend();
                            imgHelpCall.setTag("0");
                            imgHelpCall.setImageResource(R.drawable.help_call_0);
                            break;
                        case "ConfirmExtraHelp5050":
                            if (PlayerProgress.consumeInventory(GameActivity.this, "5050")) {
                                usedHelp5050 = true;
                                recordCampaignLifelineUse("5050");
                                lifelineController.hideTwoAnswers();
                                startTimer(false);
                                updateInventoryBadges();
                                Toast.makeText(GameActivity.this, "تم استخدام 50:50 إضافية", Toast.LENGTH_SHORT).show();
                            }
                            break;
                        case "ConfirmExtraHelpAudience":
                            if (PlayerProgress.consumeInventory(GameActivity.this, "audience")) {
                                usedHelpAudience = true;
                                recordCampaignLifelineUse("audience");
                                stopTimer(true);
                                lifelineController.showAudienceVote();
                                updateInventoryBadges();
                                Toast.makeText(GameActivity.this, "تم استخدام مساعدة جمهور إضافية", Toast.LENGTH_SHORT).show();
                            }
                            break;
                        case "ConfirmExtraHelpCall":
                            if (PlayerProgress.consumeInventory(GameActivity.this, "call")) {
                                usedHelpCall = true;
                                recordCampaignLifelineUse("call");
                                stopTimer(true);
                                lifelineController.callFriend();
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
                                showDialog("القوانين بسيطة وسهلة", "Rules1", 1000, -1, R.drawable.mouth_05, false);
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
                    if (!isCampaignLifelineAllowed("5050")) {
                        showCampaignLifelineUnavailable();
                        return;
                    }
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
                    if (!isCampaignLifelineAllowed("audience")) {
                        showCampaignLifelineUnavailable();
                        return;
                    }
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
                    if (!isCampaignLifelineAllowed("call")) {
                        showCampaignLifelineUnavailable();
                        return;
                    }
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
                    if (soundController != null) soundController.setCurrentEffectVolume(0f);
                    SOUND_ON = false;
                    AppPrefs.setSoundEnabled(GameActivity.this, false);
                    imgVolume.setImageResource(R.drawable.muted);
                } else {
                    if (soundController != null) soundController.setCurrentEffectVolume(1f);
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
            if (soundController != null) soundController.setCurrentEffectVolume(1f);
        } else {
            imgVolume.setImageResource(R.drawable.muted);
            if (soundController != null) soundController.setCurrentEffectVolume(0f);
        }
        if (soundController != null) soundController.stopCurrentMusicIfDisabled(MUSIC_ON);
    }

    private void gameHaptic(View view) {
        if (view != null && AppPrefs.isHapticEnabled(this)) {
            view.performHapticFeedback(HapticFeedbackConstants.VIRTUAL_KEY);
        }
    }


    @Override
    protected void onResume() {
        super.onResume();
        if (backgroundVideoController != null) backgroundVideoController.start();
        SOUND_ON = AppPrefs.isSoundEnabled(this);
        MUSIC_ON = AppPrefs.isMusicEnabled(this);
        applyVolumeUi();
    }
    private void setupCampaignBossBattle() {
        opponents.clear();
        MatchOpponent boss = new MatchOpponent();
        boss.id = "campaign_boss_" + (campaignStageId == null || campaignStageId.trim().isEmpty()
                ? getCampaignStageOrder()
                : campaignStageId.trim());
        boss.bot = true;
        boss.name = campaignBossBotName == null || campaignBossBotName.trim().isEmpty()
                ? "زعيم المرحلة"
                : campaignBossBotName.trim();
        boss.intelligence = resolveCampaignBossIntelligence();
        boss.level = Math.max(1, Math.min(10, boss.intelligence / 10));
        BotProfile profile = BotProfiles.PROFILES[Math.abs(stableHash(boss.id)) % BotProfiles.PROFILES.length];
        boss.photo = profile.photo;
        campaignBossOpponent = boss;
        opponents.add(boss);

        if (labScore != null) labScore.setText("الجولة");
        if (labSets != null) labSets.setText("الصحيح");
        if (labScoreGame != null) labScoreGame.setText("النقاط");
        if (txtMeName != null) txtMeName.setText("أنت");
        if (txtSetsMe != null) txtSetsMe.setText("0");
        if (txtScoreMe != null) txtScoreMe.setText("0");
        if (txtScoreGameMe != null) txtScoreGameMe.setText("0");
        Data.setImageSource(this, imgMe, myPhoto);
        Data.setImageSource(this, imgAnswer1Player1, myPhoto);
        Data.setImageSource(this, imgAnswer2Player1, myPhoto);
        Data.setImageSource(this, imgAnswer3Player1, myPhoto);
        Data.setImageSource(this, imgAnswer4Player1, myPhoto);
        opponentHudController.buildOpponentPanels();
        if (rlyScore != null) {
            rlyScore.setVisibility(View.GONE);
        }
        syncPrimaryOpponentFields();
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
    private GradientDrawable createRoundedDrawable(int fillColor, int strokeColor, int strokeDp, int radiusDp) {
        GradientDrawable drawable = new GradientDrawable();
        drawable.setColor(fillColor);
        drawable.setCornerRadius(dp(radiusDp));
        if (strokeDp > 0) {
            drawable.setStroke(dp(strokeDp), strokeColor);
        }
        return drawable;
    }
    private String getCampaignOpeningMessage() {
        if (campaignBossBattle) {
            return "أمامك الزعيم. اهزمه لفتح الطريق التالي!";
        }
        return "أمامك 10 أسئلة. اجمع أكبر عدد من النجوم!";
    }

    private String getCampaignAnswerMessage(boolean correct, int starsBefore) {
        if (!correct) {
            if (campaignBossBattle && campaignBossOpponent != null) {
                if (gameScoreMe < campaignBossOpponent.gameScore) {
                    return "الزعيم متقدم، لكن ما زالت لديك فرصة.";
                }
                if (gameScoreMe > campaignBossOpponent.gameScore) {
                    return "أنت متقدم على الزعيم! حافظ على تركيزك.";
                }
            }
            return "لا بأس، الخطأ لا ينهي المرحلة لكنه يؤثر على النجوم.";
        }
        int starsAfter = campaignHudController.getEarnedStars();
        if (starsAfter > starsBefore) {
            if (starsAfter == 1) return "ممتاز! حصلت على النجمة الأولى.";
            if (starsAfter == 2) return "رائع! نجمتان حتى الآن.";
            return "مذهل! ثلاث نجوم!";
        }
        if (campaignBossBattle && campaignBossOpponent != null) {
            if (gameScoreMe < campaignBossOpponent.gameScore) {
                return "الزعيم متقدم، لكن ما زالت لديك فرصة.";
            }
            if (gameScoreMe > campaignBossOpponent.gameScore) {
                return "أنت متقدم على الزعيم! حافظ على تركيزك.";
            }
        }
        return "إجابة رائعة! اقتربت من النجمة التالية.";
    }

    private static int getReadableDialogDurationMs(String message, int minimumReadMs) {
        int msgLen = message == null ? 0 : message.replace("\n", "").length();
        int typewriterMs = (msgLen + 2) * DIALOG_CHARACTER_DELAY_MS;
        return typewriterMs + minimumReadMs;
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

    private MatchOpponent findOpponentById(String playerId) {
        for (MatchOpponent opponent : opponents) {
            if (opponent.id.equals(playerId)) {
                return opponent;
            }
        }
        return null;
    }

    int dp(int value) {
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
        return GameBotLogic.resolveBotProfile(playerId);
    }

    private void applyBotIdentity(MatchOpponent opponent, boolean replacingHuman) {
        GameBotLogic.applyBotIdentity(opponent);
        if (opponent != null && replacingHuman) {
            Toast.makeText(
                    this,
                    opponent.name + " يتابع اللعب الآن كخصم آلي",
                    Toast.LENGTH_SHORT
            ).show();
        }
    }

    private int getFictitiousRandomTime() {
        return GameBotLogic.getFictitiousRandomTime(getCurrentQuestionLevel());
    }

    private int getFictitiousRandomAnswer() {
        return GameBotLogic.getFictitiousRandomAnswer(getCurrentQuestionLevel(), rightAnswer);
    }

    private int getBotDelayMillis(MatchOpponent opponent) {
        return GameBotLogic.getBotDelayMillis(opponent, currentQuestion, getCurrentQuestionLevel(), PROGRESS_VALUE);
    }

    private int getBotDisplayedAnswer(MatchOpponent opponent) {
        return GameBotLogic.getBotDisplayedAnswer(opponent, currentQuestion, getCurrentQuestionLevel(), rightAnswer);
    }

    private int getWrongAnswer(int rightAnswer) {
        return GameBotLogic.getWrongAnswer(rightAnswer);
    }

    private String getCurrentQuestionLevel() {
        if (currentQuestion >= 0 && currentQuestion < questions.size()) {
            return questions.get(currentQuestion).Level;
        }
        return "0";
    }
    private void checkAnswer(final boolean timeout) {
        final int amount = modeOnline ? 0 : Integer.parseInt(getCurrentStepAmount().replace("$", ""));
        if (!timeout) {
            stopTimer(false);
            playSound(R.raw.drum1, false, true);
            FAST_LIGHTS = true;
        }
        CAN_HOME = true;
        if (campaignMode && !modeOnline) {
            handleCampaignStageAnswer(timeout);
            return;
        }
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
                                recordCampaignCorrectAnswer();
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
                        } else if (shouldCompleteCampaignAfterCurrentQuestion()) {
                            person.moveShow2Hands(2000);
                            person.raiseEyeBrowsUp(2000, true, true);
                            showDialog("أحسنت! أنهيت المرحلة بنجاح", "", 2000, 2000, R.drawable.mouth_01, false);
                            CAN_HOME = false;
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
                            if (shouldCompleteCampaignAfterCurrentQuestion()) {
                                goToWinnerScreen(getCurrentStepAmount());
                            } else if (currentQuestion == 14) {
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
            opponentHudController.refreshOpponentPanels();
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
        opponentHudController.refreshOpponentPanels();
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

        opponentHudController.refreshOpponentPanels();

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
            persistPendingCampaignStageResult(true, prize, 0);
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
            GameActivity.this.questions = campaignMode
                    ? LocalQuestions.loadAll(this)
                    : LocalQuestions.load(this);
            applyCampaignQuestionSelectionIfNeeded();
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
                        opponentHudController.refreshOpponentPanels();
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
        stopCurrentSound();
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

    private void scheduleCampaignBossAnswer() {
        if (!campaignBossBattle || campaignBossOpponent == null
                || campaignBossOpponent.submitted || currentQuestion < 0
                || currentQuestion >= questions.size()) {
            return;
        }
        final MatchOpponent boss = campaignBossOpponent;
        final int questionIndex = currentQuestion;
        int remainingMillis = Math.max(1000, ((PROGRESS_VALUE / 10) - 1) * 1000);
        final int delayMillis = Math.min(remainingMillis, getBotDelayMillis(boss));

        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                pendingBotAnswerRunnables.remove(boss.id);
                if (EXITING || !campaignBossBattle || currentQuestion != questionIndex
                        || rightAnswer <= 0 || boss.submitted) {
                    return;
                }
                submitCampaignBossAnswer(boss, getCampaignBossDisplayedAnswer(boss), delayMillis);
            }
        };
        pendingBotAnswerRunnables.put(boss.id, runnable);
        fictitiousAnswerHandler.postDelayed(runnable, delayMillis);
    }

    private void ensureCampaignBossAnswered() {
        if (!campaignBossBattle || campaignBossOpponent == null
                || campaignBossOpponent.submitted || rightAnswer <= 0) {
            return;
        }
        int elapsedMs = (int) Math.max(900L, Math.min(QUESTION_TIMEOUT_MS, getCurrentAnswerElapsedMs() + 450L));
        submitCampaignBossAnswer(
                campaignBossOpponent,
                getCampaignBossDisplayedAnswer(campaignBossOpponent),
                elapsedMs
        );
    }

    private void submitCampaignBossAnswer(MatchOpponent boss, int displayedAnswer, long elapsedMs) {
        if (boss == null || boss.submitted || displayedAnswer <= 0) {
            return;
        }
        boss.displayedAnswer = displayedAnswer;
        boss.submittedAnswerKey = getAnswerKeyForDisplayedIndex(displayedAnswer);
        boss.submitted = true;
        boss.answerElapsedMs = Math.max(1L, Math.min(QUESTION_TIMEOUT_MS, elapsedMs));
    }

    private int getCampaignBossDisplayedAnswer(MatchOpponent boss) {
        if (boss == null || rightAnswer <= 0) {
            return 0;
        }
        return new Random().nextDouble() < getCampaignBossAccuracy(boss)
                ? rightAnswer
                : getWrongAnswer(rightAnswer);
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
        opponentHudController.refreshOpponentPanels();
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
        opponentHudController.refreshOpponentPanels();
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

    String safeString(Object value) {
        return value == null ? "" : String.valueOf(value);
    }

    String safeIntentString(String key, String fallback) {
        String value = getIntent().getStringExtra(key);
        if (value == null || value.trim().isEmpty()) {
            return fallback;
        }
        return value.trim();
    }

    private int getCampaignStageOrder() {
        if (campaignStageId != null) {
            String digits = campaignStageId.replaceAll("[^0-9]", "");
            if (!digits.isEmpty()) {
                try {
                    return Math.max(1, Integer.parseInt(digits));
                } catch (Exception ignored) {
                }
            }
        }
        return 1;
    }

    private int resolveCampaignBossIntelligence() {
        int order = getCampaignStageOrder();
        int defaultValue = order >= 30 ? 85 : (order >= 20 ? 75 : 65);
        int requested = campaignBossBotIntelligence > 0 ? campaignBossBotIntelligence : defaultValue;
        int maxValue = order >= 30 ? 88 : (order >= 20 ? 78 : 68);
        int minValue = order >= 30 ? 82 : (order >= 20 ? 72 : 60);
        return Math.max(minValue, Math.min(maxValue, requested));
    }

    private double getCampaignBossAccuracy(MatchOpponent boss) {
        int order = getCampaignStageOrder();
        double maxAccuracy = order >= 30 ? 0.88d : (order >= 20 ? 0.78d : 0.68d);
        double minAccuracy = order >= 30 ? 0.82d : (order >= 20 ? 0.72d : 0.60d);
        double baseAccuracy = Math.max(0.0d, Math.min(1.0d, boss.intelligence / 100.0d));
        double variation = (new Random().nextInt(7) - 3) / 100.0d;
        return Math.max(minAccuracy, Math.min(maxAccuracy, baseAccuracy + variation));
    }

    String normalizeCampaignMode(String mode) {
        String normalized = mode == null ? "" : mode.trim().replace("_", "").replace("-", "").toLowerCase(Locale.US);
        if ("speed".equals(normalized) || "blitz".equals(normalized)) return "blitz";
        if ("elimination".equals(normalized)) return "elimination";
        if ("survival".equals(normalized)) return "survival";
        if ("nolifeline".equals(normalized)) return "noLifeline";
        if ("battle".equals(normalized)) return "battle";
        if ("rival".equals(normalized)) return "rival";
        if ("series".equals(normalized)) return "series";
        if ("teambattle".equals(normalized)) return "teamBattle";
        if ("boss".equals(normalized) || "bossbattle".equals(normalized)) return "bossBattle";
        return "classic";
    }

    String defaultCampaignWinCondition(String mode) {
        String normalized = normalizeCampaignMode(mode);
        if ("blitz".equals(normalized)) return "finishBeforeTime";
        if ("elimination".equals(normalized)) return "noMistakes";
        if ("survival".equals(normalized)) return "survive";
        if ("battle".equals(normalized)) return "beatOpponent";
        if ("rival".equals(normalized)) return "beatTargetScore";
        if ("series".equals(normalized)) return "winSeries";
        if ("teamBattle".equals(normalized)) return "teamScore";
        if ("bossBattle".equals(normalized)) return "defeatBoss";
        return "completeQuestions";
    }

    private boolean isCampaignBlitzMode() { return "blitz".equals(campaignStageMode); }
    private boolean isCampaignEliminationMode() { return "elimination".equals(campaignStageMode); }
    private boolean isCampaignSurvivalMode() { return "survival".equals(campaignStageMode); }
    private boolean isCampaignNoLifelineMode() { return "noLifeline".equals(campaignStageMode); }
    private boolean isCampaignBattleMode() { return "battle".equals(campaignStageMode); }
    private boolean isCampaignRivalMode() { return "rival".equals(campaignStageMode); }
    private boolean isCampaignSeriesMode() { return "series".equals(campaignStageMode); }
    private boolean isCampaignTeamBattleMode() { return "teamBattle".equals(campaignStageMode); }
    boolean isCampaignBossMode() { return "bossBattle".equals(campaignStageMode) || "boss".equals(campaignStageType); }

    private boolean isCampaignCompetitiveSimulationMode() {
        return isCampaignBattleMode() || isCampaignSeriesMode() || isCampaignTeamBattleMode();
    }

    private int clampInt(int value, int min, int max) {
        return Math.max(min, Math.min(max, value));
    }

    void applyCampaignStageTypeDefaults() {
        if (!campaignMode) {
            return;
        }
        campaignStageType = campaignStageType == null ? "classic" : campaignStageType.trim().toLowerCase(Locale.US);
        campaignStageMode = normalizeCampaignMode(campaignStageMode);
        campaignWinCondition = campaignWinCondition == null || campaignWinCondition.trim().isEmpty()
                ? defaultCampaignWinCondition(campaignStageMode)
                : campaignWinCondition.trim();
        if ("nolifeline".equals(campaignStageType) || "no_lifeline".equals(campaignStageType)) {
            campaignAllow5050 = false;
            campaignAllowAudience = false;
            campaignAllowCall = false;
            campaignStageType = "noLifeline";
        }
        if (isCampaignNoLifelineMode()) {
            campaignAllow5050 = false;
            campaignAllowAudience = false;
            campaignAllowCall = false;
        }
        if (isCampaignSurvivalMode()) {
            campaignLives = campaignLives > 0 ? campaignLives : 3;
            campaignLivesRemaining = campaignLives;
        }
        if (isCampaignEliminationMode()) {
            campaignMaxWrongAnswers = campaignMaxWrongAnswers > 0 ? campaignMaxWrongAnswers : 1;
        }
        if (isCampaignRivalMode()) {
            campaignTargetScore = campaignTargetScore > 0 ? campaignTargetScore : 700;
        }
        if (isCampaignBattleMode() || isCampaignSeriesMode() || isCampaignTeamBattleMode()) {
            campaignOpponentAccuracy = clampInt(campaignOpponentAccuracy > 0 ? campaignOpponentAccuracy : 60, 35, 85);
            campaignOpponentScore = Math.max(0, campaignOpponentStartScore);
            if (campaignOpponentName == null || campaignOpponentName.trim().isEmpty()) {
                campaignOpponentName = isCampaignTeamBattleMode() ? "فريق التحدي" : "خصم آلي";
            }
        }
        if (isCampaignSeriesMode()) {
            campaignSeriesRounds = campaignSeriesRounds > 0 ? campaignSeriesRounds : 3;
            campaignSeriesWinsRequired = campaignSeriesWinsRequired > 0 ? campaignSeriesWinsRequired : 2;
        }
        if (isCampaignTeamBattleMode()) {
            if (campaignTeamAllyName == null || campaignTeamAllyName.trim().isEmpty()) {
                campaignTeamAllyName = "زميلك";
            }
            if (campaignTeamEnemyName == null || campaignTeamEnemyName.trim().isEmpty()) {
                campaignTeamEnemyName = "الفريق المنافس";
            }
        }
        if (isCampaignBossMode()) {
            if (campaignBossBotIntelligence <= 0 && campaignOpponentAccuracy > 0) {
                campaignBossBotIntelligence = campaignOpponentAccuracy;
            }
            campaignBossBotIntelligence = resolveCampaignBossIntelligence();
        }
    }

    private void applyCampaignLifelineRestrictions() {
        if (!campaignMode) {
            return;
        }
        applyCampaignLifelineVisual(imgHelp5050, campaignAllow5050);
        applyCampaignLifelineVisual(imgHelpAudience, campaignAllowAudience);
        applyCampaignLifelineVisual(imgHelpCall, campaignAllowCall);
    }

    private void applyCampaignLifelineVisual(ImageView view, boolean allowed) {
        if (view == null || allowed) {
            return;
        }
        view.setTag("0");
        GameLifelineController.setGreyscale(view);
        view.setImageAlpha(120);
    }

    private boolean isCampaignLifelineAllowed(String type) {
        if (!campaignMode) {
            return true;
        }
        if ("5050".equals(type)) {
            return campaignAllow5050;
        }
        if ("audience".equals(type)) {
            return campaignAllowAudience;
        }
        if ("call".equals(type)) {
            return campaignAllowCall;
        }
        return true;
    }

    private void showCampaignLifelineUnavailable() {
        Toast.makeText(this, "هذه المساعدة غير متاحة في هذه المرحلة", Toast.LENGTH_SHORT).show();
    }

    private void recordCampaignLifelineUse(String type) {
        if (!campaignMode) {
            return;
        }
        if ("5050".equals(type)) {
            campaignUsed5050++;
        } else if ("audience".equals(type)) {
            campaignUsedAudience++;
        } else if ("call".equals(type)) {
            campaignUsedCall++;
        }
    }

    private void recordCampaignCorrectAnswer() {
        if (!campaignMode || campaignLastCorrectQuestion == currentQuestion) {
            return;
        }
        campaignLastCorrectQuestion = currentQuestion;
        campaignCorrectAnswers++;
        campaignAnsweredQuestions++;
    }

    private void recordCampaignWrongAnswer() {
        if (!campaignMode || campaignLastWrongQuestion == currentQuestion) {
            return;
        }
        campaignLastWrongQuestion = currentQuestion;
        campaignWrongAnswers++;
        campaignAnsweredQuestions++;
    }

    private void applyCampaignModeAfterAnswer(boolean correct) {
        if (!campaignMode) {
            return;
        }
        if (!correct && isCampaignSurvivalMode()) {
            campaignLivesRemaining = Math.max(0, campaignLivesRemaining - 1);
        }
        if (isCampaignCompetitiveSimulationMode()) {
            simulateCampaignOpponentAnswer();
        }
        if (isCampaignTeamBattleMode()) {
            simulateCampaignTeamRound();
        }
    }

    private void simulateCampaignOpponentAnswer() {
        int accuracy = clampInt(campaignOpponentAccuracy > 0 ? campaignOpponentAccuracy : 60, 35, 85);
        boolean opponentCorrect = new Random().nextInt(100) < accuracy;
        if (opponentCorrect) {
            campaignOpponentCorrectAnswers++;
            campaignOpponentScore += 100;
        } else {
            campaignOpponentWrongAnswers++;
        }
    }

    private void simulateCampaignTeamRound() {
        int allyAccuracy = clampInt(campaignOpponentAccuracy - 6, 45, 78);
        int enemyAccuracy = clampInt(campaignOpponentAccuracy, 45, 85);
        if (new Random().nextInt(100) < allyAccuracy) {
            campaignAllyScore += 100;
        }
        int enemyCorrectThisQuestion = 0;
        if (new Random().nextInt(100) < enemyAccuracy) enemyCorrectThisQuestion++;
        if (new Random().nextInt(100) < Math.max(40, enemyAccuracy - 7)) enemyCorrectThisQuestion++;
        campaignEnemyTeamScore += enemyCorrectThisQuestion * 100;
        campaignTeamScore = getCampaignPlayerScore() + campaignAllyScore;
    }

    int getCampaignPlayerScore() {
        if (campaignBossBattle) {
            return Math.max(0, gameScoreMe);
        }
        return Math.max(0, campaignCorrectAnswers * 100);
    }

    private boolean campaignPlayerBeatsOpponent(int playerScore, int opponentScoreValue, int opponentCorrect) {
        if (playerScore != opponentScoreValue) {
            return playerScore > opponentScoreValue;
        }
        return campaignCorrectAnswers > opponentCorrect;
    }

    private boolean shouldFailCampaignAfterCurrentAnswer() {
        if (!campaignMode) {
            return false;
        }
        if (isCampaignEliminationMode() && campaignWrongAnswers >= Math.max(1, campaignMaxWrongAnswers)) {
            campaignFailureReason = "eliminated";
            return true;
        }
        if (isCampaignSurvivalMode() && campaignLivesRemaining <= 0) {
            campaignFailureReason = "outOfLives";
            return true;
        }
        return false;
    }

    private void failCampaignStage(String reason, int delayMs) {
        if (!campaignMode || campaignResultPersisted) {
            return;
        }
        campaignFailureReason = reason == null ? "" : reason;
        PlayerStats.recordGameEnd(GameActivity.this, false, 0);
        PlayerProgress.onGameFinished(GameActivity.this, false, 0,
                PlayerStats.getBestStreak(GameActivity.this), usedAllHelps(), usedAnyHelp());
        persistPendingCampaignStageResult(false, 0, campaignWrongAnswers);
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                if (!isFinishing()) {
                    finishCampaignAndReturnToFlutter();
                }
            }
        }, Math.max(0, delayMs));
    }

    private boolean shouldCompleteCampaignAfterCurrentQuestion() {
        return campaignMode
                && campaignQuestionCount > 0
                && campaignAnsweredQuestions >= getCampaignTargetQuestionCount();
    }

    private void applyCampaignBossRoundMetrics(boolean playerCorrect) {
        if (!campaignBossBattle || campaignBossOpponent == null) {
            return;
        }
        MatchOpponent boss = campaignBossOpponent;
        boolean bossCorrect = boss.submittedAnswerKey == ANSWER_KEY_RIGHT;
        if (playerCorrect) {
            mySetCorrectAnswers++;
            myTotalCorrectAnswers++;
            setScoreMe += 100;
            gameScoreMe += 100;
        }
        if (bossCorrect) {
            boss.setCorrectAnswers++;
            boss.totalCorrectAnswers++;
            boss.roundScore += 100;
            boss.gameScore += 100;
        }
        myRoundPoints = playerCorrect ? 100 : 0;
        boss.roundPoints = bossCorrect ? 100 : 0;
        myTotalAnswerTimeMs += myAnswerElapsedMs;
        boss.totalAnswerTimeMs += boss.answerElapsedMs;
        txtScoreMe.setText(setScoreMe + "");
        txtSetsMe.setText(myTotalCorrectAnswers + "");
        txtScoreGameMe.setText(gameScoreMe + "");
        opponentHudController.refreshOpponentPanels();
    }

    int getCampaignTargetQuestionCount() {
        int requested = campaignQuestionCount > 0 ? campaignQuestionCount : 10;
        if (campaignMode && questions != null && !questions.isEmpty()) {
            return Math.min(requested, questions.size());
        }
        return requested;
    }

    private void handleCampaignStageAnswer(final boolean timeout) {
        FAST_LIGHTS = false;
        T_LIGHTS = 3;
        CAN_PLAY = false;
        final boolean correct = !timeout && myAnswer == rightAnswer;
        final int starsBefore = campaignHudController.getEarnedStars();
        final String campaignAnswerMessage;
        final int campaignAnswerDialogMs;
        myAnswerElapsedMs = timeout ? QUESTION_TIMEOUT_MS : getCurrentAnswerElapsedMs();
        if (campaignBossBattle) {
            ensureCampaignBossAnswered();
            applyCampaignBossRoundMetrics(correct);
        }
        if (correct) {
            recordCampaignCorrectAnswer();
            if (imgSelected != null) imgSelected.setImageResource(R.drawable.frame_right);
            PlayerStats.recordCorrectAnswer(GameActivity.this);
            person.like(700);
            playSound(R.raw.correct_answer, false, false);
            campaignHudController.updateProgressHud(true);
            campaignAnswerMessage = getCampaignAnswerMessage(true, starsBefore);
            campaignAnswerDialogMs = getReadableDialogDurationMs(campaignAnswerMessage, CAMPAIGN_FEEDBACK_MIN_READ_MS);
            showDialog(campaignAnswerMessage, "", CAMPAIGN_FEEDBACK_TALK_MS, campaignAnswerDialogMs, R.drawable.mouth_01, false);
        } else {
            recordCampaignWrongAnswer();
            PlayerStats.recordWrongAnswer(GameActivity.this);
            playSound(R.raw.wrong_answer, false, false);
            if (imgSelected != null && !timeout) imgSelected.setImageResource(R.drawable.frame_wrong);
            if (imgRight != null) imgRight.setImageResource(R.drawable.frame_right);
            campaignHudController.updateProgressHud(false);
            campaignAnswerMessage = getCampaignAnswerMessage(false, starsBefore);
            campaignAnswerDialogMs = getReadableDialogDurationMs(campaignAnswerMessage, CAMPAIGN_FEEDBACK_MIN_READ_MS);
            showDialog(campaignAnswerMessage, "", CAMPAIGN_FEEDBACK_TALK_MS, campaignAnswerDialogMs, R.drawable.mouth_05, false);
        }
        final int campaignNextQuestionDelayMs = campaignAnswerDialogMs + CAMPAIGN_FEEDBACK_TRANSITION_GAP_MS;
        applyCampaignModeAfterAnswer(correct);
        campaignHudController.updateProgressHud(false);

        if (campaignBossBattle && campaignBossOpponent != null
                && campaignBossOpponent.displayedAnswer > 0) {
            showThumbPlayerAnswer(campaignBossOpponent, campaignBossOpponent.displayedAnswer);
        }

        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                if (EXITING || campaignResultPersisted) {
                    return;
                }
                if (shouldFailCampaignAfterCurrentAnswer()) {
                    failCampaignStage(campaignFailureReason, 0);
                    return;
                }
                if (shouldCompleteCampaignAfterCurrentQuestion()) {
                    completeCampaignStage();
                    return;
                }
                initQuestion();
                if (currentStep < steps.size() - 1) {
                    nextStep();
                }
                // Campaign stages use a fast 10-question flow and skip the
                // classic side/intermediate money screen between questions.
                nextQuestion();
            }
        }, campaignNextQuestionDelayMs);
    }

    private void completeCampaignStage() {
        final int prize = getCampaignCurrentMoney();
        final boolean completed = isCampaignStageCompleteByMode();
        PlayerStats.recordGameEnd(GameActivity.this, completed, prize);
        PlayerProgress.onGameFinished(GameActivity.this, completed, completed ? prize : 0,
                PlayerStats.getBestStreak(GameActivity.this), usedAllHelps(), usedAnyHelp());
        persistPendingCampaignStageResult(completed, completed ? prize : 0, 0);
        finishCampaignAndReturnToFlutter();
    }

    private boolean isCampaignStageCompleteByMode() {
        if (!campaignMode) {
            return true;
        }
        int playerScore = getCampaignPlayerScore();
        if (isCampaignEliminationMode()) {
            boolean completed = campaignWrongAnswers < Math.max(1, campaignMaxWrongAnswers);
            if (!completed) campaignFailureReason = "eliminated";
            return completed;
        }
        if (isCampaignSurvivalMode()) {
            boolean completed = campaignLivesRemaining > 0;
            if (!completed) campaignFailureReason = "outOfLives";
            return completed;
        }
        if (isCampaignBattleMode()) {
            boolean completed = campaignPlayerBeatsOpponent(playerScore, campaignOpponentScore, campaignOpponentCorrectAnswers);
            if (!completed) campaignFailureReason = "lostBattle";
            return completed;
        }
        if (isCampaignRivalMode()) {
            int targetScore = campaignTargetScore > 0 ? campaignTargetScore : 700;
            boolean completed = playerScore >= targetScore;
            if (!completed) campaignFailureReason = "targetNotReached";
            return completed;
        }
        if (isCampaignBossMode()) {
            boolean completed = isCampaignBossDefeated();
            if (!completed) campaignFailureReason = "bossDefeatedPlayer";
            return completed;
        }
        if (isCampaignSeriesMode()) {
            resolveSimpleCampaignSeries();
            boolean completed = campaignPlayerSeriesWins >= Math.max(2, campaignSeriesWinsRequired);
            if (!completed) campaignFailureReason = "lostSeries";
            return completed;
        }
        if (isCampaignTeamBattleMode()) {
            campaignTeamScore = playerScore + campaignAllyScore;
            boolean completed = campaignTeamScore > campaignEnemyTeamScore;
            if (!completed) campaignFailureReason = "lostTeamBattle";
            return completed;
        }
        return true;
    }

    private void resolveSimpleCampaignSeries() {
        // TODO: Replace this summary with visible per-round campaign series UI.
        int requiredWins = Math.max(2, campaignSeriesWinsRequired);
        boolean playerWon = campaignPlayerBeatsOpponent(
                getCampaignPlayerScore(),
                campaignOpponentScore,
                campaignOpponentCorrectAnswers
        );
        campaignPlayerSeriesWins = playerWon ? requiredWins : Math.max(0, requiredWins - 1);
        campaignOpponentSeriesWins = playerWon ? Math.max(0, requiredWins - 1) : requiredWins;
    }

    boolean isCampaignBossDefeated() {
        if (!campaignBossBattle || campaignBossOpponent == null) {
            return true;
        }
        MatchOpponent boss = campaignBossOpponent;
        if (gameScoreMe != boss.gameScore) {
            return gameScoreMe > boss.gameScore;
        }
        if (myTotalCorrectAnswers != boss.totalCorrectAnswers) {
            return myTotalCorrectAnswers > boss.totalCorrectAnswers;
        }
        return myTotalAnswerTimeMs > 0L
                && (boss.totalAnswerTimeMs <= 0L || myTotalAnswerTimeMs < boss.totalAnswerTimeMs);
    }

    private int getCampaignCurrentMoney() {
        try {
            return Integer.parseInt(getCurrentStepAmount().replace("$", "").trim());
        } catch (Exception ignored) {
        }
        try {
            if (txtAmount != null && txtAmount.getText() != null) {
                return Integer.parseInt(txtAmount.getText().toString().replace("$", "").trim());
            }
        } catch (Exception ignored) {
        }
        return 0;
    }

    private void createCampaignTimerViewIfNeeded() {
        if (!campaignMode || campaignTimeLimitSeconds <= 0 || txtCampaignTimer != null) {
            return;
        }
        txtCampaignTimer = new TextView(this);
        txtCampaignTimer.setTextColor(Color.WHITE);
        txtCampaignTimer.setTextSize(TypedValue.COMPLEX_UNIT_SP, isCampaignBlitzMode() ? 19 : 16);
        txtCampaignTimer.setTypeface(null, android.graphics.Typeface.BOLD);
        txtCampaignTimer.setPadding(dp(12), dp(7), dp(12), dp(7));
        txtCampaignTimer.setText(formatCampaignRemaining(campaignTimeLimitSeconds));
        updateCampaignTimerVisual(campaignTimeLimitSeconds);
        android.widget.FrameLayout.LayoutParams params = new android.widget.FrameLayout.LayoutParams(
                android.widget.FrameLayout.LayoutParams.WRAP_CONTENT,
                android.widget.FrameLayout.LayoutParams.WRAP_CONTENT);
        params.gravity = android.view.Gravity.TOP | android.view.Gravity.CENTER_HORIZONTAL;
        params.setMargins(dp(12), dp(82), dp(12), dp(12));
        View root = findViewById(android.R.id.content);
        if (root instanceof android.widget.FrameLayout) {
            ((android.widget.FrameLayout) root).addView(txtCampaignTimer, params);
        }
    }

    private void startCampaignStageTimerIfNeeded() {
        if (!campaignMode || campaignTimeLimitSeconds <= 0 || campaignStageTimer != null || campaignResultPersisted) {
            return;
        }
        campaignStartedAtMs = System.currentTimeMillis();
        campaignStageTimer = new CountDownTimer(campaignTimeLimitSeconds * 1000L, 1000L) {
            @Override
            public void onTick(long millisUntilFinished) {
                if (txtCampaignTimer != null) {
                    int secondsLeft = (int) Math.ceil(millisUntilFinished / 1000.0);
                    txtCampaignTimer.setText(formatCampaignRemaining(secondsLeft));
                    updateCampaignTimerVisual(secondsLeft);
                }
            }

            @Override
            public void onFinish() {
                handleCampaignTimeExpired();
            }
        }.start();
    }

    private String formatCampaignRemaining(int totalSeconds) {
        int safeSeconds = Math.max(0, totalSeconds);
        return String.format(Locale.US, "%02d:%02d", safeSeconds / 60, safeSeconds % 60);
    }

    private void updateCampaignTimerVisual(int secondsLeft) {
        if (txtCampaignTimer == null) {
            return;
        }
        boolean urgent = secondsLeft <= 20 || (isCampaignBlitzMode() && secondsLeft <= 30);
        txtCampaignTimer.setTextColor(urgent ? Color.rgb(255, 230, 230) : Color.WHITE);
        txtCampaignTimer.setBackground(createRoundedDrawable(
                urgent ? Color.argb(225, 150, 20, 34) : Color.argb(205, 10, 28, 48),
                urgent ? Color.argb(240, 255, 112, 112) : Color.argb(220, 255, 216, 74),
                isCampaignBlitzMode() ? 2 : 1,
                18
        ));
    }

    private void handleCampaignTimeExpired() {
        if (!campaignMode || campaignResultPersisted || EXITING) {
            return;
        }
        CAN_PLAY = false;
        CAN_CLICK = false;
        CAN_HOME = false;
        stopTimer(false);
        Toast.makeText(this, "انتهى الوقت!", Toast.LENGTH_SHORT).show();
        campaignFailureReason = "timeExpired";
        persistPendingCampaignStageResult(false, getCampaignCurrentMoney(), campaignWrongAnswers);
        new Handler().postDelayed(new Runnable() {
            @Override
            public void run() {
                if (!isFinishing()) {
                    finishCampaignAndReturnToFlutter();
                }
            }
        }, 1200);
    }

    private void finishCampaignAndReturnToFlutter() {
        if (!campaignMode) {
            return;
        }
        Log.d("CampaignStage", "CAMP_FINISH_TO_FLUTTER");
            stopCurrentSound();
        if (cdtProgress != null) cdtProgress.cancel();
        stopCampaignStageTimer();
        finish();
    }

    void stopCampaignStageTimer() {
        if (campaignStageTimer != null) {
            campaignStageTimer.cancel();
            campaignStageTimer = null;
        }
    }

    private void applyCampaignQuestionSelectionIfNeeded() {
        if (!campaignMode || questions == null || questions.isEmpty()) {
            return;
        }
        ArrayList<Question> selected = new ArrayList<>();
        if (!campaignQuestionIds.isEmpty()) {
            for (Integer id : campaignQuestionIds) {
                if (id == null) {
                    continue;
                }
                int index = id;
                if (index >= 0 && index < questions.size()) {
                    Question question = questions.get(index);
                    if (isCampaignQuestionLevelAllowed(question)) {
                        selected.add(question);
                    } else {
                        Log.w("CampaignStage", "Skipped question id=" + id
                                + " level=" + (question == null ? "" : question.getLevel())
                                + " allowed=" + campaignAllowedLevels);
                    }
                } else {
                    Log.w("CampaignStage", "Question id out of range: " + id);
                }
                if (selected.size() >= getCampaignTargetQuestionCount()) {
                    break;
                }
            }
        }
        if (selected.size() < getCampaignTargetQuestionCount()
                && !campaignAllowedLevels.isEmpty()) {
            for (Question question : questions) {
                if (selected.size() >= getCampaignTargetQuestionCount()) {
                    break;
                }
                if (isCampaignQuestionLevelAllowed(question) && !selected.contains(question)) {
                    selected.add(question);
                }
            }
        }
        if (!selected.isEmpty() || !campaignAllowedLevels.isEmpty()) {
            questions = selected;
        }
        if (isDebuggableBuild()) {
            Log.d("CampaignStage", "loaded campaign questions=" + questions.size()
                    + " levels=" + campaignLevelSummary(questions));
        }
    }

    boolean isDebuggableBuild() {
        return (getApplicationInfo().flags & android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) != 0;
    }

    private boolean isCampaignQuestionLevelAllowed(Question question) {
        if (question == null || campaignAllowedLevels.isEmpty()) {
            return true;
        }
        String level = question.getLevel() == null ? "" : question.getLevel().trim();
        return campaignAllowedLevels.contains(level);
    }

    private String campaignLevelSummary(ArrayList<Question> list) {
        HashMap<String, Integer> summary = new HashMap<>();
        for (Question question : list) {
            String level = question == null || question.getLevel() == null
                    ? ""
                    : question.getLevel().trim();
            Integer count = summary.get(level);
            summary.put(level, count == null ? 1 : count + 1);
        }
        return summary.toString();
    }

    private void confirmExit() {
        if (!txtAmount.getText().toString().equals("$0")) {
            showDialog("هل تريد الخروج والاكتفاء بالمبلغ الحالي ؟", "ConfirmHome", 2000, 0, R.drawable.mouth_05, false);
        } else {
            showDialog("هل تريد الانسحاب من المباراة ؟", "ConfirmExit", 2000, 0, R.drawable.mouth_05, false);
        }
    }

    private void showInterstitialAd() {
        if (interstitialAdController != null) {
            interstitialAdController.showOrRun(this::navigateToHome);
        } else {
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
                        if (campaignMode && "boss".equals(campaignStageType) && !campaignBossBotName.trim().isEmpty()) {
                            Toast.makeText(GameActivity.this, "تواجه الآن " + campaignBossBotName, Toast.LENGTH_SHORT).show();
                        }
                        if (modeOnline)
                            showDialog("نبدأ الآن.. استعدوا للمباراة", "", 1000, 3000, R.drawable.mouth_01, false);
                        else if (campaignMode)
                            showDialog(getCampaignOpeningMessage(), "", 1000, 3000, R.drawable.mouth_01, false);
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
                        if (campaignMode) {
                            campaignStartedAtMs = System.currentTimeMillis();
                        }
                        startCampaignStageTimerIfNeeded();
                        if (modeOnline || campaignBossBattle) {
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
        stopCurrentSound();
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
                    persistPendingCampaignStageResult(false, prize, 0);
                } catch (Exception ignored) {}
                stopCurrentSound();
                if (cdtProgress != null) cdtProgress.cancel();
                if (campaignMode) {
                    finishCampaignAndReturnToFlutter();
                } else {
                    showInterstitialAd();
                }
            }
        }, 2000);
    }

    void startTimer(boolean start) {
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
                } else if (campaignBossBattle) {
                    scheduleCampaignBossAnswer();
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
        recordCampaignWrongAnswer();
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
                                    persistPendingCampaignStageResult(false, safeHavenPrize, 1);
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
        GameLifelineController.setVote(this, imgVote1);
        GameLifelineController.setVote(this, imgVote2);
        GameLifelineController.setVote(this, imgVote3);
        GameLifelineController.setVote(this, imgVote4);
        if(modeOnline || campaignBossBattle) {
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
            opponentHudController.refreshOpponentPanels();
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
            campaignHudController.updateProgressHud(false);
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

    String getLetter(int index) {
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
        return GameAnswerOptions.buildShuffledKeys(modeOnline, currentQuestion, gameID, question);
    }

    private String getAnswerText(Question question, int answerKey) {
        return GameAnswerOptions.getAnswerText(question, answerKey);
    }

    private int getAnswerKeyForDisplayedIndex(int displayedIndex) {
        return GameAnswerOptions.getAnswerKeyForDisplayedIndex(currentAnswerOrder, displayedIndex);
    }

    private int getDisplayedIndexForAnswerKey(int answerKey) {
        return GameAnswerOptions.getDisplayedIndexForAnswerKey(currentAnswerOrder, answerKey);
    }

    int getRightAnswer() {
        return GameAnswerOptions.getDisplayedIndexFromTextId(txtRight.getId());
    }

    void playSound(int resID, boolean fading, boolean looping) {
        if (soundController != null) {
            soundController.play(resID, fading, looping, EXITING);
        }
    }

    void stopCurrentSound() {
        if (soundController != null) {
            soundController.stopCurrent();
        }
    }

    void showDialog(final String message, final String tag, final int timeTalk, final int timeDialog, final int nextMouthId, final boolean gameStatusAfter) {
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
                        txtDialog.setCharacterDelay(DIALOG_CHARACTER_DELAY_MS);
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
    @Override
    protected void onPause() {
        if (backgroundVideoController != null) backgroundVideoController.pause();
        if(cdtProgress != null) cdtProgress.cancel();
        if (soundController != null) soundController.releaseCurrent();
        GameSoundController.release(mpBeep);
        mpBeep = null;
        GameSoundController.release(mpBeep1);
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
        stopCampaignStageTimer();
        if (soundController != null) soundController.releaseCurrent();
        GameSoundController.release(mpBeep);
        mpBeep = null;
        GameSoundController.release(mpBeep1);
        mpBeep1 = null;
        if (backgroundVideoController != null) backgroundVideoController.stop();
        backgroundVideoController = null;
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
        if (interstitialAdController != null) {
            interstitialAdController.loadIfNeeded(this::navigateToHome);
        }
    }
    private void persistPendingCampaignStageResult(boolean completed, int money, int wrongAnswers) {
        campaignResultStore.persistPendingStageResult(completed, money, wrongAnswers);
    }

    private void updateInventoryBadges() {
        InventoryBadgeUpdater.update(this);
    }

}





