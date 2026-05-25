package net.androidgaming.millionaire2024;

import android.graphics.ColorMatrix;
import android.graphics.ColorMatrixColorFilter;
import android.os.CountDownTimer;
import android.os.Handler;
import android.view.View;
import android.view.animation.TranslateAnimation;
import android.widget.ImageView;
import android.widget.LinearLayout;

import java.util.ArrayList;
import java.util.Random;

final class GameLifelineController {
    private final GameActivity activity;

    GameLifelineController(GameActivity activity) {
        this.activity = activity;
    }

    void hideTwoAnswers() {
        ArrayList<Integer> idxs = new ArrayList<>();
        int idx;
        while (idxs.size() < 2) {
            do {
                idx = (new Random()).nextInt(4);
            } while ((idxs.contains(idx)) || (activity.listAnswerViews.get(idx).getTag().toString().equals("1")));
            idxs.add(idx);
        }
        activity.listAnswerViews.get(idxs.get(0)).setVisibility(View.INVISIBLE);
        activity.listAnswerViews.get(idxs.get(1)).setVisibility(View.INVISIBLE);

        activity.CAN_PLAY = true;
    }

    void showAudienceVote() {
        activity.playSound(R.raw.main_theme_2, true, false);
        activity.rlyVotes.setVisibility(View.VISIBLE);
        boolean audienceSure = (activity.currentQuestion < 5) || (((new Random()).nextInt(2) + 1) == 1);
        int[] vote = new int[4];
        int tmp;
        if (audienceSure) {
            vote[0] = (new Random()).nextInt(20) + 70;
            tmp = 100 - vote[0];
            vote[1] = (new Random()).nextInt(tmp) + 1;
            tmp = 100 - (vote[0] + vote[1]);
            if (tmp > 0) {
                vote[2] = (new Random()).nextInt(tmp) + 1;
                tmp = 100 - (vote[0] + vote[1] + vote[2]);
                if (tmp > 0) vote[3] = tmp;
            }

            int rightAnswer = activity.getRightAnswer();
            int idxVotes = 0;
            for (int i = 1; i <= 4; i++) {
                int idVote = activity.getResources().getIdentifier("imgVote" + i, "id", activity.getPackageName());
                ImageView imgVote = activity.findViewById(idVote);
                if (i == rightAnswer) {
                    imgVote.setTag(vote[0]);
                } else {
                    idxVotes++;
                    imgVote.setTag(vote[idxVotes]);
                }
            }
        } else {
            vote[0] = (new Random()).nextInt(20) + 20;
            tmp = (100 - vote[0]) / 3;
            vote[1] = (new Random()).nextInt(tmp) + 1;
            tmp = (100 - (vote[0] + vote[1])) / 2;
            vote[2] = (new Random()).nextInt(tmp) + 1;
            vote[3] = 100 - (vote[0] + vote[1] + vote[2]);
            activity.imgVote1.setTag(vote[0]);
            activity.imgVote2.setTag(vote[1]);
            activity.imgVote3.setTag(vote[2]);
            activity.imgVote4.setTag(vote[3]);
        }

        setVote(activity, activity.imgVote1);
        setVote(activity, activity.imgVote2);
        setVote(activity, activity.imgVote3);
        setVote(activity, activity.imgVote4);

        (new Handler()).postDelayed(() -> {
            activity.btnCloseVote.setVisibility(View.VISIBLE);
            activity.playSound(R.raw.s_32000, true, false);
            activity.startTimer(false);
            activity.CAN_PLAY = true;
            activity.showDialog("ماهي إجابتك ؟", "", 1000, 2000, R.drawable.mouth_06, true);
        }, 6000);
    }

