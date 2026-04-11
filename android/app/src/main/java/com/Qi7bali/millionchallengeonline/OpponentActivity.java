package com.Qi7bali.millionchallengeonline;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.content.SharedPreferences;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.google.firebase.database.DatabaseError;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.Random;

public class OpponentActivity extends AppCompatActivity {

    boolean browsingOpponents = false;
    boolean requestAccepted = false;
    boolean ownRequestInserted = false;
    boolean launchingGame = false;
    String userID = "";
    String userName = "";
    String userPhoto = "";
    String matchMode = "";
    String friendCode = "";
    int userLevel = 1;
    int userScore = 0;

    ImageView imgPhoto1, imgPhoto2, imgPhoto21, imgPhoto22;
    TextView txtOpponent1, txtOpponent2, txtLevel1, txtLevel2, txtStatus;

    private final Handler matchmakingHandler = new Handler();
    private Runnable matchmakingRunnable;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_opponent);

        imgPhoto1 = findViewById(R.id.imgPhoto1);
        imgPhoto2 = findViewById(R.id.imgPhoto2);
        imgPhoto21 = findViewById(R.id.imgPhoto21);
        imgPhoto22 = findViewById(R.id.imgPhoto22);
        txtOpponent1 = findViewById(R.id.txtOpponent1);
        txtOpponent2 = findViewById(R.id.txtOpponent2);
        txtLevel1 = findViewById(R.id.txtLevel1);
        txtLevel2 = findViewById(R.id.txtLevel2);
        txtStatus = findViewById(R.id.txtStatus);

        SharedPreferences settings = getSharedPreferences("UserInfo", 0);
        userID = settings.getString("userID", "");
        userName = settings.getString("userName", "");
        userPhoto = settings.getString("userPhoto", "");
        userLevel = settings.getInt("userLevel", 1);
        userScore = settings.getInt("userScore", 0);

        matchMode = getIntent().getStringExtra("matchMode") == null ? "" : getIntent().getStringExtra("matchMode");
        friendCode = getIntent().getStringExtra("friendCode") == null ? "" : getIntent().getStringExtra("friendCode").trim().toUpperCase();

        txtOpponent1.setText(userName);
        Data.setImageSource(this, imgPhoto1, userPhoto);
        txtLevel1.setText(String.valueOf(userLevel));

        Data.syncUserProfile(userID, userName, userPhoto, userLevel, userScore);
        Data.setUserActive(userID);

        startBrowsingOpponents();
        if ("friend".equals(matchMode) && !friendCode.isEmpty()) {
            startFriendInviteFlow();
        } else {
            startRandomMatchFlow();
        }
    }

    private void startFriendInviteFlow() {
        setStatus("جاري تجهيز تحدي الصديق...");
        new Data().getUserIdByFriendCode(friendCode, new OnGetGameIdListener() {
            @Override
            public void onSuccess(String targetUserId) {
                if (launchingGame) {
                    return;
                }
                if (targetUserId == null || targetUserId.trim().isEmpty()) {
                    Toast.makeText(OpponentActivity.this, "كود الصديق غير صحيح", Toast.LENGTH_SHORT).show();
                    finish();
                    return;
                }
                if (targetUserId.equals(userID)) {
                    Toast.makeText(OpponentActivity.this, "لا يمكنك تحدي نفسك", Toast.LENGTH_SHORT).show();
                    return;
                }
                ownRequestInserted = true;
                Data.insertRequest(userID, targetUserId);
                waitForAcceptedRequest();
                setStatus("تم إرسال الدعوة. بانتظار دخول صديقك...");
            }

            @Override
            public void onFailed(DatabaseError error) {
                Toast.makeText(OpponentActivity.this, "تعذر العثور على الصديق الآن", Toast.LENGTH_SHORT).show();
                finish();
            }
        });
    }

    private void startRandomMatchFlow() {
        setStatus("جاري البحث عن منافس عبر الإنترنت...");
        waitForAcceptedRequest();
        tryClaimAvailableOpponent();
    }

    private void tryClaimAvailableOpponent() {
        if (launchingGame) {
            return;
        }
        new Data().getRandomRequest(new OnRandomRequestListener() {
            @Override
            public void onStart() {
            }

            @Override
            public void onSuccess(String idOpponent) {
                if (launchingGame) {
                    return;
                }
                if (idOpponent != null && !idOpponent.isEmpty() && !"null".equals(idOpponent)) {
                    requestAccepted = true;
                    resolveOpponentAndLaunch(idOpponent, false);
                    return;
                }
                if (!ownRequestInserted) {
                    ownRequestInserted = true;
                    Data.insertRequest(userID);
                    setStatus("لم يتم العثور على خصم فورًا. بانتظار لاعب آخر...");
                }
                scheduleRetry();
            }

            @Override
            public void onFailed(DatabaseError error) {
                scheduleRetry();
            }
        });
    }

    private void waitForAcceptedRequest() {
        new Data().getRequestResponse(userID, new OnGetRequestResponseListener() {
            @Override
            public void onStart() {
            }

            @Override
            public void onSuccess(String opponentID) {
                if (launchingGame) {
                    return;
                }
                if (opponentID != null && !opponentID.isEmpty() && !"0".equals(opponentID)) {
                    requestAccepted = true;
                    resolveOpponentAndLaunch(opponentID, true);
                }
            }

            @Override
            public void onFailed(DatabaseError error) {
            }
        });
    }

    private void resolveOpponentAndLaunch(final String opponentId, final boolean meOwner) {
        new Data().getUserFromFirebase(opponentId, new OnGetUserInfoListener() {
            @Override
            public void onStart() {
            }

            @Override
            public void onSuccess(User user) {
                if (launchingGame) {
                    return;
                }
                if (user == null) {
                    Toast.makeText(OpponentActivity.this, "تعذر تحميل بيانات المنافس", Toast.LENGTH_SHORT).show();
                    return;
                }
                stopBrowsingOpponents(user, meOwner);
            }

            @Override
            public void onFailed(DatabaseError error) {
                Toast.makeText(OpponentActivity.this, "تعذر تحميل بيانات المنافس", Toast.LENGTH_SHORT).show();
            }
        });
    }

    private void scheduleRetry() {
        if (launchingGame || "friend".equals(matchMode)) {
            return;
        }
        matchmakingHandler.removeCallbacks(matchmakingRunnable);
        matchmakingRunnable = new Runnable() {
            @Override
            public void run() {
                if (!requestAccepted && !launchingGame) {
                    tryClaimAvailableOpponent();
                }
            }
        };
        matchmakingHandler.postDelayed(matchmakingRunnable, 2000);
    }

    private void startBrowsingOpponents() {
        final int margin = 180;
        final int duration = 500;

        browsingOpponents = true;

        setRandomOpponentImage(imgPhoto21, 14);
        Animations.animOpponent(imgPhoto21, duration, margin);

        final Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            boolean photo1 = true;

            @Override
            public void run() {
                if (browsingOpponents) {
                    if (photo1) {
                        setRandomOpponentImage(imgPhoto22, 14);
                        Animations.animOpponent(imgPhoto22, duration, margin);
                        photo1 = false;
                    } else {
                        setRandomOpponentImage(imgPhoto21, 14);
                        Animations.animOpponent(imgPhoto21, duration, margin);
                        photo1 = true;
                    }
                    handler.postDelayed(this, duration / 2);
                }
            }
        };
        handler.postDelayed(runnable, duration / 2);
    }

    private void stopBrowsingOpponents(final User opponent, final boolean meOwner) {
        launchingGame = true;
        requestAccepted = true;
        browsingOpponents = false;
        matchmakingHandler.removeCallbacksAndMessages(null);
        if (ownRequestInserted) {
            Data.cancelRequest(userID);
            ownRequestInserted = false;
        }
        imgPhoto22.clearAnimation();
        imgPhoto21.clearAnimation();
        imgPhoto21.setVisibility(View.INVISIBLE);
        imgPhoto22.setVisibility(View.INVISIBLE);
        imgPhoto2.setVisibility(View.VISIBLE);
        Data.setImageSource(this, imgPhoto2, opponent.photo);
        txtOpponent2.setText(opponent.name);
        txtLevel2.setText(String.valueOf(opponent.level));
        setStatus("تم العثور على منافس. جاري بدء المباراة...");

        Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                Intent intent = new Intent(OpponentActivity.this, GameActivity.class);
                intent.putExtra("mode", "online");
                intent.putExtra("meOwner", meOwner);
                try {
                    JSONObject opponentJson = new JSONObject();
                    opponentJson.put("id", opponent.id);
                    opponentJson.put("name", opponent.name);
                    opponentJson.put("photo", opponent.photo != null ? opponent.photo : "");
                    opponentJson.put("level", opponent.level);
                    opponentJson.put("score", opponent.score);
                    opponentJson.put("bot", false);
                    JSONArray opponentsArray = new JSONArray();
                    opponentsArray.put(opponentJson);
                    intent.putExtra("opponentsJson", opponentsArray.toString());
                } catch (Exception e) {
                    intent.putExtra("opponentsJson", "[]");
                }
                startActivity(intent);
                finish();
            }
        };
        handler.postDelayed(runnable, 1000);
    }

    private void setRandomOpponentImage(ImageView img, int maxNumber) {
        int rnd = (new Random()).nextInt(maxNumber) + 1;
        int idImage = this.getResources().getIdentifier("opponent" + String.format("%02d", rnd), "drawable", this.getPackageName());
        img.setImageResource(idImage);
    }

    private void setStatus(String message) {
        if (txtStatus != null) {
            txtStatus.setText(message);
        }
    }

    private void cleanupPendingRequest() {
        matchmakingHandler.removeCallbacksAndMessages(null);
        if (ownRequestInserted && !launchingGame) {
            Data.cancelRequest(userID);
            ownRequestInserted = false;
        }
    }

    @Override
    protected void onDestroy() {
        cleanupPendingRequest();
        super.onDestroy();
    }

    @Override
    public void onBackPressed() {
        cleanupPendingRequest();
        super.onBackPressed();
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
}
