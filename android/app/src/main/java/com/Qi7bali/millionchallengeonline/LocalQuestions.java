package com.Qi7bali.millionchallengeonline;

import android.content.Context;
import android.content.res.AssetManager;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.Random;

import io.flutter.FlutterInjector;

public class LocalQuestions {
    public static ArrayList<Question> load(Context context) {
        final ArrayList<Question> questions = new ArrayList<>();
        final ArrayList<Question> allQuestions0 = new ArrayList<>();
        final ArrayList<Question> allQuestions1 = new ArrayList<>();
        final ArrayList<Question> allQuestions2 = new ArrayList<>();
        final ArrayList<Question> allQuestions3 = new ArrayList<>();
        try {
            AssetManager assets = context.getAssets();
            InputStream inputStream = openQuestionsStream(assets);
            ByteArrayOutputStream output = new ByteArrayOutputStream();
            byte[] buffer = new byte[4096];
            int n;
            while ((n = inputStream.read(buffer)) >= 0) {
                output.write(buffer, 0, n);
            }
            inputStream.close();

            JSONArray array = new JSONArray(output.toString(StandardCharsets.UTF_8.name()));
            for (int i = 0; i < array.length(); i++) {
                JSONObject item = array.getJSONObject(i);
                Question q = new Question();
                q.setQ(item.optString("Q"));
                q.setR(item.optString("R"));
                q.setW1(item.optString("W1"));
                q.setW2(item.optString("W2"));
                q.setW3(item.optString("W3"));
                q.setLevel(item.optString("Level"));
                switch (q.getLevel()) {
                    case "0":
                        allQuestions0.add(q);
                        break;
                    case "1":
                        allQuestions1.add(q);
                        break;
                    case "2":
                        allQuestions2.add(q);
                        break;
                    case "3":
                        allQuestions3.add(q);
                        break;
                }
            }
            populate(questions, allQuestions0, 3);
            populate(questions, allQuestions1, 3);
            populate(questions, allQuestions2, 5);
            populate(questions, allQuestions3, 4);
        } catch (Exception ignored) {
        }
        return questions;
    }

    private static void populate(ArrayList<Question> questions, ArrayList<Question> subList, int count) {
        if (subList.isEmpty()) return;
        ArrayList<Integer> used = new ArrayList<>();
        Random random = new Random();
        for (int i = 0; i < count && used.size() < subList.size(); i++) {
            int idx;
            do {
                idx = random.nextInt(subList.size());
            } while (used.contains(idx));
            used.add(idx);
            questions.add(subList.get(idx));
        }
    }

    private static InputStream openQuestionsStream(AssetManager assets) throws Exception {
        try {
            String flutterAssetPath = FlutterInjector.instance()
                    .flutterLoader()
                    .getLookupKeyForAsset("assets/questions.json");
            return assets.open(flutterAssetPath);
        } catch (Exception ignored) {
            return assets.open("questions.json");
        }
    }
}
