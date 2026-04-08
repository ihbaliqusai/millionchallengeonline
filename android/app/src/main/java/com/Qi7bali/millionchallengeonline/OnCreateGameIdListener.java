package com.Qi7bali.millionchallengeonline;

import com.google.firebase.database.DatabaseError;

public interface OnCreateGameIdListener {
    void onSuccess(String gameID);
    void onFailed(DatabaseError error);
}
