package net.androidgaming.millionaire2024;

import com.google.firebase.database.DatabaseError;

public interface OnGetRequestResponseListener {
    void onStart();
    void onSuccess(String opponentID);
    void onFailed(DatabaseError error);
}