    void callFriend() {
        final LinearLayout llyWavesR = activity.findViewById(R.id.llyWavesR);
        final LinearLayout llyWavesL = activity.findViewById(R.id.llyWavesL);
        final ImageView imgWaveR1 = activity.findViewById(R.id.imgWaveR1);
        final ImageView imgWaveR2 = activity.findViewById(R.id.imgWaveR2);
        final ImageView imgWaveR3 = activity.findViewById(R.id.imgWaveR3);
        final ImageView imgWaveL1 = activity.findViewById(R.id.imgWaveL1);
        final ImageView imgWaveL2 = activity.findViewById(R.id.imgWaveL2);
        final ImageView imgWaveL3 = activity.findViewById(R.id.imgWaveL3);

        int rnd = (new Random()).nextInt(6) + 1;
        int idImage = activity.getResources().getIdentifier("face_0" + rnd, "drawable", activity.getPackageName());
        activity.imgCallerFace.setImageResource(idImage);
        rnd = (new Random()).nextInt(3) + 1;
        idImage = activity.getResources().getIdentifier("circle_body_0" + rnd, "drawable", activity.getPackageName());
        activity.imgCallerBody.setImageResource(idImage);

        activity.playSound(R.raw.phone_friend, true, false);
        setGreyscale(activity.imgCallerBody);
        setGreyscale(activity.imgCallerFace);
        setGreyscale(activity.imgCallerMouth);
        activity.rlyCall.setVisibility(View.VISIBLE);
        llyWavesR.setVisibility(View.VISIBLE);
        llyWavesL.setVisibility(View.VISIBLE);
        imgWaveR1.setImageAlpha(0);
        imgWaveR2.setImageAlpha(0);
        imgWaveR3.setImageAlpha(0);
        imgWaveL1.setImageAlpha(0);
        imgWaveL2.setImageAlpha(0);
        imgWaveL3.setImageAlpha(0);

        new CountDownTimer(20000, 200) {
            int t = 0;

            @Override
            public void onTick(long l) {
                t++;
                switch (t) {
                    case 1:
                    case 6:
                    case 11:
                        imgWaveR1.setImageAlpha(255);
                        imgWaveL1.setImageAlpha(255);
                        imgWaveR2.setImageAlpha(0);
                        imgWaveL2.setImageAlpha(0);
                        imgWaveR3.setImageAlpha(0);
                        imgWaveL3.setImageAlpha(0);
                        break;
                    case 2:
                    case 7:
                    case 12:
                        imgWaveR1.setImageAlpha(128);
                        imgWaveL1.setImageAlpha(128);
                        imgWaveR2.setImageAlpha(255);
                        imgWaveL2.setImageAlpha(255);
                        imgWaveR3.setImageAlpha(0);
                        imgWaveL3.setImageAlpha(0);
                        break;
                    case 3:
                    case 8:
                    case 13:
                        imgWaveR1.setImageAlpha(0);
                        imgWaveL1.setImageAlpha(0);
                        imgWaveR2.setImageAlpha(128);
                        imgWaveL2.setImageAlpha(128);
                        imgWaveR3.setImageAlpha(255);
                        imgWaveL3.setImageAlpha(255);
                        break;
                    case 4:
                    case 9:
                    case 14:
                        imgWaveR1.setImageAlpha(0);
                        imgWaveL1.setImageAlpha(0);
                        imgWaveR2.setImageAlpha(0);
                        imgWaveL2.setImageAlpha(0);
                        imgWaveR3.setImageAlpha(128);
                        imgWaveL3.setImageAlpha(128);
                        break;
                    case 5:
                    case 10:
                    case 15:
                        imgWaveR1.setImageAlpha(0);
                        imgWaveL1.setImageAlpha(0);
                        imgWaveR2.setImageAlpha(0);
                        imgWaveL2.setImageAlpha(0);
                        imgWaveR3.setImageAlpha(0);
                        imgWaveL3.setImageAlpha(0);
                        break;
                    case 20:
                        llyWavesR.setVisibility(View.INVISIBLE);
                        llyWavesL.setVisibility(View.INVISIBLE);
                        setColored(activity.imgCallerBody);
                        setColored(activity.imgCallerFace);
                        setColored(activity.imgCallerMouth);
                        break;
                    case 25:
                        int rndSure = (activity.currentQuestion < 5) ? 10 : (new Random().nextInt(10) + 1);
                        String answer;
                        if (rndSure > 7) {
                            answer = "أنا متأكد أن الجواب هو " + activity.getLetter(activity.getRightAnswer());
                        } else if (rndSure > 2) {
                            int rnd = new Random().nextInt(4) + 1;
                            answer = "ممممم.. أعتقد أن الإجابة هي " + activity.getLetter(rnd);
                        } else {
                            answer = "في الحقيقة لا أعرف الإجابة";
                        }
                        activity.txtCallAnswer.setVisibility(View.VISIBLE);
                        activity.txtCallAnswer.setCharacterDelay(18);
                        activity.txtCallAnswer.animateText(answer);
                        activity.playSound(R.raw.blabla, false, false);
                        phoneTalk(3000);
                        break;
                    case 40:
                        activity.stopCurrentSound();
                        activity.txtCallAnswer.setVisibility(View.INVISIBLE);
                        break;
                    case 45:
                        setGreyscale(activity.imgCallerBody);
                        setGreyscale(activity.imgCallerFace);
                        setGreyscale(activity.imgCallerMouth);
                        break;
                    case 50:
                        this.cancel();
                        activity.rlyCall.setVisibility(View.INVISIBLE);
                        activity.playSound(R.raw.s_32000, true, false);
                        activity.startTimer(false);
                        activity.CAN_PLAY = true;
                        activity.showDialog("ماهي إجابتك ؟", "", 1000, 2000, R.drawable.mouth_06, true);
                        break;
                }
            }

            @Override
            public void onFinish() {
            }
        }.start();
    }

    static void setVote(GameActivity activity, ImageView img) {
        int vote = (Integer) img.getTag();
        LinearLayout.LayoutParams params = (LinearLayout.LayoutParams) img.getLayoutParams();
        final float scale = activity.getResources().getDisplayMetrics().density;
        int pVote = (int) (vote * scale + 0.5f);
        params.height = pVote;
        img.setLayoutParams(params);

        TranslateAnimation anim = new TranslateAnimation(0, 0, pVote, 0);
        anim.setFillAfter(true);
        anim.setDuration(5000);
        img.startAnimation(anim);
    }

    static void setGreyscale(ImageView v) {
        ColorMatrix matrix = new ColorMatrix();
        matrix.setSaturation(0);
        ColorMatrixColorFilter cf = new ColorMatrixColorFilter(matrix);
        v.setColorFilter(cf);
    }

    static void setColored(ImageView v) {
        v.setColorFilter(null);
        v.setImageAlpha(255);
    }

    private void phoneTalk(int duration) {
        activity.imgCallerMouth.setImageResource(R.drawable.smile_02);
        new CountDownTimer(duration, 100) {
            int statusMouth = 0;

            @Override
            public void onTick(long l) {
                switch (statusMouth) {
                    case 0:
                        activity.imgCallerMouth.setImageResource(R.drawable.smile_02);
                        statusMouth++;
                        break;
                    case 1:
                        activity.imgCallerMouth.setImageResource(R.drawable.smile_04);
                        statusMouth++;
                        break;
                    case 2:
                        activity.imgCallerMouth.setImageResource(R.drawable.smile_03);
                        statusMouth++;
                        break;
                    case 3:
                        activity.imgCallerMouth.setImageResource(R.drawable.smile_05);
                        statusMouth = 0;
                        break;
                }
            }

            @Override
            public void onFinish() {
                activity.imgCallerMouth.setImageResource(R.drawable.smile_01);
            }
        }.start();
    }
}
