package com.Qi7bali.millionchallengeonline;

import android.content.Context;
import android.net.ConnectivityManager;
import android.net.NetworkInfo;
import android.widget.ImageView;

import androidx.annotation.Nullable;

import com.google.firebase.FirebaseApp;
import com.google.firebase.auth.FirebaseAuth;
import com.google.firebase.database.DataSnapshot;
import com.google.firebase.database.DatabaseError;
import com.google.firebase.database.DatabaseReference;
import com.google.firebase.database.FirebaseDatabase;
import com.google.firebase.database.MutableData;
import com.google.firebase.database.Query;
import com.google.firebase.database.ServerValue;
import com.google.firebase.database.Transaction;
import com.google.firebase.database.ValueEventListener;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.TreeMap;

public class Data {

    boolean listenOpponentAnswer = false;
    boolean listenGameID = false;
    int numQuestion;
    String opponentAcceptingID;

    private static final String GUEST_ID = "guest_local";

    public static boolean isNetworkAvailable(Context con) {
        try {
            ConnectivityManager cm = (ConnectivityManager) con.getSystemService(Context.CONNECTIVITY_SERVICE);
            NetworkInfo networkInfo = cm != null ? cm.getActiveNetworkInfo() : null;
            return networkInfo != null && networkInfo.isConnected();
        } catch (Exception e) {
            return false;
        }
    }

    public void setOpponentAcceptingID(String opponentAcceptingID) {
        this.opponentAcceptingID = opponentAcceptingID;
    }

    public static String buildFriendCode(String userID) {
        if (userID == null) {
            return "";
        }
        String normalized = userID.replaceAll("[^A-Za-z0-9]", "").toUpperCase(Locale.US);
        if (normalized.isEmpty()) {
            return "";
        }
        return normalized.length() > 10 ? normalized.substring(0, 10) : normalized;
    }

    public static void syncUserProfile(String userID, String name, String photo, int level, int score) {
        if (!isRealUser(userID)) {
            return;
        }
        HashMap<String, Object> payload = new HashMap<>();
        payload.put("Name", safeName(name));
        payload.put("Photo", photo == null ? "" : photo);
        payload.put("Level", Math.max(1, level));
        payload.put("Score", Math.max(0, score));
        payload.put("FriendCode", buildFriendCode(userID));
        payload.put("UpdatedAt", ServerValue.TIMESTAMP);
        usersRegisteredRef().child(userID).updateChildren(payload);
    }

    public static void setUserScore(String userID, int score) {
        if (!isRealUser(userID)) {
            return;
        }
        usersRegisteredRef().child(userID).child("Score").setValue(Math.max(0, score));
    }

    public static void setUserLevel(String userID, int level) {
        if (!isRealUser(userID)) {
            return;
        }
        usersRegisteredRef().child(userID).child("Level").setValue(Math.max(1, level));
    }

    public static void setUserActive(String userID) {
        if (!isRealUser(userID)) {
            return;
        }
        usersActiveRef().child(userID).setValue(true);
    }

    public static void setUserInactive(String userID) {
        if (!isRealUser(userID)) {
            return;
        }
        usersActiveRef().child(userID).setValue(false);
    }

    public static void removeTempGameID(final String gameID) {
        if (gameID == null || gameID.trim().isEmpty()) {
            return;
        }
        tempRef().orderByChild("gameID").equalTo(gameID).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                for (DataSnapshot child : snapshot.getChildren()) {
                    child.getRef().removeValue();
                }
            }

