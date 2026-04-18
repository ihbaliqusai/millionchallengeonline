# Millionaire Flutter - Online Multiplayer Upgrade

This project keeps the original Android millionaire quiz gameplay and adds a new Flutter-powered online multiplayer layer on top of the same app.

## What was added

- Email/password authentication
- Optional Google sign-in
- Online public matchmaking
- Private rooms with room codes
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

## Multiplayer behavior

### Public matchmaking
- A player enters the public queue.
- The service looks for another waiting player.
- When found, a match room is created and both players join the same room.

### Private matches and play with friends
- A host creates a room.
- The room gets a 6-character code.
- The second player joins by code or invitation.
- Once two players are present, the match starts automatically.

### Real-time sync
The match document stores:
- room status
- current question index
- synchronized question payload
- per-player selected answer
- answer timing and score
- winner and finalized state

## Important notes

- The original native Android millionaire game is still launched from Flutter using the existing `millionaire/native` method channel.
- The new online mode is implemented in Flutter to avoid breaking the original gameplay codebase.
- The current implementation is designed for 1v1 live matches.
- If you want stronger anti-cheat guarantees later, move score validation and round progression into Firebase Cloud Functions.

## Recommended next improvements

- Add presence and online/offline indicators
- Add push notifications for invitations
- Add rematch flow
- Add chat/emotes in room
- Move matchmaking and answer validation to Cloud Functions
