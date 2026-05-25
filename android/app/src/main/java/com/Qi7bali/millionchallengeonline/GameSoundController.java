package net.androidgaming.millionaire2024;

import android.content.Context;
import android.media.MediaPlayer;
import android.os.Handler;

final class GameSoundController {
    private final Context context;
    private MediaPlayer currentPlayer;
    private boolean currentPlayerIsMusic;

    GameSoundController(Context context) {
        this.context = context.getApplicationContext();
    }

    void play(int resId, boolean fading, boolean looping, boolean exiting) {
        if (exiting) return;

        boolean targetIsMusic = isMusicTrack(resId, looping);
        if (targetIsMusic) {
            if (!AppPrefs.isMusicEnabled(context)) {
                stopCurrent();
                return;
            }
        } else if (!AppPrefs.isSoundEnabled(context)) {
            return;
        }

        if (fading) {
            if (currentPlayer != null) {
                fadeCurrent();
            }
        } else {
            stopCurrent();
        }

        currentPlayer = MediaPlayer.create(context, resId);
        if (currentPlayer == null) return;
        currentPlayerIsMusic = targetIsMusic;
        currentPlayer.setLooping(looping);
        currentPlayer.start();
    }

    void setCurrentEffectVolume(float volume) {
        if (currentPlayer != null && !currentPlayerIsMusic) {
            currentPlayer.setVolume(volume, volume);
        }
    }

    void stopCurrentMusicIfDisabled(boolean musicEnabled) {
        if (currentPlayer != null && currentPlayerIsMusic && !musicEnabled) {
            stopCurrent();
        }
    }

    void stopCurrent() {
        MediaPlayer player = currentPlayer;
        currentPlayer = null;
        currentPlayerIsMusic = false;
        release(player);
    }

    void releaseCurrent() {
        stopCurrent();
    }

    static void release(MediaPlayer player) {
        if (player == null) return;
        try {
            if (player.isPlaying()) {
                player.stop();
            }
        } catch (Exception ignored) {
        }
        try {
            player.release();
        } catch (Exception ignored) {
        }
    }

    private boolean isMusicTrack(int resId, boolean looping) {
        return looping
                || resId == R.raw.main_theme_0
                || resId == R.raw.main_theme_1
                || resId == R.raw.main_theme_2
                || resId == R.raw.main_theme_3
                || resId == R.raw.main_theme_4
                || resId == R.raw.main_theme_5
                || resId == R.raw.commerical_break
                || resId == R.raw.s_32000
                || resId == R.raw.s_64000
                || resId == R.raw.s_250000
                || resId == R.raw.s_5000000
                || resId == R.raw.s_1000000;
    }

    private void fadeCurrent() {
        final MediaPlayer player = currentPlayer;
        currentPlayer = null;
        currentPlayerIsMusic = false;
        if (player == null) return;

        final Handler handler = new Handler();
        handler.postDelayed(new Runnable() {
            int currentVolumeStep = 10;

            @Override
            public void run() {
                try {
                    currentVolumeStep--;
                    float currentVolume = (float) (1 - (Math.log(10 - currentVolumeStep) / Math.log(10)));
                    player.setVolume(currentVolume, currentVolume);
                    if (currentVolumeStep > 0) {
                        handler.postDelayed(this, 100);
                    } else {
                        release(player);
                    }
                } catch (Exception ignored) {
                    release(player);
                }
            }
        }, 100);
    }
}
