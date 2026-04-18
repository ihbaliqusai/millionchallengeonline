package net.androidgaming.millionaire2024;

import com.google.firebase.database.DatabaseError;
import java.util.ArrayList;

public interface OnGetQuestionsListener {
    void onSuccess(ArrayList<Question> questions);
    void onFailed(DatabaseError error);
}
