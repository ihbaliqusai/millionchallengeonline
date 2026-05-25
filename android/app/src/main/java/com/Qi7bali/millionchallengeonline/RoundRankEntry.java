package net.androidgaming.millionaire2024;

final class RoundRankEntry {
    final String playerId;
    final long elapsedMs;

    RoundRankEntry(String playerId, long elapsedMs) {
        this.playerId = playerId;
        this.elapsedMs = elapsedMs;
    }
}
