package net.androidgaming.millionaire2024;

import androidx.appcompat.app.AlertDialog;
import androidx.appcompat.app.AppCompatActivity;

import android.os.Bundle;
import android.view.View;
import android.view.Window;
import android.view.WindowManager;
import android.widget.TextView;
import android.widget.Toast;

public class StoreActivity extends AppCompatActivity {

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        supportRequestWindowFeature(Window.FEATURE_NO_TITLE);
        super.onCreate(savedInstanceState);
        getWindow().setFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN,
                WindowManager.LayoutParams.FLAG_FULLSCREEN);
        getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_HIDE_NAVIGATION);
        setContentView(R.layout.activity_store);
        if (getSupportActionBar() != null) getSupportActionBar().hide();

        findViewById(R.id.btnStoreBack).setOnClickListener(v -> finish());
        findViewById(R.id.btnBuy5050).setOnClickListener(v -> purchaseCoins("شراء 50:50 إضافية", 600, () -> PlayerProgress.addInventory(this, "5050", 1)));
        findViewById(R.id.btnBuyAudience).setOnClickListener(v -> purchaseCoins("شراء مساعدة الجمهور", 700, () -> PlayerProgress.addInventory(this, "audience", 1)));
        findViewById(R.id.btnBuyCall).setOnClickListener(v -> purchaseCoins("شراء الاتصال بصديق", 700, () -> PlayerProgress.addInventory(this, "call", 1)));
        findViewById(R.id.btnBuyGemPack).setOnClickListener(v -> purchaseCoins("شراء 5 جواهر", 1500, () -> PlayerProgress.addGems(this, 5)));
        findViewById(R.id.btnExchangeGems).setOnClickListener(v -> purchaseGems("تحويل 3 جواهر إلى 900 قطعة", 3, () -> PlayerProgress.addCoins(this, 900)));
        bind();
    }

    private interface Action { void run(); }

    private void purchaseCoins(String title, int price, Action action) {
        new AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage("السعر: " + price + " قطعة")
                .setPositiveButton("شراء", (d, i) -> {
                    if (PlayerProgress.spendCoins(this, price)) {
                        action.run();
                        Toast.makeText(this, "تم الشراء بنجاح", Toast.LENGTH_SHORT).show();
                        bind();
                    } else {
                        Toast.makeText(this, "لا تملك قطعًا كافية", Toast.LENGTH_SHORT).show();
                    }
                })
                .setNegativeButton("إلغاء", null)
                .show();
    }

    private void purchaseGems(String title, int price, Action action) {
        new AlertDialog.Builder(this)
                .setTitle(title)
                .setMessage("السعر: " + price + " جواهر")
                .setPositiveButton("شراء", (d, i) -> {
                    if (PlayerProgress.spendGems(this, price)) {
                        action.run();
                        Toast.makeText(this, "تم التنفيذ بنجاح", Toast.LENGTH_SHORT).show();
                        bind();
                    } else {
                        Toast.makeText(this, "لا تملك جواهر كافية", Toast.LENGTH_SHORT).show();
                    }
                })
                .setNegativeButton("إلغاء", null)
                .show();
    }

    private void bind() {
        setText(R.id.txtStoreCoins, String.valueOf(PlayerProgress.getCoins(this)));
        setText(R.id.txtStoreGems, String.valueOf(PlayerProgress.getGems(this)));
        setText(R.id.txtInv5050, String.valueOf(PlayerProgress.getInventory5050(this)));
        setText(R.id.txtInvAudience, String.valueOf(PlayerProgress.getInventoryAudience(this)));
        setText(R.id.txtInvCall, String.valueOf(PlayerProgress.getInventoryCall(this)));
    }

    private void setText(int id, String value) {
        ((TextView)findViewById(id)).setText(value);
    }
}
