ExpenseMate MVP (Flutter) — Drop-in `lib/` folder
=================================================

This zip contains a working Splitwise-style MVP using:
- go_router (routing)
- flutter_riverpod (state management)
- In-memory repositories (no backend required)

CONTENTS
--------
- lib/
  - main.dart
  - app/router.dart
  - app/theme.dart
  - features/groups/… (domain, data, UI)
  - features/expenses/… (domain, data, UI)
  - shared/providers/repositories.dart
- pubspec_dependencies.txt (what to add to pubspec.yaml)

HOW TO USE
----------
1) Create (or open) a Flutter project:
   flutter create ExpenseMate
   cd ExpenseMate

2) Replace your project's `lib/` with the `lib/` from this zip.
   (Back up your original lib/ if needed.)

3) Update `pubspec.yaml` dependencies:
   Add at least:
     go_router: ^14.2.6
     flutter_riverpod: ^2.5.1

   Then run:
     flutter pub get

4) Run the app:
   flutter run

5) Try it:
   - Create a group, add members
   - Open the group, add expenses (equal split)
   - Balances show who owes/is owed

NOTES
-----
- This MVP stores data in memory; app restart clears data.
- You can later swap repositories to Firestore or your Spring Boot API.
- No code generation or build_runner is required.

Need help wiring to Firestore or your backend next? Ping me.
