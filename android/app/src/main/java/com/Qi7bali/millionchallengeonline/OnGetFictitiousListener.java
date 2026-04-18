package net.androidgaming.millionaire2024;

import com.google.firebase.database.DatabaseError;

import java.util.ArrayList;

public interface OnGetFictitiousListener {
    void onStart();
    void onSuccess(User user);
    void onFailed(DatabaseError error);
}
