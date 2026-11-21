# L.M.T – The Last Message Team (فريق الرسالة الاخيرة)

Flutter app for team posts, chat, shared files, calendar with reminders, daily Khelwa tracking and member management.

## Docs
- [Architecture](docs/ARCHITECTURE.md)
- [Coding Guidelines](docs/CODING_GUIDELINES.md)
- [UI / UX Guidelines](docs/UI_UX_GUIDELINES.md)
- Each feature folder has its own `README.md` (`lib/features/<feature>/README.md`), and `lib/core/README.md` covers shared code.

## Run
```
flutter pub get
flutter analyze        # must report 0 issues
flutter run -d <device>
```
Native Android changes (`MainActivity.kt`, `AndroidManifest.xml`) require `flutter build apk --debug` + install.

## Demo accounts
`admin`, `editor`, `member` (password `password123`).
