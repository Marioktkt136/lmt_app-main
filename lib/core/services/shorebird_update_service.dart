import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

import '../utils/app_preferences.dart';

/// Information presented in the post-update welcome dialog when a new app
/// release or Shorebird OTA patch has been installed on the device.
class ShorebirdWelcomeMessage {
  /// Formatted version string including patch number when present
  /// (e.g., `v1.0.0+1 (Patch #2)`).
  final String versionLabel;

  /// Date and time when the update was applied/downloaded.
  final DateTime updatedAt;

  /// `true` when an OTA patch was downloaded in this session and will activate
  /// on restart; `false` when running directly on the newly updated version.
  final bool restartRequired;

  /// Creates a [ShorebirdWelcomeMessage].
  const ShorebirdWelcomeMessage({
    required this.versionLabel,
    required this.updatedAt,
    this.restartRequired = false,
  });
}

/// Snapshot returned after checking current version/patch and Shorebird OTA.
class ShorebirdUpdateCheckResult {
  /// Human-readable version & patch label for settings display.
  final String versionLabel;

  /// Active Shorebird patch number (`null` on base binary or non-Shorebird builds).
  final int? patchNumber;

  /// Current OTA update status returned by Shorebird.
  final UpdateStatus status;

  /// Whether the Shorebird engine is active in the current build.
  final bool isShorebirdAvailable;

  /// Optional welcome banner/dialog payload if this launch reflects a new update
  /// or if an OTA patch was just downloaded.
  final ShorebirdWelcomeMessage? welcomeMessage;

  /// Creates a [ShorebirdUpdateCheckResult].
  const ShorebirdUpdateCheckResult({
    required this.versionLabel,
    required this.patchNumber,
    required this.status,
    required this.isShorebirdAvailable,
    this.welcomeMessage,
  });
}

/// Testable abstraction over `ShorebirdUpdater` & `PackageInfo`.
class ShorebirdPlatformBridge {
  final ShorebirdUpdater Function() updaterFactory;
  final Future<({String version, String buildNumber})> Function()
      appVersionReader;

  const ShorebirdPlatformBridge({
    this.updaterFactory = ShorebirdUpdater.new,
    this.appVersionReader = _defaultAppVersionReader,
  });

  static Future<({String version, String buildNumber})>
      _defaultAppVersionReader() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return (version: info.version, buildNumber: info.buildNumber);
    } catch (_) {
      return (version: '1.0.0', buildNumber: '1');
    }
  }
}

/// Manages Shorebird OTA code-push checks, automatic background patch
/// downloads, and version/date welcome tracking across devices.
class ShorebirdUpdateService {
  ShorebirdUpdateService({ShorebirdPlatformBridge? bridge})
      : _bridge = bridge ?? const ShorebirdPlatformBridge();

  static final ShorebirdUpdateService instance = ShorebirdUpdateService();

  final ShorebirdPlatformBridge _bridge;
  bool _isChecking = false;
  Future<ShorebirdUpdateCheckResult>? _inFlightCheck;

  static String formatVersionLabel({
    required String version,
    required String buildNumber,
    int? patchNumber,
  }) {
    final base = 'v$version+$buildNumber';
    if (patchNumber != null && patchNumber > 0) {
      return '$base (Patch #$patchNumber)';
    }
    return base;
  }

  /// Checks installed version/patch against saved state, triggers Shorebird OTA
  /// download automatically when outdated, and returns a [ShorebirdWelcomeMessage]
  /// at most once per newly downloaded or newly activated release/patch.
  Future<ShorebirdUpdateCheckResult> checkAndSyncUpdates() {
    final existing = _inFlightCheck;
    if (existing != null) return existing;
    final run = _runSerializedCheck();
    _inFlightCheck = run;
    return run;
  }

  Future<ShorebirdUpdateCheckResult> _runSerializedCheck() async {
    try {
      return await _runCheckAndSyncUpdates();
    } finally {
      _inFlightCheck = null;
    }
  }

