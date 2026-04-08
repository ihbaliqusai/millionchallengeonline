package com.Qi7bali.millionchallengeonline;

import android.os.CountDownTimer;
import android.os.Handler;
import android.view.View;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.view.animation.RotateAnimation;
import android.view.animation.TranslateAnimation;
import android.widget.ImageView;
import android.widget.RelativeLayout;

import java.util.ArrayList;

public class Person {
    private RelativeLayout rlyPerson, rlyHead;
    private ImageView imgBody, imgHead, imgMouth, imgClosedEyes, imgEyeBrowsUpRight, imgEyeBrowsUpLeft, imgLookAside;

    public Person(RelativeLayout rlyPerson) {
        this.rlyPerson = rlyPerson;
        imgBody = (ImageView) rlyPerson.getChildAt(0);
        rlyHead = (RelativeLayout) rlyPerson.getChildAt(1);
        imgHead = (ImageView) rlyHead.getChildAt(0);
        imgMouth = (ImageView) rlyHead.getChildAt(1);
        imgLookAside = (ImageView) rlyHead.getChildAt(2);
        imgClosedEyes = (ImageView) rlyHead.getChildAt(3);
        imgEyeBrowsUpRight = (ImageView) rlyHead.getChildAt(4);
        imgEyeBrowsUpLeft = (ImageView) rlyHead.getChildAt(5);

    }

