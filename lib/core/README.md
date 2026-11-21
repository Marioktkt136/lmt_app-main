# Core Layer (`lib/core`)

Shared, feature-agnostic infrastructure, domain models, repository contracts, native services, theme tokens, and global widgets.

## Structure
- `cubit/`: `LmtState` (`lmt_state.dart`) and `LmtCubit` composition root (`lmt_cubit.dart`).
- `data/`: `LmtSeedData` facade (`lmt_seed_data.dart`) and modular entity seed files (`seed/`).
- `di/`: `get_it` service locator (`injection_container.dart`).
- `models/`: Domain models (`user_role.dart`, `member_model.dart`, `chat_models.dart`, `post_models.dart`, `shared_file_model.dart`, `calendar_event_model.dart`, `notification_model.dart`, barrel `lmt_models.dart`).
- `repositories/`: `LmtRepository` interface & `LmtLocalRepositoryImpl` (`lmt_repository.dart`).
- `routes/`: Route constants (`routes.dart`) and animated `AppRouter` (`app_router.dart`).
- `services/`: `LocalNotificationService` (exact alarm reminders) and `NativeMediaService` (Android MethodChannel bridge for mic permission, voice recording/playback, native file picker, and public `Download/LMT` saving).
- `theme/`: `AppColors` (WCAG AA Light/Dark palette & shadow tokens), `AppTypography`, and `AppTheme`.
- `utils/`: `AppPreferences`, `DeviceFileHelper` facade + `device_files/` modules, `AppAssets`, `AppConstants`, `Validators`, and `Extensions`.
- `widgets/`: Global reusable UI components (`LmtCard`, `LmtAvatar`, `LmtSearchBar`, `LmtEmptyState`, `CustomAppBar`, `BottomNavBar`, `HeaderBanner`).
