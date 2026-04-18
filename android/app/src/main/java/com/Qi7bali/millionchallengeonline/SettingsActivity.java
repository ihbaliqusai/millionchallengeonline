package net.androidgaming.millionaire2024;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.CompoundButton;
import android.widget.Switch;
import android.widget.TextView;
import android.widget.Toast;

import com.google.android.gms.auth.api.signin.GoogleSignIn;
import com.google.android.gms.auth.api.signin.GoogleSignInOptions;
import com.google.firebase.auth.FirebaseAuth;

public class SettingsActivity extends AppCompatActivity {

    private Switch swSound;
    private Switch swDialogs;
    private TextView txtSummary;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_settings);
        if (getSupportActionBar() != null) getSupportActionBar().hide();

        swSound = findViewById(R.id.swSound);
        swDialogs = findViewById(R.id.swDialogs);
        txtSummary = findViewById(R.id.txtSettingsSummary);

        swSound.setChecked(AppPrefs.isSoundEnabled(this));
        swDialogs.setChecked(AppPrefs.isDialogsEnabled(this));
        updateSummary();

        swSound.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                AppPrefs.setSoundEnabled(SettingsActivity.this, isChecked);
                Toast.makeText(
                        SettingsActivity.this,
                        isChecked ? "تم تشغيل الصوت" : "تم كتم الصوت",
                        Toast.LENGTH_SHORT
                ).show();
                updateSummary();
            }
        });

        swDialogs.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                AppPrefs.setDialogsEnabled(SettingsActivity.this, isChecked);
                updateSummary();
            }
        });

        findViewById(R.id.btnResetStats).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                new AlertDialog.Builder(SettingsActivity.this)
                        .setTitle("إعادة ضبط الإحصائيات")
                        .setMessage("سيتم مسح الإحصائيات فقط مع الاحتفاظ بالإنجازات والعملات والمستوى.")
                        .setPositiveButton("متابعة", (dialog, which) -> {
                            PlayerStats.reset(SettingsActivity.this);
                            Toast.makeText(SettingsActivity.this, "تمت إعادة ضبط الإحصائيات", Toast.LENGTH_SHORT).show();
                            updateSummary();
                        })
                        .setNegativeButton("إلغاء", null)
                        .show();
            }
        });

        findViewById(R.id.btnResetProgress).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                new AlertDialog.Builder(SettingsActivity.this)
                        .setTitle("إعادة ضبط التقدم")
                        .setMessage("سيتم مسح العملات والجواهر والإنجازات والمستوى والإحصائيات.")
                        .setPositiveButton("إعادة ضبط", (dialog, which) -> {
                            AppPrefs.resetLocalProgress(SettingsActivity.this);
                            Toast.makeText(SettingsActivity.this, "تمت إعادة ضبط التقدم المحلي", Toast.LENGTH_SHORT).show();
                            updateSummary();
                        })
                        .setNegativeButton("إلغاء", null)
                        .show();
            }
        });

        findViewById(R.id.btnLogout).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                signOutAndReturnToLogin();
            }
        });

        findViewById(R.id.btnCloseSettings).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });
    }

    private void updateSummary() {
        String summary = "المستوى: " + AppPrefs.getLevel(this)
                + "\nXP: " + AppPrefs.getXp(this)
                + "\nالعملات: " + AppPrefs.getCoins(this)
                + "\nالجواهر: " + AppPrefs.getGems(this)
                + "\nالصوت: " + (AppPrefs.isSoundEnabled(this) ? "مفعل" : "مكتوم")
                + "\nالنوافذ التوضيحية: " + (AppPrefs.isDialogsEnabled(this) ? "مفعلة" : "مخففة");
        txtSummary.setText(summary);
    }

    private void signOutAndReturnToLogin() {
        String userId = AppPrefs.getUserId(this);
        if (!userId.equals("guest_local")) {
            Data.setUserInactive(userId);
        }
        AppPrefs.setGuestUser(this);
        try {
            FirebaseAuth.getInstance().signOut();
        } catch (Exception ignored) {
        }
        try {
            GoogleSignInOptions gso = new GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
                    .requestEmail()
                    .build();
            GoogleSignIn.getClient(this, gso).signOut();
        } catch (Exception ignored) {
        }

        Intent intent = new Intent(SettingsActivity.this, MainActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK | Intent.FLAG_ACTIVITY_NO_ANIMATION);
        startActivity(intent);
        finish();
    }
}
