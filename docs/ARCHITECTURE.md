# L.M.T Architecture Guide

Feature-first Clean Architecture for "The Last Message Team" app.

## Layers

```
lib/
├── main.dart                 App bootstrap (DI, theme, localization)
├── core/                     Shared, feature-agnostic code
│   ├── api/ network/ errors/ usecases/   Infrastructure contracts
│   ├── config/ routes/ di/               App wiring
│   ├── cubit/                            LmtState + LmtBaseCubit + LmtCubit (composition root)
│   ├── data/                             Seed data (one file per entity)
│   ├── models/                           Domain models (one model per file)
│   ├── repositories/                     LmtRepository (abstraction) + local impl
│   ├── services/                         Native bridges & notifications
│   ├── theme/                            Colors, typography, ThemeData
│   ├── utils/                            Helpers, validators, extensions
│   └── widgets/                          Global reusable widgets
└── features/<feature>/
    ├── cubit/                Feature business logic (mixin on LmtBaseCubit)
    ├── views/                Screens: compose widgets only, no business logic
    ├── widgets/              Feature widgets (one public widget per file)
    ├── sheets|dialogs/       Bottom sheets and dialogs
    └── README.md             Feature-specific notes
```

## Dependency rule
`views → widgets → cubit → repository → data source`. Inner layers never import outer layers.
Features never import other features' `widgets/`; share via `core/widgets`.

## State management
- `LmtState` is immutable (Equatable). Change it only through `emit(state.copyWith(...))` in a Cubit.
- Each feature owns a `<Feature>CubitMixin on LmtBaseCubit`; `LmtCubit` composes them.
- Persist after every mutation with `persistState()`; notify users with `pushNotification()`.

## Adding a feature
1. Create `lib/features/<name>/{cubit,views,widgets}`.
2. Write `<Name>CubitMixin on LmtBaseCubit` and add it to `LmtCubit`.
3. Add the route in `core/routes/routes.dart` and `app_router.dart`.
4. Add strings to `assets/lang/ar.json` and `en.json`.
5. Document it in the feature `README.md`.

## Native bridge
`core/services/native_media_service.dart` wraps channel `com.example.lmt/native_media`
(mic permission, voice record/play, file picker, public Downloads). Kotlin side: `MainActivity.kt`.
After changing Kotlin/Manifest you must rebuild the APK (hot restart is not enough).
