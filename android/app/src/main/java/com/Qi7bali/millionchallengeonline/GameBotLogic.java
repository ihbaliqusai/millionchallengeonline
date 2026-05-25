package net.androidgaming.millionaire2024;

import java.util.Random;

final class GameBotLogic {
    private GameBotLogic() {
    }

    static BotProfile resolveBotProfile(String playerId) {
        if (playerId != null) {
            String[] parts = playerId.split("_");
            if (parts.length >= 1) {
                try {
                    int slot = Integer.parseInt(parts[parts.length - 1]) - 1;
                    if (slot >= 0 && slot < BotProfiles.PROFILES.length) {
                        return BotProfiles.PROFILES[slot];
                    }
                } catch (NumberFormatException ignored) {
                }
            }
        }
        int seed = Math.abs(stableHash(playerId));
        return BotProfiles.PROFILES[seed % BotProfiles.PROFILES.length];
    }

    static void applyBotIdentity(MatchOpponent opponent) {
        if (opponent == null) {
            return;
        }
        BotProfile profile = resolveBotProfile(opponent.id);
        opponent.bot = true;
        opponent.name = profile.name;
        opponent.photo = profile.photo;
        opponent.intelligence = profile.intelligence;
        opponent.level = Math.max(1, opponent.intelligence / 10);
    }

    static int getFictitiousRandomTime(String level) {
        int res = 5;
        switch (level) {
            case "0":
                res = (new Random()).nextInt(3) + 1;
                break;
            case "1":
                res = (new Random()).nextInt(3) + 4;
                break;
            case "2":
                res = (new Random()).nextInt(6) + 7;
                break;
            case "3":
                res = (new Random()).nextInt(8) + 13;
                break;
        }
        return 30 - res;
    }

    static int getFictitiousRandomAnswer(String level, int rightAnswer) {
        int x = (new Random()).nextInt(10) + 1;
        switch (level) {
            case "0":
                return rightAnswer;
            case "1":
                return x < 9 ? rightAnswer : getWrongAnswer(rightAnswer);
            case "2":
                return x < 6 ? rightAnswer : getWrongAnswer(rightAnswer);
            case "3":
                return x < 4 ? rightAnswer : getWrongAnswer(rightAnswer);
            default:
                return 1;
        }
    }

    static int getBotDelayMillis(MatchOpponent opponent, int currentQuestion, String level, int progressValue) {
        int intel = opponent.intelligence;
        int baseMs;
        if (currentQuestion < 5) {
            baseMs = 4835 + (100 - intel) * 93;
        } else if (currentQuestion < 10) {
            baseMs = 7110 + (100 - intel) * 138;
        } else {
            baseMs = 7835 + (100 - intel) * 293;
        }

        switch (level) {
            case "1": baseMs += 400; break;
            case "2": baseMs += 1000; break;
            case "3": baseMs += 2200; break;
        }

        int seed = Math.abs(stableHash(opponent.id + "|q" + currentQuestion));
        baseMs += (seed % 600) - 300;
        baseMs += new Random().nextInt(700) - 350;
        if (new Random().nextInt(100) < 8) {
            baseMs += 1000 + new Random().nextInt(2000);
        }
        baseMs = Math.max(900, baseMs);

        int remainingMs = Math.max(1500, ((progressValue / 10) - 3) * 1000);
        return Math.min(remainingMs, baseMs);
    }

    static int getBotDisplayedAnswer(MatchOpponent opponent, int currentQuestion, String level, int rightAnswer) {
        int levelPenalty;
        switch (level) {
            case "1": levelPenalty = 8; break;
            case "2": levelPenalty = 18; break;
            case "3": levelPenalty = 26; break;
            case "4": levelPenalty = 32; break;
            case "5": levelPenalty = 38; break;
            case "6": levelPenalty = 44; break;
            case "7": levelPenalty = 50; break;
            case "8": levelPenalty = 56; break;
            default: levelPenalty = 0; break;
        }
        int successChance = Math.max(20, Math.min(97, opponent.intelligence - levelPenalty));
        int stablePart = Math.abs(stableHash(opponent.id + "|" + currentQuestion)) % 80;
        int randomPart = new Random().nextInt(20);
        int roll = (stablePart + randomPart) % 100;
        return roll < successChance ? rightAnswer : getWrongAnswer(rightAnswer);
    }

    static int getWrongAnswer(int rightAnswer) {
        int res;
        do {
            res = (new Random()).nextInt(4) + 1;
        } while (res == rightAnswer);
        return res;
    }

    private static int stableHash(String value) {
        if (value == null) {
            return 0;
        }
        int hash = 1125899907;
        for (int i = 0; i < value.length(); i++) {
            hash = 31 * hash + value.charAt(i);
        }
        return hash;
    }
}
