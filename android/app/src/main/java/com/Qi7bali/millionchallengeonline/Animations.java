package com.Qi7bali.millionchallengeonline;

import android.view.View;
import android.view.animation.AccelerateInterpolator;
import android.view.animation.AlphaAnimation;
import android.view.animation.Animation;
import android.view.animation.AnimationSet;
import android.view.animation.DecelerateInterpolator;
import android.view.animation.RotateAnimation;
import android.view.animation.ScaleAnimation;
import android.view.animation.TranslateAnimation;
import android.widget.FrameLayout;
import android.widget.LinearLayout;
import android.widget.RelativeLayout;

public class Animations {

    public static void zoom(View view, int duration, float scateTo) {
        ScaleAnimation anim = new ScaleAnimation(1, scateTo, 1, scateTo);
        anim.setDuration(duration);
        anim.setFillAfter(true);
        view.startAnimation(anim);
    }

    public static void dialogZoom(View view, int number, int duration, float toScale) {
        AnimationSet animSet = new AnimationSet(false);
        ScaleAnimation anim;
        float startXY = toScale, endXY = 1 / startXY, toXY;
        int startOffset = 0;
        boolean normal = true;

        for (int i=1; i<=number; i++) {
            if(normal) {
                toXY = startXY;
            } else {
                toXY = endXY;
            }
            normal = !normal;
            anim = new ScaleAnimation(1.0f,toXY, 1.0f, toXY, 0.5f, 0.5f);
            anim.setDuration(duration);
            anim.setStartOffset(startOffset);
            startOffset += duration;
            animSet.addAnimation(anim);
        }
        view.startAnimation(animSet);
    }

    public static void progressZoomIn(View view) {
        view.setVisibility(View.VISIBLE);
        ScaleAnimation anim = new ScaleAnimation(0f, 1f, 0f, 1f, 50f, 50f);
        anim.setDuration(500);
        anim.setFillAfter(true);
        view.startAnimation(anim);
    }

    public static void progressZoomOut(View view) {
        ScaleAnimation anim = new ScaleAnimation(1f, 0f, 1f, 0f, 50f, 50f);
        anim.setDuration(200);
        anim.setFillAfter(true);
        view.startAnimation(anim);
    }

    public static void move(View view, int duration, float fromX, float toX, float fromY, float toY) {
        TranslateAnimation anim;
        anim = new TranslateAnimation(fromX, toX, fromY, toY);
        anim.setDuration(duration);
        anim.setFillAfter(true);
        view.startAnimation(anim);
    }

    public static void movePlayer(final View view, final int distanceToLeft, final int distanceToDown, final int duration) {
        AnimationSet animationSet = new AnimationSet(false);
        TranslateAnimation animMove = new TranslateAnimation(0, -distanceToLeft, 0, distanceToDown);
        ScaleAnimation animZoom = new ScaleAnimation(1f, 0.5f, 1f, 0.5f, 50f, 50f);
        animationSet.addAnimation(animMove);
        animationSet.addAnimation(animZoom);
        animationSet.setDuration(duration);
        animationSet.setFillAfter(true);
        view.startAnimation(animationSet);
    }

    public static void rotate(View view, int duration, int from, int to, float xPivot, float yPivot) {
        RotateAnimation anim = new RotateAnimation(from, to, Animation.RELATIVE_TO_SELF, xPivot, Animation.RELATIVE_TO_SELF, yPivot);
        anim.setDuration(duration);
        anim.setFillAfter(true);
        view.startAnimation(anim);
    }

    public static void rotateLight(View view, float fromDegree, float toDegree, int duration) {
        RotateAnimation anim;
        anim = new RotateAnimation(fromDegree, toDegree, 50f, 10f);
        anim.setDuration(duration);
        anim.setFillAfter(true);
        view.startAnimation(anim);
    }

    public static void movePerson(View view, boolean toLeft) {
        AnimationSet animSet = new AnimationSet(false);

        RotateAnimation rotateAnimation;
        TranslateAnimation translateAnimation;

        if(toLeft) {
            rotateAnimation = new RotateAnimation(0, -3, Animation.RELATIVE_TO_SELF, 0.8f, Animation.RELATIVE_TO_SELF, 1.0f);
            translateAnimation = new TranslateAnimation(0, -3, 0, 0);
        } else {
            rotateAnimation = new RotateAnimation(-3, 0, Animation.RELATIVE_TO_SELF, 0.8f, Animation.RELATIVE_TO_SELF, 1.0f);
            translateAnimation = new TranslateAnimation(0, 3, 0, 0);
        }

        rotateAnimation.setDuration(200);
        rotateAnimation.setFillAfter(true);
        animSet.addAnimation(rotateAnimation);

        translateAnimation.setDuration(200);
        translateAnimation.setFillAfter(true);
        animSet.addAnimation(translateAnimation);

        animSet.setFillAfter(true);

        view.startAnimation(animSet);
    }

    public static void bendPerson(View view, boolean toLeft) {
        AnimationSet animSet = new AnimationSet(false);

        RotateAnimation rotateAnimation;
        TranslateAnimation translateAnimation;
        ScaleAnimation scaleAnimation;

        if(toLeft) {
            rotateAnimation = new RotateAnimation(0, -2, Animation.RELATIVE_TO_SELF, 0.8f, Animation.RELATIVE_TO_SELF, 1.0f);
            translateAnimation = new TranslateAnimation(0, -3, 0, 0);
            scaleAnimation = new ScaleAnimation(1, 1.04f, 1, 1.05f);
        } else {
            rotateAnimation = new RotateAnimation(-2, 0, Animation.RELATIVE_TO_SELF, 0.8f, Animation.RELATIVE_TO_SELF, 1.0f);
            translateAnimation = new TranslateAnimation(0, 3, 0, 0);
            scaleAnimation = new ScaleAnimation(1.04f, 1, 1.05f, 1);
        }


        animSet.addAnimation(rotateAnimation);
        animSet.addAnimation(translateAnimation);
        animSet.addAnimation(scaleAnimation);

        animSet.setDuration(100);
        animSet.setFillAfter(true);

        view.startAnimation(animSet);
    }

    public static void fadeShadow(View view) {
        AlphaAnimation anim;
        AnimationSet animSet = new AnimationSet(false);
        anim = new AlphaAnimation(0, 1);
        anim.setInterpolator(new DecelerateInterpolator());
        anim.setDuration(250);
        animSet.addAnimation(anim);
        anim = new AlphaAnimation(1, 0);
        anim.setInterpolator(new AccelerateInterpolator());
        anim.setDuration(250);
        anim.setStartOffset(250);
        animSet.addAnimation(anim);
        view.startAnimation(animSet);
    }

    public static void animOpponent(View view, int duration, int margin) {
        TranslateAnimation animation = new TranslateAnimation(0, 0, -1 * margin, margin);
        animation.setDuration(duration);
        animation.setFillAfter(true);
        view.startAnimation(animation);
    }


}

