# Auth Feature (`lib/features/auth`)

Handles username/password authentication, session token persistence, and automatic Fingerprint / Face ID biometric authentication.

## Rules & Behavior
- The app always opens on `LoginScreen` after `SplashScreen`.
- Biometrics are **only** active if the user has previously logged in (`AppPreferences.isLoggedIn() == true`).
- When active, `LoginScreen` automatically triggers the hardware biometric prompt on open without waiting for a button tap.

## Structure
- `cubit/auth_cubit.dart`: `AuthCubitMixin` login and biometric session methods.
- `services/biometric_auth_service.dart`: Hardware `local_auth` wrapper returning `BiometricResult`.
- `helpers/login_validators.dart`: Pure validation functions for username and password fields.
- `views/login_screen.dart`: Stateful coordinator screen.
- `widgets/`: Single-responsibility widgets (`login_body.dart`, `login_top_bar.dart`, `login_header.dart`, `login_text_field.dart`, `remember_me_tile.dart`, `login_submit_button.dart`, `login_biometric_button.dart`, `biometric_fallback_dialog.dart`).
