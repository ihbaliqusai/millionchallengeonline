package com.Qi7bali.millionchallengeonline;

import com.google.firebase.database.DatabaseError;

public interface OnGetUserInfoListener {
    void onStart();
    void onSuccess(User user);
    void onFailed(DatabaseError error);
}