    public void closeEyes(int duration) {
        Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                imgClosedEyes.setVisibility(View.INVISIBLE);
            }
        };
        imgClosedEyes.setVisibility(View.VISIBLE);
        handler.postDelayed(runnable, duration);
    }

    public void raiseEyeBrowsUp(int duration, final boolean right, final boolean left) {
        Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                if(right) imgEyeBrowsUpRight.setVisibility(View.INVISIBLE);
                if(left) imgEyeBrowsUpLeft.setVisibility(View.INVISIBLE);
            }
        };
        if(right) imgEyeBrowsUpRight.setVisibility(View.VISIBLE);
        if(left) imgEyeBrowsUpLeft.setVisibility(View.VISIBLE);
        handler.postDelayed(runnable, duration);
    }

    public void lookAside(int duration) {
        Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                imgLookAside.setVisibility(View.INVISIBLE);
            }
        };
        imgLookAside.setVisibility(View.VISIBLE);
        handler.postDelayed(runnable, duration);
    }

    public void bend(int duration, int bodyResId) {
        Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            @Override
            public void run() {
                Animations.bendPerson(rlyPerson, false);
                imgBody.setImageResource(R.drawable.person_02);
            }
        };
        imgBody.setImageResource(bodyResId);
        Animations.bendPerson(rlyPerson, true);
        handler.postDelayed(runnable, duration);
    }

    public void talk(int duration, final int mouthAfter) {
        imgMouth.setImageResource(R.drawable.mouth_01);
        CountDownTimer cdt = new CountDownTimer(duration, 100) {
            int status_mouth = 0;
            @Override
            public void onTick(long l) {
                switch (status_mouth) {
                    case 0:
                        imgMouth.setImageResource(R.drawable.mouth_02);
                        status_mouth++;
                        break;
                    case 1:
                        imgMouth.setImageResource(R.drawable.mouth_03);
                        status_mouth++;
                        break;
                    case 2:
                        imgMouth.setImageResource(R.drawable.mouth_01);
                        status_mouth = 0;
                        break;
                }
            }

            @Override
            public void onFinish() {
                imgMouth.setImageResource(mouthAfter);
            }
        }.start();
    }

    public void blinkEyes(final int times) {
        final Handler handler = new Handler();
        final Runnable runnable = new Runnable() {
            int t = 0;
            boolean opened = true;
            @Override
            public void run() {
                if(opened) {
                    opened=false;
                    t++;
                    imgClosedEyes.setVisibility(View.VISIBLE);
                    handler.postDelayed(this, 50);
                } else {
                    opened=true;
                    imgClosedEyes.setVisibility(View.INVISIBLE);
                    if(t<times) handler.postDelayed(this, 300);
                }
            }
        };
        handler.postDelayed(runnable, 1);
    }

    private void moveEyebrows(final int times) {
        final Handler handler = new Handler();
        final Runnable runnable = new Runnable() {
            int t = 0;
            boolean normal = true;
            @Override
            public void run() {
                if(normal) {
                    normal=false;
                    t++;
                    imgEyeBrowsUpRight.setVisibility(View.VISIBLE);
                    imgEyeBrowsUpLeft.setVisibility(View.VISIBLE);
                    handler.postDelayed(this, 50);
                } else {
                    normal=true;
                    imgEyeBrowsUpRight.setVisibility(View.INVISIBLE);
                    imgEyeBrowsUpLeft.setVisibility(View.INVISIBLE);
                    if(t<times) handler.postDelayed(this, 100);
                }
            }
        };
        handler.postDelayed(runnable, 1);
    }

    public void moveBody(final ArrayList<Integer[]> sequence) {
        final Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            int i = 0;
            @Override
            public void run() {
                i++;
                if(i<sequence.size()) {
                    imgBody.setImageResource(sequence.get(i)[0]);
                    handler.postDelayed(this, sequence.get(i)[1]);
                } else {
                    sequence.clear();
                }
            }
        };
        imgBody.setImageResource(sequence.get(0)[0]);
        handler.postDelayed(runnable, sequence.get(0)[1]);
    }

    public void like(int duration) {
        ArrayList<Integer[]> sequence = new ArrayList<>();
        sequence.add(new Integer[]{R.drawable.person_02, 40});
        sequence.add(new Integer[]{R.drawable.person_03, 40});
        sequence.add(new Integer[]{R.drawable.person_10, duration});
        sequence.add(new Integer[]{R.drawable.person_03, 40});
        sequence.add(new Integer[]{R.drawable.person_02, 40});
        moveBody(sequence);
    }

    public void raiseShoulders() {
        AnimationSet animSet = new AnimationSet(false);
        TranslateAnimation anim;
        anim = new TranslateAnimation(0,0,0,-10);
        anim.setDuration(100);
        anim.setFillAfter(true);
        animSet.addAnimation(anim);
        anim = new TranslateAnimation(0,0,0,10);
        anim.setDuration(100);
        anim.setFillAfter(true);
        anim.setStartOffset(600);
        animSet.addAnimation(anim);
        imgBody.startAnimation(animSet);
    }

    private void animShow(int duration) {
        AnimationSet animSet = new AnimationSet(false);
        TranslateAnimation animTranslate;
        RotateAnimation animRotate;
        animTranslate = new TranslateAnimation(0,0,0,-10);
        animTranslate.setDuration(100);
        animTranslate.setFillAfter(true);
        animSet.addAnimation(animTranslate);
        animRotate = new RotateAnimation(0, -3, Animation.RELATIVE_TO_SELF, 0.8f, Animation.RELATIVE_TO_SELF, 1.0f);
        animRotate.setDuration(100);
        animRotate.setFillAfter(true);
        animRotate.setStartOffset(80+(duration/4));
        animSet.addAnimation(animRotate);
        animRotate = new RotateAnimation(-3, 0, Animation.RELATIVE_TO_SELF, 0.8f, Animation.RELATIVE_TO_SELF, 1.0f);
        animRotate.setDuration(100);
        animRotate.setFillAfter(true);
        animRotate.setStartOffset(80+duration);
        animSet.addAnimation(animRotate);
        animTranslate = new TranslateAnimation(0,0,0,10);
        animTranslate.setDuration(100);
        animTranslate.setFillAfter(true);
        animTranslate.setStartOffset(80+duration);
        animSet.addAnimation(animTranslate);
        rlyPerson.startAnimation(animSet);
    }

    public void moveShowHand(int duration) {
        ArrayList<Integer[]> sequence = new ArrayList<>();
        sequence.add(new Integer[]{R.drawable.person_02, 20});
        sequence.add(new Integer[]{R.drawable.person_03, 20});
        sequence.add(new Integer[]{R.drawable.person_04, 20});
        sequence.add(new Integer[]{R.drawable.person_05, 20});
        sequence.add(new Integer[]{R.drawable.person_06, duration});
        sequence.add(new Integer[]{R.drawable.person_05, 20});
        sequence.add(new Integer[]{R.drawable.person_04, 20});
        sequence.add(new Integer[]{R.drawable.person_03, 20});
        sequence.add(new Integer[]{R.drawable.person_02, 20});
        moveBody(sequence);
        animShow(duration);
    }

    public void moveShowHandGrip(int duration) {
        ArrayList<Integer[]> sequence = new ArrayList<>();
        sequence.add(new Integer[]{R.drawable.person_02, 20});
        sequence.add(new Integer[]{R.drawable.person_03, 20});
        sequence.add(new Integer[]{R.drawable.person_04, 20});
        sequence.add(new Integer[]{R.drawable.person_05, 20});
        sequence.add(new Integer[]{R.drawable.person_09, duration});
        sequence.add(new Integer[]{R.drawable.person_05, 20});
        sequence.add(new Integer[]{R.drawable.person_04, 20});
        sequence.add(new Integer[]{R.drawable.person_03, 20});
        sequence.add(new Integer[]{R.drawable.person_02, 20});
        moveBody(sequence);
        animShow(duration);
    }

    public void moveShowScreen(int duration) {
        ArrayList<Integer[]> sequence = new ArrayList<>();
        sequence.add(new Integer[]{R.drawable.person_02, 20});
        sequence.add(new Integer[]{R.drawable.person_03, 20});
        sequence.add(new Integer[]{R.drawable.person_04, 20});
        sequence.add(new Integer[]{R.drawable.person_05, 20});
        sequence.add(new Integer[]{R.drawable.person_06, 20});
        sequence.add(new Integer[]{R.drawable.person_07, duration});
        sequence.add(new Integer[]{R.drawable.person_06, 20});
        sequence.add(new Integer[]{R.drawable.person_05, 20});
        sequence.add(new Integer[]{R.drawable.person_04, 20});
        sequence.add(new Integer[]{R.drawable.person_03, 20});
        sequence.add(new Integer[]{R.drawable.person_02, 20});
        moveBody(sequence);
        animShow(duration);
    }

    public void moveShow2Hands(int duration) {
        ArrayList<Integer[]> sequence = new ArrayList<>();
        sequence.add(new Integer[]{R.drawable.person_02, 10});
        sequence.add(new Integer[]{R.drawable.person_03, 10});
        sequence.add(new Integer[]{R.drawable.person_04, 10});
        sequence.add(new Integer[]{R.drawable.person_05, 10});
        sequence.add(new Integer[]{R.drawable.person_06, 10});
        sequence.add(new Integer[]{R.drawable.person_08, duration});
        sequence.add(new Integer[]{R.drawable.person_06, 10});
        sequence.add(new Integer[]{R.drawable.person_05, 10});
        sequence.add(new Integer[]{R.drawable.person_04, 10});
        sequence.add(new Integer[]{R.drawable.person_03, 10});
        sequence.add(new Integer[]{R.drawable.person_02, 10});
        moveBody(sequence);
        animShow(duration);
    }

    public void moveHead(int duration) {
        AnimationSet animSet = new AnimationSet(false);
        RotateAnimation animRotate;
        animRotate = new RotateAnimation(0, -2, Animation.RELATIVE_TO_SELF, 0.8f, Animation.RELATIVE_TO_SELF, 1.0f);
        animRotate.setDuration(100);
        animRotate.setFillAfter(true);
        animSet.addAnimation(animRotate);
        animRotate = new RotateAnimation(-2, 0, Animation.RELATIVE_TO_SELF, 0.8f, Animation.RELATIVE_TO_SELF, 1.0f);
        animRotate.setDuration(100);
        animRotate.setFillAfter(true);
        animRotate.setStartOffset(100+duration);
        animSet.addAnimation(animRotate);
        rlyHead.startAnimation(animSet);
    }

    public void sad() {
        imgMouth.setVisibility(View.INVISIBLE);
        imgEyeBrowsUpLeft.setVisibility(View.INVISIBLE);
        imgEyeBrowsUpRight.setVisibility(View.INVISIBLE);
        imgLookAside.setVisibility(View.INVISIBLE);
        imgClosedEyes.setVisibility(View.INVISIBLE);
        final Handler handler = new Handler();
        Runnable runnable = new Runnable() {
            int t = 0;
            @Override
            public void run() {
                t++;
                switch (t) {
                    case 1:
                        imgHead.setImageResource(R.drawable.sad_01);
                        handler.postDelayed(this,50);
                        break;
                    case 5:
                    case 9:
                        imgHead.setImageResource(R.drawable.sad_01);
                        handler.postDelayed(this,100);
                        break;
                    case 2:
                    case 4:
                    case 6:
                    case 8:
                        imgHead.setImageResource(R.drawable.sad_02);
                        handler.postDelayed(this,50);
                        break;
                    case 3:
                    case 7:
                        imgHead.setImageResource(R.drawable.sad_03);
                        handler.postDelayed(this,100);
                        break;
                    case 10:
                        imgHead.setImageResource(R.drawable.head);
                        imgMouth.setVisibility(View.VISIBLE);
                        imgMouth.setImageResource(R.drawable.mouth_05);
                }
            }
        };
        handler.postDelayed(runnable,10);
    }

}