  Future<ShorebirdUpdateCheckResult> _runCheckAndSyncUpdates() async {
    final appVer = await _bridge.appVersionReader();
    int? currentPatchNum;
    bool isAvailable = false;
    UpdateStatus status = UpdateStatus.unavailable;

    ShorebirdUpdater? updater;
    try {
      updater = _bridge.updaterFactory();
      isAvailable = updater.isAvailable;
      if (isAvailable) {
        final patch = await updater.readCurrentPatch();
        currentPatchNum = patch?.number;
      }
    } catch (e) {
      debugPrint('Shorebird readCurrentPatch skipped: $e');
    }

    final displayVersion = formatVersionLabel(
      version: appVer.version,
      buildNumber: appVer.buildNumber,
      patchNumber: currentPatchNum,
    );
    final currentSig =
        '${appVer.version}+${appVer.buildNumber}#patch_${currentPatchNum ?? 0}';

    final previousSig = await AppPreferences.getLastWelcomedAppVersion();
    final pendingRaw = await AppPreferences.getPendingUpdateWelcome();
    final lastShownPopup = await AppPreferences.getLastShownPopupSignature();
    ShorebirdWelcomeMessage? welcome;

    // 1. Check whether this cold start booted onto a newer release or patch.
    final isActivatedNewReleaseOrPatch =
        (previousSig != null && previousSig != currentSig) ||
            (previousSig == null &&
                currentPatchNum != null &&
                currentPatchNum > 0);

    if (isActivatedNewReleaseOrPatch) {
      DateTime activatedAt = DateTime.now();
      if (pendingRaw != null && pendingRaw.contains('|')) {
        final parts = pendingRaw.split('|');
        final parsed = DateTime.tryParse(parts.last);
        if (parsed != null) activatedAt = parsed;
      }
      final activePopupSig = 'active:$currentSig';
      await AppPreferences.setLastWelcomedAppVersion(currentSig);
      await AppPreferences.setLastUpdateDate(activatedAt);
      await AppPreferences.setPendingUpdateWelcome(null);
      if (lastShownPopup != activePopupSig) {
        await AppPreferences.setLastShownPopupSignature(activePopupSig);
        welcome = ShorebirdWelcomeMessage(
          versionLabel: displayVersion,
          updatedAt: activatedAt,
          restartRequired: false,
        );
      }
    } else if (previousSig == null) {
      // Initial baseline install: store signature cleanly so the next OTA
      // patch or APK upgrade welcomes the user with version & update date.
      await AppPreferences.setLastWelcomedAppVersion(currentSig);
      await AppPreferences.setLastUpdateDate(DateTime.now());
      await AppPreferences.setLastShownPopupSignature('active:$currentSig');
    }

    // 2. Check Shorebird servers and automatically download any pending OTA patch.
    if (isAvailable && updater != null && !_isChecking) {
      _isChecking = true;
      try {
        status = await updater.checkForUpdate();
        if (status == UpdateStatus.outdated) {
          await updater.update();
          final nextPatch = await updater.readNextPatch();
          final nextPatchNum = nextPatch?.number ?? (currentPatchNum ?? 0) + 1;
          final nextLabel = formatVersionLabel(
            version: appVer.version,
            buildNumber: appVer.buildNumber,
            patchNumber: nextPatchNum,
          );
          final downloadedAt = DateTime.now();
          await AppPreferences.setPendingUpdateWelcome(
            '$nextLabel|${downloadedAt.toIso8601String()}',
          );
          status = UpdateStatus.restartRequired;
          final pendingPopupSig =
              'pending:${appVer.version}+${appVer.buildNumber}#patch_$nextPatchNum';
          final updatedShown = await AppPreferences.getLastShownPopupSignature();
          if (welcome == null && updatedShown != pendingPopupSig) {
            await AppPreferences.setLastShownPopupSignature(pendingPopupSig);
            welcome = ShorebirdWelcomeMessage(
              versionLabel: nextLabel,
              updatedAt: downloadedAt,
              restartRequired: true,
            );
          }
        } else if (status == UpdateStatus.restartRequired) {
          final nextPatch = await updater.readNextPatch();
          final nextPatchNum = nextPatch?.number ?? currentPatchNum ?? 0;
          final nextLabel = formatVersionLabel(
            version: appVer.version,
            buildNumber: appVer.buildNumber,
            patchNumber: nextPatch?.number ?? currentPatchNum,
          );
          DateTime downloadedAt = DateTime.now();
          if (pendingRaw != null && pendingRaw.contains('|')) {
            final parsed = DateTime.tryParse(pendingRaw.split('|').last);
            if (parsed != null) downloadedAt = parsed;
          }
          final pendingPopupSig =
              'pending:${appVer.version}+${appVer.buildNumber}#patch_$nextPatchNum';
          final updatedShown = await AppPreferences.getLastShownPopupSignature();
          if (welcome == null && updatedShown != pendingPopupSig) {
            await AppPreferences.setLastShownPopupSignature(pendingPopupSig);
            welcome = ShorebirdWelcomeMessage(
              versionLabel: nextLabel,
              updatedAt: downloadedAt,
              restartRequired: true,
            );
          }
        }
      } catch (e) {
        debugPrint('Shorebird check/update error: $e');
      } finally {
        _isChecking = false;
      }
    }

    return ShorebirdUpdateCheckResult(
      versionLabel: displayVersion,
      patchNumber: currentPatchNum,
      status: status,
      isShorebirdAvailable: isAvailable,
      welcomeMessage: welcome,
    );
  }
}
