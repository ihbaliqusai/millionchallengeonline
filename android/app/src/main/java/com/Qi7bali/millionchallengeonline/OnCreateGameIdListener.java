package net.androidgaming.millionaire2024;

import com.google.firebase.database.DatabaseError;

public interface OnCreateGameIdListener {
    void onSuccess(String gameID);
    void onFailed(DatabaseError error);
}