            @Override
            public void onCancelled(DatabaseError error) {
            }
        });
    }

    public static void insertRequest(String userID) {
        insertRequest(userID, "");
    }

    public static void insertRequest(String userID, @Nullable String targetId) {
        if (!isRealUser(userID)) {
            return;
        }
        HashMap<String, Object> payload = new HashMap<>();
        payload.put("userId", userID);
        payload.put("acceptedBy", "0");
        payload.put("status", "waiting");
        payload.put("targetId", targetId == null ? "" : targetId.trim());
        payload.put("createdAt", ServerValue.TIMESTAMP);
        requestsRef().child(userID).setValue(payload);
    }

    public static void setFictitiousOpponent(String userID, String opponentID) {
        if (gameExists(opponentID)) {
            return;
        }
        tempRef().child(userID).child("fictitiousOpponent").setValue(opponentID);
    }

    public static void insertMyAnswer(int answer, String myID, String gameID) {
        if (gameID == null || gameID.trim().isEmpty() || myID == null || myID.trim().isEmpty()) {
            return;
        }
        gamesRef().child(gameID).child(myID).child("answer").setValue(answer);
    }

    public static void simulateFictitiousAnswer(int answer, String opponentID, String gameID) {
        if (gameID == null || gameID.trim().isEmpty() || opponentID == null || opponentID.trim().isEmpty()) {
            return;
        }
        gamesRef().child(gameID).child(opponentID).child("answer").setValue(answer);
    }

    public static void cancelRequest(String userID) {
        if (!isRealUser(userID)) {
            return;
        }
        requestsRef().child(userID).removeValue();
    }

    public static void acceptRequest(String userID, String opponentID) {
        if (!isRealUser(userID) || !isRealUser(opponentID)) {
            return;
        }
        requestsRef().child(opponentID).child("acceptedBy").setValue(userID);
        requestsRef().child(opponentID).child("status").setValue("matched");
    }

    public static void setImageSource(Context context, ImageView img, String src) {
        try {
            if (src == null || src.trim().isEmpty()) {
                img.setImageResource(R.drawable.user);
            } else if (src.startsWith("drawable:")) {
                String drawableName = src.substring("drawable:".length()).trim();
                int drawableId = context.getResources().getIdentifier(
                        drawableName,
                        "drawable",
                        context.getPackageName()
                );
                if (drawableId != 0) {
                    img.setImageResource(drawableId);
                } else {
                    img.setImageResource(R.drawable.user);
                }
            } else {
                PicassoClient.downloadImage(context, src, img, false);
            }
        } catch (Exception ignored) {
            try {
                img.setImageResource(R.drawable.user);
            } catch (Exception ignored2) {
            }
        }
    }

    public static void setGamePlayerStatus(String gameID, String playerID, String status) {
        if (gameID == null || gameID.trim().isEmpty() || playerID == null || playerID.trim().isEmpty()) {
            return;
        }
        HashMap<String, Object> payload = new HashMap<>();
        payload.put("status", status == null ? "" : status.trim());
        payload.put("updatedAt", ServerValue.TIMESTAMP);
        gamesRef().child(gameID).child(playerID).updateChildren(payload);
    }

    public static void initQuestionPlayer(String gameID, String playerID, int questionIndex) {
        if (gameID == null || gameID.trim().isEmpty() || playerID == null || playerID.trim().isEmpty()) {
            return;
        }
        HashMap<String, Object> payload = new HashMap<>();
        payload.put("answer", 0);
        payload.put("current", questionIndex);
        gamesRef().child(gameID).child(playerID).updateChildren(payload);
    }

    public void getQuestions(final String gameID, final OnGetQuestionsListener listener) {
        getGameQuestions(gameID, listener);
    }

    public void getGameQuestions(final String gameID, final OnGetQuestionsListener listener) {
        gamesRef().child(gameID).child("questions").addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                ArrayList<Question> questions = parseQuestions(snapshot);
                if (listener != null) {
                    listener.onSuccess(questions);
                }
            }

            @Override
            public void onCancelled(DatabaseError error) {
                if (listener != null) {
                    listener.onFailed(error);
                }
            }
        });
    }

    public void getRandomRequest(final OnRandomRequestListener listener) {
        if (listener != null) {
            listener.onStart();
        }
        final String currentUserId = getCurrentUserId();
        if (!isRealUser(currentUserId)) {
            if (listener != null) {
                listener.onSuccess("null");
            }
            return;
        }
        requestsRef().orderByChild("createdAt").limitToFirst(50).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                final ArrayList<String> candidates = new ArrayList<>();
                for (DataSnapshot child : snapshot.getChildren()) {
                    String requesterId = child.getKey();
                    if (requesterId == null || requesterId.equals(currentUserId)) {
                        continue;
                    }
                    String status = valueAsString(child.child("status"));
                    String acceptedBy = valueAsString(child.child("acceptedBy"));
                    String targetId = valueAsString(child.child("targetId"));
                    if (!status.isEmpty() && !"waiting".equals(status)) {
                        continue;
                    }
                    if (!acceptedBy.isEmpty() && !"0".equals(acceptedBy)) {
                        continue;
                    }
                    if (!targetId.isEmpty() && !targetId.equals(currentUserId)) {
                        continue;
                    }
                    candidates.add(requesterId);
                }
                claimRequestCandidate(currentUserId, candidates, 0, listener);
            }

            @Override
            public void onCancelled(DatabaseError error) {
                if (listener != null) {
                    listener.onFailed(error);
                }
            }
        });
    }

    public void getRequestResponse(String userID, final OnGetRequestResponseListener listener) {
        if (listener != null) {
            listener.onStart();
        }
        requestsRef().child(userID).child("acceptedBy").addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                String acceptedBy = valueAsString(snapshot);
                if (listener != null) {
                    listener.onSuccess(acceptedBy.isEmpty() ? "0" : acceptedBy);
                }
                if (!acceptedBy.isEmpty() && !"0".equals(acceptedBy)) {
                    snapshot.getRef().removeEventListener(this);
                }
            }

            @Override
            public void onCancelled(DatabaseError error) {
                if (listener != null) {
                    listener.onFailed(error);
                }
            }
        });
    }

    public void getAnswer(String gameID, final String opponentID, final int expectedQuestionIndex, final OnGetAnswersListener listener) {
        if (listener != null) {
            listener.onStart();
        }
        gamesRef().child(gameID).child(opponentID).addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                String status = valueAsString(snapshot.child("status"));
                if ("left".equals(status)) {
                    if (listener != null) {
                        listener.onSuccess(-1L);
                    }
                    snapshot.getRef().removeEventListener(this);
                    return;
                }
                int currentQuestionIndex = parseInt(snapshot.child("current").getValue(), -1);
                Long answer = snapshot.child("answer").getValue(Long.class);
                if (currentQuestionIndex != expectedQuestionIndex) {
                    if (listener != null) {
                        listener.onSuccess(0L);
                    }
                    return;
                }
                long safeAnswer = answer == null ? 0L : answer;
                if (listener != null) {
                    listener.onSuccess(safeAnswer);
                }
                if (safeAnswer > 0) {
                    snapshot.getRef().removeEventListener(this);
                }
            }

            @Override
            public void onCancelled(DatabaseError error) {
                if (listener != null) {
                    listener.onFailed(error);
                }
            }
        });
    }

    public void createGameID(final String myID, final String opponentID, final String opponentName,
                             final OnCreateGameIdListener listener) {
        ArrayList<String> opponentIds = new ArrayList<>();
        if (opponentID != null && !opponentID.trim().isEmpty()) {
            opponentIds.add(opponentID);
        }
        createGameID(myID, opponentIds, listener);
    }

    public void createGameID(final String myID, final ArrayList<String> opponentIds,
                             final OnCreateGameIdListener listener) {
        final DatabaseReference gameRef = gamesRef().push();
        final String gameID = gameRef.getKey() == null ? String.valueOf(System.currentTimeMillis()) : gameRef.getKey();

        ArrayList<Question> questions = loadSharedQuestions();
        HashMap<String, Object> payload = new HashMap<>();
        payload.put("meta/createdAt", ServerValue.TIMESTAMP);
        payload.put("meta/ownerId", myID);
        payload.put("meta/playerCount", 1 + (opponentIds == null ? 0 : opponentIds.size()));
        payload.put(myID + "/answer", 0);
        payload.put(myID + "/current", 0);
        if (opponentIds != null) {
            for (String opponentId : opponentIds) {
                if (opponentId == null || opponentId.trim().isEmpty()) {
                    continue;
                }
                payload.put(opponentId + "/answer", 0);
                payload.put(opponentId + "/current", 0);
                payload.put(opponentId + "/status", "active");
            }
        }
        payload.put(myID + "/status", "active");

        int index = 0;
        for (Question question : questions) {
            String key = String.format(Locale.US, "questions/q%02d", index++);
            payload.put(key + "/Level", question.getLevel());
            payload.put(key + "/Q", question.getQ());
            payload.put(key + "/R", question.getR());
            payload.put(key + "/W1", question.getW1());
            payload.put(key + "/W2", question.getW2());
            payload.put(key + "/W3", question.getW3());
        }

        gameRef.updateChildren(payload, (error, ref) -> {
            if (error != null) {
                if (listener != null) {
                    listener.onFailed(error);
                }
                return;
            }
            requestsRef().child(myID).removeValue();
            if (opponentIds != null) {
                for (String opponentId : opponentIds) {
                    if (opponentId == null || opponentId.trim().isEmpty()) {
                        continue;
                    }
                    requestsRef().child(opponentId).removeValue();
                }
            }
            if (listener != null) {
                listener.onSuccess(gameID);
            }
        });
    }

    public void getGameID(String myID, final OnGetGameIdListener listener) {
        tempRef().child(myID).child("gameID").addValueEventListener(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                String gameID = valueAsString(snapshot);
                if (listener != null) {
                    listener.onSuccess(gameID);
                }
                if (!gameID.isEmpty()) {
                    snapshot.getRef().removeEventListener(this);
                }
            }

            @Override
            public void onCancelled(DatabaseError error) {
                if (listener != null) {
                    listener.onFailed(error);
                }
            }
        });
    }

    public void getUserFromFirebase(final String userID, final OnGetUserInfoListener listener) {
        if (listener != null) {
            listener.onStart();
        }
        usersRegisteredRef().child(userID).addListenerForSingleValueEvent(new ValueEventListener() {
            @Override
            public void onDataChange(DataSnapshot snapshot) {
                if (listener == null) {
                    return;
                }
                if (!snapshot.exists()) {
                    listener.onSuccess(null);
                    return;
                }
                listener.onSuccess(parseUser(snapshot, userID));
            }

            @Override
            public void onCancelled(DatabaseError error) {
                if (listener != null) {
                    listener.onFailed(error);
                }
            }
        });
    }

    public void readFirebaseData(Object reference, final OnReadFirebaseListener listener) {
        if (listener != null) {
            listener.onStart();
        }
        if (reference instanceof Query) {
            ((Query) reference).addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    if (listener != null) {
                        listener.onSuccess(snapshot);
                    }
                }

                @Override
                public void onCancelled(DatabaseError error) {
                    if (listener != null) {
                        listener.onFailed(error);
                    }
                }
            });
        } else if (reference instanceof DatabaseReference) {
            ((DatabaseReference) reference).addListenerForSingleValueEvent(new ValueEventListener() {
                @Override
                public void onDataChange(DataSnapshot snapshot) {
                    if (listener != null) {
                        listener.onSuccess(snapshot);
                    }
                }

                @Override
                public void onCancelled(DatabaseError error) {
                    if (listener != null) {
                        listener.onFailed(error);
                    }
                }
            });
        } else if (listener != null) {
            listener.onFailed(null);
        }
    }

    public void getFictitiousPlayer(final OnGetFictitiousListener listener) {
        if (listener != null) {
            listener.onStart();
            User user = new User("fictitious");
            user.setName("خصم افتراضي");
            user.setPhoto("");
            user.setLevel(1);
            user.setScore(0);
            listener.onSuccess(user);
        }
    }

    public void getUserIdByFriendCode(String friendCode, final OnGetGameIdListener listener) {
        String normalizedCode = normalizeFriendCode(friendCode);
        if (normalizedCode.isEmpty()) {
            if (listener != null) {
                listener.onSuccess("");
            }
            return;
        }
        usersRegisteredRef()
                .orderByChild("FriendCode")
                .equalTo(normalizedCode)
                .limitToFirst(1)
                .addListenerForSingleValueEvent(new ValueEventListener() {
                    @Override
                    public void onDataChange(DataSnapshot snapshot) {
                        String userId = "";
                        for (DataSnapshot child : snapshot.getChildren()) {
                            userId = child.getKey();
                            break;
                        }
                        if (listener != null) {
                            listener.onSuccess(userId == null ? "" : userId);
                        }
                    }

                    @Override
                    public void onCancelled(DatabaseError error) {
                        if (listener != null) {
                            listener.onFailed(error);
                        }
                    }
                });
    }

    private static DatabaseReference rootRef() {
        return FirebaseDatabase.getInstance().getReference();
    }

    private static DatabaseReference usersRegisteredRef() {
        return rootRef().child("Users").child("Registered");
    }

    private static DatabaseReference usersActiveRef() {
        return rootRef().child("Users").child("Active");
    }

    private static DatabaseReference requestsRef() {
        return rootRef().child("Requests");
    }

    private static DatabaseReference tempRef() {
        return rootRef().child("temp");
    }

    private static DatabaseReference gamesRef() {
        return rootRef().child("Games");
    }

    private void claimRequestCandidate(final String currentUserId,
                                       final ArrayList<String> candidates,
                                       final int index,
                                       final OnRandomRequestListener listener) {
        if (index >= candidates.size()) {
            if (listener != null) {
                listener.onSuccess("null");
            }
            return;
        }

        final String requesterId = candidates.get(index);
        requestsRef().child(requesterId).runTransaction(new Transaction.Handler() {
            @Override
            public Transaction.Result doTransaction(MutableData currentData) {
                if (currentData.getValue() == null) {
                    return Transaction.abort();
                }
                String status = valueAsString(currentData.child("status").getValue());
                String acceptedBy = valueAsString(currentData.child("acceptedBy").getValue());
                String targetId = valueAsString(currentData.child("targetId").getValue());
                if (!status.isEmpty() && !"waiting".equals(status)) {
                    return Transaction.abort();
                }
                if (!acceptedBy.isEmpty() && !"0".equals(acceptedBy)) {
                    return Transaction.abort();
                }
                if (!targetId.isEmpty() && !targetId.equals(currentUserId)) {
                    return Transaction.abort();
                }
                currentData.child("acceptedBy").setValue(currentUserId);
                currentData.child("status").setValue("matched");
                return Transaction.success(currentData);
            }

            @Override
            public void onComplete(@Nullable DatabaseError error, boolean committed, @Nullable DataSnapshot currentData) {
                if (error != null) {
                    if (listener != null) {
                        listener.onFailed(error);
                    }
                    return;
                }
                if (committed) {
                    if (listener != null) {
                        listener.onSuccess(requesterId);
                    }
                } else {
                    claimRequestCandidate(currentUserId, candidates, index + 1, listener);
                }
            }
        });
    }

    private static ArrayList<Question> parseQuestions(DataSnapshot snapshot) {
        ArrayList<Question> result = new ArrayList<>();
        if (snapshot == null || !snapshot.exists()) {
            return result;
        }
        TreeMap<String, Question> sorted = new TreeMap<>();
        for (DataSnapshot child : snapshot.getChildren()) {
            Question question = new Question();
            question.setLevel(valueAsString(child.child("Level")));
            question.setQ(valueAsString(child.child("Q")));
            question.setR(valueAsString(child.child("R")));
            question.setW1(valueAsString(child.child("W1")));
            question.setW2(valueAsString(child.child("W2")));
            question.setW3(valueAsString(child.child("W3")));
            sorted.put(child.getKey() == null ? String.valueOf(sorted.size()) : child.getKey(), question);
        }
        result.addAll(sorted.values());
        return result;
    }

    private static User parseUser(DataSnapshot snapshot, String userID) {
        User user = new User(userID);
        user.setName(valueAsString(snapshot.child("Name")));
        user.setPhoto(valueAsString(snapshot.child("Photo")));
        user.setLevel(parseInt(snapshot.child("Level").getValue(), 1));
        user.setScore(parseInt(snapshot.child("Score").getValue(), 0));
        if (user.getName() == null || user.getName().trim().isEmpty()) {
            user.setName("لاعب");
        }
        return user;
    }

    private static ArrayList<Question> loadSharedQuestions() {
        try {
            Context context = FirebaseApp.getInstance().getApplicationContext();
            return LocalQuestions.load(context);
        } catch (Exception e) {
            return new ArrayList<>();
        }
    }

    private static String getCurrentUserId() {
        try {
            if (FirebaseAuth.getInstance().getCurrentUser() != null) {
                return FirebaseAuth.getInstance().getCurrentUser().getUid();
            }
        } catch (Exception ignored) {
        }
        return "";
    }

    private static boolean isRealUser(String userID) {
        return userID != null && !userID.trim().isEmpty() && !GUEST_ID.equals(userID);
    }

    private static String safeName(String name) {
        String normalized = name == null ? "" : name.trim();
        if (normalized.isEmpty()) {
            return "لاعب";
        }
        if ("guest".equalsIgnoreCase(normalized) || "player".equalsIgnoreCase(normalized)) {
            return "لاعب";
        }
        return normalized;
    }

    private static String normalizeFriendCode(String friendCode) {
        if (friendCode == null) {
            return "";
        }
        return friendCode.replaceAll("[^A-Za-z0-9]", "").toUpperCase(Locale.US);
    }

    private static boolean gameExists(String value) {
        return value != null && !value.trim().isEmpty();
    }

    private static int parseInt(Object value, int fallback) {
        if (value instanceof Number) {
            return ((Number) value).intValue();
        }
        try {
            return Integer.parseInt(String.valueOf(value));
        } catch (Exception ignored) {
            return fallback;
        }
    }

    private static String valueAsString(DataSnapshot snapshot) {
        if (snapshot == null) {
            return "";
        }
        Object value = snapshot.getValue();
        return value == null ? "" : String.valueOf(value).trim();
    }

    private static String valueAsString(Object value) {
        return value == null ? "" : String.valueOf(value).trim();
    }
}



