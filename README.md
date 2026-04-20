# Millionaire Flutter - Online Multiplayer Upgrade

This project keeps the original Android millionaire quiz gameplay and adds a new Flutter-powered online multiplayer layer on top of the same app.

## What was added

- Email/password authentication
- Optional Google sign-in
- Online public matchmaking
- Private rooms with room codes
- Room-based multiplayer modes: `battle`, `elimination`, `blitz`, `survival`, `series`, and `team_battle`
- Direct friend challenges and invitations
- Live synchronized multiplayer question flow using Cloud Firestore
- Player profiles, wins/losses, total score, rating, and match history
- Leaderboard screen
- Friends list and player search
- Original local/native game launch preserved through the existing method channel

## Project structure

- `lib/screens/auth` - login and auth gate
- `lib/screens/home` - lobby, leaderboard entry point
- `lib/screens/online` - friends, matchmaking, profile, live match screens
- `lib/services` - authentication, profile, matchmaking, multiplayer room logic
- `lib/repositories` - question loading and match question generation
- `lib/models` - room, invitation, profile, and question models
- `assets/questions.json` - shared question bank for the new online mode
- `firestore.rules` - starter Firestore security rules
- `firestore.indexes.json` - starter indexes for leaderboard/history/invitations

## Firebase setup

1. Create a Firebase project.
2. Add an Android app with package name:
   - `net.androidgaming.millionaire2024`
3. Replace `android/app/google-services.json` with your own Firebase config file.
4. Enable these Firebase products:
   - Authentication
   - Cloud Firestore
5. In Authentication, enable:
   - Email/Password
   - Google (optional but supported by the UI)
6. Deploy Firestore rules and indexes:
   - `firebase deploy --only firestore:rules`
   - `firebase deploy --only firestore:indexes`

## Run steps

1. Install Flutter SDK.
2. Run:
   - `flutter pub get`
3. If you use Firebase CLI or FlutterFire CLI, configure the project as needed.
4. Run the app:
   - `flutter run`

## Firestore collections used

- `users/{uid}`
- `users/{uid}/friends/{friendUid}`
- `matches/{matchId}`
- `matchmaking_queue/{uid}`
- `invitations/{invitationId}`
- `rooms/{roomId}`

## Multiplayer behavior

### Public matchmaking
- A player enters the public queue.
- The service looks for another waiting player.
- When found, a match room is created and both players join the same room.

### Private matches and play with friends
- A host creates a room.
- The room gets a 6-character code.
- Players join by code or invitation until the room is full, or the host starts early.
- Missing seats can be filled with bots when the room starts.

### Room modes
- `battle`: standard score race.
- `elimination`: round-based knockout flow.
- `blitz`: timed score race.
- `survival`: each player starts with 3 lives, correct answers give +1 score, wrong answers remove 1 life, and eliminated players stay out.
- `series`: best-of-N round flow.
- `team_battle`: team-vs-team score aggregation.

### Survival room flow
- Phase order: `lobby` -> `playing_round` -> `round_over` -> `finished`
- Only the host can start the room and start the next Survival round.
- At room start, all players and filled bots get 3 lives.
- A player can answer once per round.
- Eliminated players cannot answer and are not revived.
- Lives persist across rounds; only per-round fields are reset for alive players.
- If more than one player is still alive after a round, the room moves to `round_over`.
- If only one player remains alive, that player becomes `winnerId` and the room moves to `finished`.

### Real-time sync
The room document stores:
- room mode and phase
- host ID and max players
- round metadata such as `roundNumber`
- optional `questionIds` for round-based modes
- per-player room state: `score`, `ready`, `answeredCount`, `completedAt`, `currentAnswer`, `lives`, `eliminated`, `roundWins`, and `teamId`
- `winnerId` / `winnerTeamId`

## Important notes

- The original native Android millionaire game is still launched from Flutter using the existing `millionaire/native` method channel.
- The new online mode is implemented in Flutter to avoid breaking the original gameplay codebase.
- Open public matchmaking still behaves like a lightweight direct match flow, while room mode supports more than two players.
- Survival bots use the same room-state rules as human players and can lose lives or be eliminated.
- If you want stronger anti-cheat guarantees later, move score validation and round progression into Firebase Cloud Functions.

## Known limitations

- The room layer keeps multiplayer room state in Cloud Firestore, while the existing native gameplay layer still uses its legacy bridge/data flow.
- There is no Cloud Functions authority layer yet, so room validation still runs on the client.

## Recommended next improvements

- Add presence and online/offline indicators
- Add push notifications for invitations
- Add rematch flow
- Add chat/emotes in room
- Move matchmaking and answer validation to Cloud Functions
