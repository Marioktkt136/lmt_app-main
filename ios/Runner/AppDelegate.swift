import AVFoundation
import Flutter
import MobileCoreServices
import Photos
import PhotosUI
import UIKit
import UserNotifications

import BackgroundTasks
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "com.example.lmt/native_media"
  private var isChannelRegistered = false

  private var audioRecorder: AVAudioRecorder?
  private var audioPlayer: AVAudioPlayer?
  private var currentRecordingPath: String?
  private var currentPlayingPath: String?
  private var pendingFilePickerResult: FlutterResult?
  private var pickerType: String = "any"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    LmtIosBackgroundSync.shared.registerBackgroundTasks()
    application.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if !isChannelRegistered,
       let controller = window?.rootViewController as? FlutterViewController {
      registerMediaChannel(messenger: controller.binaryMessenger)
    }
    return ok
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "LmtNativeMediaPlugin") {
      registerMediaChannel(messenger: registrar.messenger())
    }
  }

  private func registerMediaChannel(messenger: FlutterBinaryMessenger) {
    guard !isChannelRegistered else { return }
    isChannelRegistered = true
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }
    LmtIosBackgroundSync.shared.registerChannel(messenger: messenger)
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
    LmtIosBackgroundSync.shared.scheduleAppRefreshIfNeeded()
    super.applicationDidEnterBackground(application)
  }

  override func application(
    _ application: UIApplication,
    performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    LmtIosBackgroundSync.shared.pollAndAlertIfNeeded { hasNew in
      DispatchQueue.main.async {
        completionHandler(hasNew ? .newData : .noData)
      }
    }
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    if let payload = response.notification.request.content.userInfo["lmt_notif_payload"] as? String {
      LmtIosBackgroundSync.shared.handleNotificationTapPayload(payload)
    }
    super.userNotificationCenter(center, didReceive: response, withCompletionHandler: completionHandler)
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]

    switch call.method {
    case "pickDeviceFile":
      let type = (args?["type"] as? String) ?? "any"
      let allowedExtensions = args?["allowedExtensions"] as? [String]
      DispatchQueue.main.async {
        self.launchSystemPicker(type: type, allowedExtensions: allowedExtensions, result: result)
      }

    case "captureCameraPhoto":
      DispatchQueue.main.async {
        self.launchCameraCaptureDirect(result: result)
      }

    case "requestMicPermission":
      requestMicrophonePermission(result: result)

    case "startVoiceRecording":
      startVoiceRecording(result: result)

    case "stopVoiceRecording":
      result(stopVoiceRecordingInternal())

    case "cancelVoiceRecording":
      cancelVoiceRecordingInternal()
      result(true)

    case "playVoiceNote":
      guard let path = args?["path"] as? String, !path.isEmpty else {
        result(FlutterError(code: "INVALID_PATH", message: "Audio path is empty", details: nil))
        return
      }
      let speed = (args?["speed"] as? Double) ?? 1.0
      let positionMs = args?["positionMs"] as? Int
      playAudioInternal(path: path, speed: Float(speed), positionMs: positionMs, result: result)

    case "pauseVoiceNote":
      audioPlayer?.pause()
      result(true)

    case "seekVoiceNote":
      let positionMs = (args?["positionMs"] as? Int) ?? 0
      audioPlayer?.currentTime = TimeInterval(positionMs) / 1000.0
      result(true)

    case "setVoicePlaybackSpeed":
      let speed = (args?["speed"] as? Double) ?? 1.0
      audioPlayer?.enableRate = true
      audioPlayer?.rate = Float(speed)
      result(true)

    case "stopVoiceNote":
      stopAudioInternal()
      result(true)

    case "saveFileToPublicDownloads":
      guard let sourcePath = args?["sourcePath"] as? String, !sourcePath.isEmpty else {
        result(FlutterError(code: "INVALID_SOURCE", message: "Source path is empty", details: nil))
        return
      }
      let fileName = (args?["fileName"] as? String) ?? "LMT_File.txt"
      let mimeType = (args?["mimeType"] as? String) ?? "application/octet-stream"
      saveFileToDownloadsInternal(
        sourcePath: sourcePath,
        fileName: fileName,
        mimeType: mimeType,
        result: result
      )

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  // MARK: - Top ViewController Helper (UIScene & Legacy Safe)

  private func topViewController() -> UIViewController? {
    var root: UIViewController?
    if #available(iOS 13.0, *) {
      let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
      let activeScene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
      root = activeScene?.windows.first(where: { $0.isKeyWindow })?.rootViewController
        ?? activeScene?.windows.first?.rootViewController
    }
    if root == nil {
      root = window?.rootViewController
    }
    var top = root
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }

  private func showSettingsAlert(title: String, message: String) {
    DispatchQueue.main.async {
      guard let presenter = self.topViewController() else { return }
      let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
      alert.addAction(UIAlertAction(title: "إلغاء / Cancel", style: .cancel))
      alert.addAction(UIAlertAction(title: "الإعدادات / Settings", style: .default) { _ in
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
          UIApplication.shared.open(settingsUrl)
        }
      })
      presenter.present(alert, animated: true)
    }
  }

  // MARK: - Native Microphone Permission & Voice Notes

  private func requestMicrophonePermission(result: @escaping FlutterResult) {
    let session = AVAudioSession.sharedInstance()
    switch session.recordPermission {
    case .granted:
      result(true)
    case .denied:
      showSettingsAlert(
        title: "إذن الميكروفون مطلوب 🎤",
        message: "يرجى تفعيل إذن الميكروفون لتسجيل وإرسال الرسائل الصوتية من الإعدادات."
      )
      result(false)
    case .undetermined:
      session.requestRecordPermission { granted in
        DispatchQueue.main.async {
          result(granted)
        }
      }
    @unknown default:
      result(false)
    }
  }

  private func startVoiceRecording(result: @escaping FlutterResult) {
    let session = AVAudioSession.sharedInstance()
    guard session.recordPermission == .granted else {
      result(FlutterError(code: "PERMISSION_DENIED", message: "Microphone permission not granted", details: nil))
      return
    }

    _ = stopVoiceRecordingInternal()

    do {
      try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
      try session.setActive(true)

      let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      let voiceDir = docsDir.appendingPathComponent("voice_notes", isDirectory: true)
      if !FileManager.default.fileExists(atPath: voiceDir.path) {
        try FileManager.default.createDirectory(at: voiceDir, withIntermediateDirectories: true)
      }

      let fileName = "vn_\(Int(Date().timeIntervalSince1970 * 1000)).m4a"
      let outUrl = voiceDir.appendingPathComponent(fileName)
      currentRecordingPath = outUrl.path

      let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 44100,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
      ]

      let recorder = try AVAudioRecorder(url: outUrl, settings: settings)
      recorder.prepareToRecord()
      recorder.record()
      audioRecorder = recorder
      result(outUrl.path)
    } catch {
      result(FlutterError(code: "RECORD_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  private func stopVoiceRecordingInternal() -> String? {
    let path = currentRecordingPath
    if let recorder = audioRecorder {
      if recorder.isRecording {
        recorder.stop()
      }
      audioRecorder = nil
    }
    return path
  }

  private func cancelVoiceRecordingInternal() {
    let path = stopVoiceRecordingInternal()
    if let p = path, !p.isEmpty {
      try? FileManager.default.removeItem(atPath: p)
    }
    currentRecordingPath = nil
  }

  private func playAudioInternal(
    path: String,
    speed: Float,
    positionMs: Int?,
    result: @escaping FlutterResult
  ) {
    do {
      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playback, mode: .default)
      try session.setActive(true)

      if let existing = audioPlayer, currentPlayingPath == path {
        existing.enableRate = true
        existing.rate = speed
        if let pos = positionMs {
          existing.currentTime = TimeInterval(pos) / 1000.0
        }
        if !existing.isPlaying {
          existing.play()
        }
        result(true)
        return
      }

      stopAudioInternal()

      let fileUrl = URL(fileURLWithPath: path)
      guard FileManager.default.fileExists(atPath: fileUrl.path) else {
        result(FlutterError(code: "INVALID_PATH", message: "Audio file does not exist", details: nil))
        return
      }

      let player = try AVAudioPlayer(contentsOf: fileUrl)
      player.enableRate = true
      player.rate = speed
      if let pos = positionMs, pos > 0 {
        player.currentTime = TimeInterval(pos) / 1000.0
      }
      player.delegate = self
      player.prepareToPlay()
      player.play()
      audioPlayer = player
      currentPlayingPath = path
      result(true)
    } catch {
      result(FlutterError(code: "PLAY_ERROR", message: error.localizedDescription, details: nil))
    }
  }

  private func stopAudioInternal() {
    audioPlayer?.stop()
    audioPlayer = nil
    currentPlayingPath = nil
  }

  // MARK: - Native Camera, Gallery (Photos) & Files Picker

  private func completePicker(with value: Any?) {
    DispatchQueue.main.async {
      let callback = self.pendingFilePickerResult
      self.pendingFilePickerResult = nil
      callback?(value)
    }
  }

  private func launchSystemPicker(
    type: String,
    allowedExtensions: [String]?,
    result: @escaping FlutterResult
  ) {
    if pendingFilePickerResult != nil {
      completePicker(with: nil)
    }
    guard let presenter = topViewController() else {
      result(nil)
      return
    }

    pendingFilePickerResult = result
    pickerType = type

    // Open Photo Gallery directly for images, videos, or combined media picks
    if type == "image" || type == "video" || type == "media" {
      requestPhotoLibraryThenOpen(mediaKind: type)
    } else {
      presentDocumentPicker(on: presenter, allowedExtensions: allowedExtensions)
    }
  }

  private func launchCameraCaptureDirect(result: @escaping FlutterResult) {
    if pendingFilePickerResult != nil {
      completePicker(with: nil)
    }
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      result(FlutterError(code: "NO_CAMERA", message: "Camera not available", details: nil))
      return
    }
    pendingFilePickerResult = result
    pickerType = "image"
    requestCameraThenOpen(mediaKind: "image")
  }

  private func requestPhotoLibraryThenOpen(mediaKind: String) {
    let handleStatus: (PHAuthorizationStatus) -> Void = { status in
      DispatchQueue.main.async {
        let isAuthorized: Bool
        if #available(iOS 14.0, *) {
          isAuthorized = (status == .authorized || status == .limited)
        } else {
          isAuthorized = (status == .authorized)
        }

        guard isAuthorized else {
          self.showSettingsAlert(
            title: "إذن معرض الصور مطلوب 🖼️",
            message: "يرجى تفعيل إذن الصور من الإعدادات لاختيار الصور والفيديوهات."
          )
          self.completePicker(with: nil)
          return
        }

        self.openPhotoLibrary(mediaKind: mediaKind)
      }
    }

    if #available(iOS 14.0, *) {
      let current = PHPhotoLibrary.authorizationStatus(for: .readWrite)
      if current == .notDetermined {
        PHPhotoLibrary.requestAuthorization(for: .readWrite, handler: handleStatus)
      } else {
        handleStatus(current)
      }
    } else {
      let current = PHPhotoLibrary.authorizationStatus()
      if current == .notDetermined {
        PHPhotoLibrary.requestAuthorization(handleStatus)
      } else {
        handleStatus(current)
      }
    }
  }

  private func openPhotoLibrary(mediaKind: String) {
    guard let presenter = topViewController() else {
      completePicker(with: nil)
      return
    }

    if #available(iOS 14.0, *) {
      var config = PHPickerConfiguration(photoLibrary: .shared())
      config.selectionLimit = 1
      switch mediaKind {
      case "image":
        config.filter = .images
      case "video":
        config.filter = .videos
      default:
        config.filter = .any(of: [.images, .videos])
      }
      let picker = PHPickerViewController(configuration: config)
      picker.delegate = self
      picker.presentationController?.delegate = self
      presenter.present(picker, animated: true)
    } else {
      let picker = UIImagePickerController()
      picker.sourceType = .photoLibrary
      picker.delegate = self
      picker.presentationController?.delegate = self
      switch mediaKind {
      case "video":
        picker.mediaTypes = [kUTTypeMovie as String]
      case "media":
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
      default:
        picker.mediaTypes = [kUTTypeImage as String]
      }
      presenter.present(picker, animated: true)
    }
  }

  private func requestCameraThenOpen(mediaKind: String) {
    let status = AVCaptureDevice.authorizationStatus(for: .video)
    switch status {
    case .authorized:
      openCamera(mediaKind: mediaKind)
    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async {
          if granted {
            self.openCamera(mediaKind: mediaKind)
          } else {
            self.showSettingsAlert(
              title: "إذن الكاميرا مطلوب 📷",
              message: "يرجى السماح بالوصول إلى الكاميرا لالتقاط الصور والفيديوهات."
            )
            self.completePicker(with: nil)
          }
        }
      }
    default:
      showSettingsAlert(
        title: "إذن الكاميرا مطلوب 📷",
        message: "يرجى تفعيل إذن الكاميرا من الإعدادات لالتقاط الصور والفيديوهات."
      )
      completePicker(with: nil)
    }
  }

  private func openCamera(mediaKind: String) {
    guard let presenter = topViewController(),
          UIImagePickerController.isSourceTypeAvailable(.camera) else {
      completePicker(with: nil)
      return
    }
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = self
    picker.presentationController?.delegate = self
    if mediaKind == "video" {
      picker.mediaTypes = [kUTTypeMovie as String]
    } else if mediaKind == "media" {
      picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
    } else {
      picker.mediaTypes = [kUTTypeImage as String]
    }
    presenter.present(picker, animated: true)
  }

  private func presentDocumentPicker(
    on presenter: UIViewController,
    allowedExtensions: [String]?
  ) {
    var docTypes: [String] = []
    if let exts = allowedExtensions, !exts.isEmpty {
      for ext in exts {
        if let uti = UTTypeCreatePreferredIdentifierForTag(
          kUTTagClassFilenameExtension,
          ext.lowercased() as CFString,
          nil
        )?.takeRetainedValue() as String? {
          docTypes.append(uti)
        }
      }
    }
    if docTypes.isEmpty {
      if pickerType == "image" {
        docTypes = [kUTTypeImage as String]
      } else if pickerType == "video" {
        docTypes = [kUTTypeMovie as String]
      } else if pickerType == "media" {
        docTypes = [kUTTypeImage as String, kUTTypeMovie as String]
      } else {
        docTypes = [
          kUTTypeItem as String,
          kUTTypeData as String,
          kUTTypeContent as String,
          kUTTypePDF as String,
          kUTTypeImage as String,
          kUTTypeMovie as String,
        ]
      }
    }

    let docPicker = UIDocumentPickerViewController(documentTypes: docTypes, in: .import)
    docPicker.delegate = self
    docPicker.allowsMultipleSelection = false
    docPicker.presentationController?.delegate = self
    presenter.present(docPicker, animated: true)
  }

  // MARK: - File Caching & Saving Helper

  private func pickedCacheDirectory() throws -> URL {
    let caches = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let dir = caches.appendingPathComponent("picked_files", isDirectory: true)
    if !FileManager.default.fileExists(atPath: dir.path) {
      try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
    return dir
  }

  private func copyUrlToLocalCache(sourceUrl: URL, preferredName: String? = nil) -> [String: Any]? {
    let accessed = sourceUrl.startAccessingSecurityScopedResource()
    defer {
      if accessed {
        sourceUrl.stopAccessingSecurityScopedResource()
      }
    }

    do {
      let dir = try pickedCacheDirectory()
      let rawName = (preferredName?.isEmpty == false ? preferredName! : sourceUrl.lastPathComponent)
      let safeName = rawName.replacingOccurrences(
        of: "[\\\\/:*?\"<>|]",
        with: "_",
        options: .regularExpression
      )
      let destUrl = dir.appendingPathComponent("\(Int(Date().timeIntervalSince1970 * 1000))_\(safeName)")
      if FileManager.default.fileExists(atPath: destUrl.path) {
        try? FileManager.default.removeItem(at: destUrl)
      }
      try FileManager.default.copyItem(at: sourceUrl, to: destUrl)
      let attrs = try FileManager.default.attributesOfItem(atPath: destUrl.path)
      let size = (attrs[.size] as? NSNumber)?.intValue ?? 0
      return [
        "name": rawName,
        "path": destUrl.path,
        "size": size,
      ]
    } catch {
      return nil
    }
  }

  private func writeImageToLocalCache(image: UIImage, name: String) -> [String: Any]? {
    guard let data = image.jpegData(compressionQuality: 0.92) else { return nil }
    do {
      let dir = try pickedCacheDirectory()
      let destUrl = dir.appendingPathComponent("\(Int(Date().timeIntervalSince1970 * 1000))_\(name)")
      try data.write(to: destUrl, options: .atomic)
      return [
        "name": name,
        "path": destUrl.path,
        "size": data.count,
      ]
    } catch {
      return nil
    }
  }

  private func saveFileToDownloadsInternal(
    sourcePath: String,
    fileName: String,
    mimeType: String,
    result: @escaping FlutterResult
  ) {
    do {
      let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
      let downloadsDir = docsDir.appendingPathComponent("LMT_Downloads", isDirectory: true)
      if !FileManager.default.fileExists(atPath: downloadsDir.path) {
        try FileManager.default.createDirectory(at: downloadsDir, withIntermediateDirectories: true)
      }
      let safeName = fileName.replacingOccurrences(
        of: "[\\\\/:*?\"<>|]",
        with: "_",
        options: .regularExpression
      )
      let destUrl = downloadsDir.appendingPathComponent(safeName)
      let srcUrl = URL(fileURLWithPath: sourcePath)
      if srcUrl.path != destUrl.path {
        if FileManager.default.fileExists(atPath: destUrl.path) {
          try FileManager.default.removeItem(at: destUrl)
        }
        try FileManager.default.copyItem(at: srcUrl, to: destUrl)
      }

      if mimeType.hasPrefix("image/"), let img = UIImage(contentsOfFile: destUrl.path) {
        let saveToPhotos = {
          UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        }
        if #available(iOS 14.0, *) {
          let addStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
          if addStatus == .authorized || addStatus == .limited {
            saveToPhotos()
          } else if addStatus == .notDetermined {
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
              if status == .authorized || status == .limited {
                DispatchQueue.main.async { saveToPhotos() }
              }
            }
          }
        } else {
          if PHPhotoLibrary.authorizationStatus() == .authorized {
            saveToPhotos()
          }
        }
      }

      result(destUrl.path)
    } catch {
      result(FlutterError(code: "DOWNLOAD_ERROR", message: error.localizedDescription, details: nil))
    }
  }
}

// MARK: - AVAudioPlayerDelegate

extension AppDelegate: AVAudioPlayerDelegate {
  func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
    if audioPlayer === player {
      audioPlayer = nil
      currentPlayingPath = nil
    }
  }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension AppDelegate: UIAdaptivePresentationControllerDelegate {
  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    completePicker(with: nil)
  }
}

// MARK: - UIDocumentPickerDelegate

extension AppDelegate: UIDocumentPickerDelegate {
  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    guard let picked = urls.first else {
      completePicker(with: nil)
      return
    }
    completePicker(with: copyUrlToLocalCache(sourceUrl: picked))
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    completePicker(with: nil)
  }
}

// MARK: - UIImagePickerControllerDelegate

extension AppDelegate: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    picker.dismiss(animated: true) {
      if let mediaUrl = info[.mediaURL] as? URL {
        self.completePicker(with: self.copyUrlToLocalCache(sourceUrl: mediaUrl))
      } else if let imageUrl = info[.imageURL] as? URL {
        self.completePicker(with: self.copyUrlToLocalCache(sourceUrl: imageUrl))
      } else if let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage {
        self.completePicker(
          with: self.writeImageToLocalCache(image: image, name: "lmt_photo.jpg")
        )
      } else {
        self.completePicker(with: nil)
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true) {
      self.completePicker(with: nil)
    }
  }
}

/// iOS background fetch coordinator querying Firestore REST for unseen
/// notifications while the screen is locked or app is backgrounded.
private final class LmtIosBackgroundSync {
  static let shared = LmtIosBackgroundSync()

  private let channelName = "com.example.lmt/background_sync"
  private let bgTaskId = "com.example.lmt.bgfetch"
  private let defaults = UserDefaults.standard
  private let lock = NSLock()

  private let keyLoggedIn = "lmt_bg_logged_in"
  private let keyUserId = "lmt_bg_user_id"
  private let keyApiKey = "lmt_bg_api_key"
  private let keyProjectId = "lmt_bg_project_id"
  private let keyIdToken = "lmt_bg_id_token"
  private let keyTokenTs = "lmt_bg_token_ts"
  private let keyAlertedPrefix = "lmt_bg_alerted_"
  private let keyPendingNativePrefix = "lmt_bg_pending_native_"

  private var methodChannel: FlutterMethodChannel?
  private var pendingLaunchPayload: String?
  private var registeredBgTasks = false

  private init() {}

  func registerChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    methodChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }
  }

  func registerBackgroundTasks() {
    guard !registeredBgTasks else { return }
    registeredBgTasks = true
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: bgTaskId, using: nil) { [weak self] task in
        guard let refreshTask = task as? BGAppRefreshTask else {
          task.setTaskCompleted(success: false)
          return
        }
        self?.handleAppRefresh(task: refreshTask)
      }
    }
  }

  func scheduleAppRefreshIfNeeded() {
    guard isSessionActive() else { return }
    if #available(iOS 13.0, *) {
      let request = BGAppRefreshTaskRequest(identifier: bgTaskId)
      request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
      try? BGTaskScheduler.shared.submit(request)
    }
  }

  @available(iOS 13.0, *)
  private func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefreshIfNeeded()
    let session = URLSession.shared
    task.expirationHandler = {
      session.invalidateAndCancel()
    }
    pollAndAlertIfNeeded { _ in
      task.setTaskCompleted(success: true)
    }
  }

  func handleNotificationTapPayload(_ payload: String) {
    let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    if let channel = methodChannel {
      pendingLaunchPayload = nil
      DispatchQueue.main.async {
        channel.invokeMethod("onBackgroundNotificationTapped", arguments: trimmed)
      }
    } else {
      pendingLaunchPayload = trimmed
    }
  }

  func isSessionActive() -> Bool {
    return defaults.bool(forKey: keyLoggedIn)
      && !(defaults.string(forKey: keyUserId) ?? "").trimmingCharacters(in: .whitespaces).isEmpty
      && !(defaults.string(forKey: keyApiKey) ?? "").trimmingCharacters(in: .whitespaces).isEmpty
      && !(defaults.string(forKey: keyProjectId) ?? "").trimmingCharacters(in: .whitespaces).isEmpty
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "syncSessionConfig":
      let loggedIn = (args?["isLoggedIn"] as? Bool) ?? false
      let userId = ((args?["userId"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      let apiKey = ((args?["apiKey"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      let projectId = ((args?["projectId"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      let idToken = (args?["idToken"] as? String)?.trimmingCharacters(in: .whitespaces)
      let alertedIds = (args?["alertedIds"] as? [String]) ?? []

      lock.lock()
      defaults.set(loggedIn && !userId.isEmpty, forKey: keyLoggedIn)
      defaults.set(userId, forKey: keyUserId)
      defaults.set(apiKey, forKey: keyApiKey)
      defaults.set(projectId, forKey: keyProjectId)
      if let token = idToken, !token.isEmpty {
        defaults.set(token, forKey: keyIdToken)
        defaults.set(Date().timeIntervalSince1970, forKey: keyTokenTs)
      } else if !loggedIn {
        defaults.removeObject(forKey: keyIdToken)
        defaults.removeObject(forKey: keyTokenTs)
      }
      if loggedIn && !userId.isEmpty && !alertedIds.isEmpty {
        appendIdsLocked(forKey: "\(keyAlertedPrefix)\(userId)", ids: alertedIds)
      }
      lock.unlock()

      if loggedIn && !userId.isEmpty {
        scheduleAppRefreshIfNeeded()
      } else if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: bgTaskId)
      }
      result(nil)

    case "recordAlertedIds":
      let userId = ((args?["userId"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      let ids = (args?["ids"] as? [String]) ?? []
      if !userId.isEmpty && !ids.isEmpty {
        lock.lock()
        appendIdsLocked(forKey: "\(keyAlertedPrefix)\(userId)", ids: ids)
        lock.unlock()
      }
      result(nil)

    case "consumeNativeAlertedIds":
      let userId = ((args?["userId"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      var consumed: [String] = []
      if !userId.isEmpty {
        lock.lock()
        let key = "\(keyPendingNativePrefix)\(userId)"
        consumed = defaults.stringArray(forKey: key) ?? []
        defaults.removeObject(forKey: key)
        lock.unlock()
      }
      result(consumed)

    case "consumeLaunchPayload":
      let payload = pendingLaunchPayload
      pendingLaunchPayload = nil
      result(payload)

    case "isIgnoringBatteryOptimizations":
      result(true)

    case "requestIgnoreBatteryOptimizations":
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func pollAndAlertIfNeeded(completion: @escaping (Bool) -> Void) {
    guard isSessionActive() else {
      completion(false)
      return
    }
    let userId = (defaults.string(forKey: keyUserId) ?? "").trimmingCharacters(in: .whitespaces)
    let apiKey = (defaults.string(forKey: keyApiKey) ?? "").trimmingCharacters(in: .whitespaces)
    let projectId = (defaults.string(forKey: keyProjectId) ?? "").trimmingCharacters(in: .whitespaces)
    let storedToken = defaults.string(forKey: keyIdToken)
    let tokenAge = Date().timeIntervalSince1970 - defaults.double(forKey: keyTokenTs)

    let proceedWithToken: (String?) -> Void = { [weak self] token in
      guard let self = self, let token = token, !token.isEmpty else {
        completion(false)
        return
      }
      self.fetchNotifications(projectId: projectId, idToken: token) { items in
        guard let items = items, !items.isEmpty else {
          completion(false)
          return
        }
        self.dispatchUnseenNotifications(items, userId: userId, completion: completion)
      }
    }

    if let token = storedToken, !token.isEmpty, tokenAge < (45 * 60) {
      proceedWithToken(token)
    } else {
      refreshAnonymousToken(apiKey: apiKey, completion: proceedWithToken)
    }
  }

  private func refreshAnonymousToken(apiKey: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(apiKey)") else {
      completion(nil)
      return
    }
    var req = URLRequest(url: url, timeoutInterval: 10)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = #"{"returnSecureToken":true}"#.data(using: .utf8)

    URLSession.shared.dataTask(with: req) { [weak self] data, resp, _ in
      guard let self = self,
            let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
            let data = data,
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let token = (obj["idToken"] as? String)?.trimmingCharacters(in: .whitespaces),
            !token.isEmpty else {
        completion(nil)
        return
      }
      self.lock.lock()
      self.defaults.set(token, forKey: self.keyIdToken)
      self.defaults.set(Date().timeIntervalSince1970, forKey: self.keyTokenTs)
      self.lock.unlock()
      completion(token)
    }.resume()
  }

  private func fetchNotifications(
    projectId: String,
    idToken: String,
    completion: @escaping ([[String: Any]]?) -> Void
  ) {
    guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents:runQuery") else {
      completion(nil)
      return
    }
    var req = URLRequest(url: url, timeoutInterval: 10)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
    let bodyObj: [String: Any] = [
      "structuredQuery": [
        "from": [["collectionId": "notifications"]],
        "orderBy": [["field": ["fieldPath": "dateTime"], "direction": "DESCENDING"]],
        "limit": 25
      ]
    ]
    req.httpBody = try? JSONSerialization.data(withJSONObject: bodyObj)

    URLSession.shared.dataTask(with: req) { data, resp, _ in
      guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
            let data = data,
            let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        completion(nil)
        return
      }
      let docs = entries.compactMap { $0["document"] as? [String: Any] }
      completion(docs)
    }.resume()
  }

  private func dispatchUnseenNotifications(
    _ docs: [[String: Any]],
    userId: String,
    completion: @escaping (Bool) -> Void
  ) {
    lock.lock()
    let alerted = Set(defaults.stringArray(forKey: "\(keyAlertedPrefix)\(userId)") ?? [])
    lock.unlock()

    let now = Date()
    var newlyAlerted: [String] = []
    let center = UNUserNotificationCenter.current()

    for doc in docs {
      guard let fields = doc["fields"] as? [String: Any] else { continue }
      let fallbackId = ((doc["name"] as? String) ?? "").components(separatedBy: "/").last ?? ""
      let id = (fsString(fields, "id").isEmpty ? fallbackId : fsString(fields, "id"))
      if id.isEmpty || alerted.contains(id) { continue }
      if fsBool(fields, "isRead") { continue }
      let excluded = fsStringArray(fields, "excludedMemberIds")
      if excluded.contains(userId) { continue }
      let targeted = fsStringArray(fields, "targetMemberIds")
      if !targeted.isEmpty && !targeted.contains(userId) { continue }
      guard let date = parseIso8601(fsString(fields, "dateTime")),
            abs(now.timeIntervalSince(date)) <= 24 * 60 * 60 else { continue }

      let title = fsString(fields, "title").isEmpty ? "L.M.T App" : fsString(fields, "title")
      let description = fsString(fields, "description")
      if title.isEmpty && description.isEmpty { continue }

      let category = fsString(fields, "category")
      let rawTone = fsString(fields, "tone")
      let tone = rawTone.isEmpty
        ? (category == "calendar" ? "calendar" : (category == "chat" ? "chatMessage" : "normal"))
        : rawTone

      var payloadDict: [String: Any] = ["notifId": id]
      if let tab = fsInt(fields, "targetTabIndex") { payloadDict["tab"] = tab }
      let groupId = fsString(fields, "targetGroupId")
      if !groupId.isEmpty { payloadDict["groupId"] = groupId }
      let eventId = fsString(fields, "targetEventId")
      if !eventId.isEmpty { payloadDict["eventId"] = eventId }
      let route = fsString(fields, "targetRoute")
      if !route.isEmpty { payloadDict["route"] = route }

      let payloadData = (try? JSONSerialization.data(withJSONObject: payloadDict)) ?? Data()
      let payloadStr = String(data: payloadData, encoding: .utf8) ?? ""

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = description
      content.userInfo = ["lmt_notif_payload": payloadStr]
      if tone == "calendar",
         Bundle.main.url(forResource: "calendar_notifications", withExtension: "wav") != nil {
        content.sound = UNNotificationSound(named: UNNotificationSoundName("calendar_notifications.wav"))
      } else if Bundle.main.url(forResource: "normal_notifications", withExtension: "wav") != nil {
        content.sound = UNNotificationSound(named: UNNotificationSoundName("normal_notifications.wav"))
      } else {
        content.sound = .default
      }

      let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
      center.add(request, withCompletionHandler: nil)
      newlyAlerted.append(id)
    }

    if !newlyAlerted.isEmpty {
      lock.lock()
      appendIdsLocked(forKey: "\(keyAlertedPrefix)\(userId)", ids: newlyAlerted)
      appendIdsLocked(forKey: "\(keyPendingNativePrefix)\(userId)", ids: newlyAlerted)
      lock.unlock()
      completion(true)
    } else {
      completion(false)
    }
  }

  private func appendIdsLocked(forKey key: String, ids: [String]) {
    var list = defaults.stringArray(forKey: key) ?? []
    for id in ids {
      let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty && !list.contains(trimmed) {
        list.append(trimmed)
      }
    }
    if list.count > 300 {
      list = Array(list.suffix(300))
    }
    defaults.set(list, forKey: key)
  }

  private func fsString(_ fields: [String: Any], _ key: String) -> String {
    guard let map = fields[key] as? [String: Any],
          let str = map["stringValue"] as? String else { return "" }
    return str.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func fsBool(_ fields: [String: Any], _ key: String) -> Bool {
    guard let map = fields[key] as? [String: Any],
          let b = map["booleanValue"] as? Bool else { return false }
    return b
  }

  private func fsInt(_ fields: [String: Any], _ key: String) -> Int? {
    guard let map = fields[key] as? [String: Any],
          let s = map["integerValue"] as? String else { return nil }
    return Int(s)
  }

  private func fsStringArray(_ fields: [String: Any], _ key: String) -> [String] {
    guard let map = fields[key] as? [String: Any],
          let arrMap = map["arrayValue"] as? [String: Any],
          let vals = arrMap["values"] as? [[String: Any]] else { return [] }
    return vals.compactMap { ($0["stringValue"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  private func parseIso8601(_ raw: String) -> Date? {
    guard !raw.isEmpty else { return nil }
    if #available(iOS 11.0, *) {
      let f = ISO8601DateFormatter()
      f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let d = f.date(from: raw) { return d }
      f.formatOptions = [.withInternetDateTime]
      if let d = f.date(from: raw) { return d }
    }
    for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss"] {
      let df = DateFormatter()
      df.locale = Locale(identifier: "en_US_POSIX")
      df.dateFormat = fmt
      if let d = df.date(from: raw) { return d }
    }
    return nil
  }
}

// MARK: - PHPickerViewControllerDelegate (iOS 14+)

@available(iOS 14.0, *)
extension AppDelegate: PHPickerViewControllerDelegate {
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    picker.dismiss(animated: true) {
      guard let item = results.first else {
        self.completePicker(with: nil)
        return
      }
      let provider = item.itemProvider
      let suggestedName = provider.suggestedName

      if provider.hasItemConformingToTypeIdentifier(kUTTypeMovie as String) {
        provider.loadFileRepresentation(forTypeIdentifier: kUTTypeMovie as String) { url, _ in
          if let url = url {
            let ext = url.pathExtension.isEmpty ? "mov" : url.pathExtension
            let name = (suggestedName?.isEmpty == false) ? "\(suggestedName!).\(ext)" : url.lastPathComponent
            self.completePicker(with: self.copyUrlToLocalCache(sourceUrl: url, preferredName: name))
          } else {
            self.completePicker(with: nil)
          }
        }
        return
      }

      if provider.hasItemConformingToTypeIdentifier(kUTTypeImage as String) {
        provider.loadFileRepresentation(forTypeIdentifier: kUTTypeImage as String) { url, _ in
          if let url = url {
            let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension
            let name = (suggestedName?.isEmpty == false) ? "\(suggestedName!).\(ext)" : url.lastPathComponent
            if let mapped = self.copyUrlToLocalCache(sourceUrl: url, preferredName: name) {
              self.completePicker(with: mapped)
              return
            }
          }
          if provider.canLoadObject(ofClass: UIImage.self) {
            provider.loadObject(ofClass: UIImage.self) { obj, _ in
              if let img = obj as? UIImage {
                let name = (suggestedName?.isEmpty == false) ? "\(suggestedName!).jpg" : "lmt_gallery.jpg"
                self.completePicker(with: self.writeImageToLocalCache(image: img, name: name))
              } else {
                self.completePicker(with: nil)
              }
            }
          } else {
            self.completePicker(with: nil)
          }
        }
        return
      }

      self.completePicker(with: nil)
    }
  }
}

/// iOS background fetch coordinator querying Firestore REST for unseen
/// notifications while the screen is locked or app is backgrounded.
private final class LmtIosBackgroundSync {
  static let shared = LmtIosBackgroundSync()

  private let channelName = "com.example.lmt/background_sync"
  private let bgTaskId = "com.example.lmt.bgfetch"
  private let defaults = UserDefaults.standard
  private let lock = NSLock()

  private let keyLoggedIn = "lmt_bg_logged_in"
  private let keyUserId = "lmt_bg_user_id"
  private let keyApiKey = "lmt_bg_api_key"
  private let keyProjectId = "lmt_bg_project_id"
  private let keyIdToken = "lmt_bg_id_token"
  private let keyTokenTs = "lmt_bg_token_ts"
  private let keyAlertedPrefix = "lmt_bg_alerted_"
  private let keyPendingNativePrefix = "lmt_bg_pending_native_"

  private var methodChannel: FlutterMethodChannel?
  private var pendingLaunchPayload: String?
  private var registeredBgTasks = false

  private init() {}

  func registerChannel(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    methodChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handleMethodCall(call, result: result)
    }
  }

  func registerBackgroundTasks() {
    guard !registeredBgTasks else { return }
    registeredBgTasks = true
    if #available(iOS 13.0, *) {
      BGTaskScheduler.shared.register(forTaskWithIdentifier: bgTaskId, using: nil) { [weak self] task in
        guard let refreshTask = task as? BGAppRefreshTask else {
          task.setTaskCompleted(success: false)
          return
        }
        self?.handleAppRefresh(task: refreshTask)
      }
    }
  }

  func scheduleAppRefreshIfNeeded() {
    guard isSessionActive() else { return }
    if #available(iOS 13.0, *) {
      let request = BGAppRefreshTaskRequest(identifier: bgTaskId)
      request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
      try? BGTaskScheduler.shared.submit(request)
    }
  }

  @available(iOS 13.0, *)
  private func handleAppRefresh(task: BGAppRefreshTask) {
    scheduleAppRefreshIfNeeded()
    let session = URLSession.shared
    task.expirationHandler = {
      session.invalidateAndCancel()
    }
    pollAndAlertIfNeeded { _ in
      task.setTaskCompleted(success: true)
    }
  }

  func handleNotificationTapPayload(_ payload: String) {
    let trimmed = payload.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    if let channel = methodChannel {
      pendingLaunchPayload = nil
      DispatchQueue.main.async {
        channel.invokeMethod("onBackgroundNotificationTapped", arguments: trimmed)
      }
    } else {
      pendingLaunchPayload = trimmed
    }
  }

  func isSessionActive() -> Bool {
    return defaults.bool(forKey: keyLoggedIn)
      && !(defaults.string(forKey: keyUserId) ?? "").trimmingCharacters(in: .whitespaces).isEmpty
      && !(defaults.string(forKey: keyApiKey) ?? "").trimmingCharacters(in: .whitespaces).isEmpty
      && !(defaults.string(forKey: keyProjectId) ?? "").trimmingCharacters(in: .whitespaces).isEmpty
  }

  private func handleMethodCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let args = call.arguments as? [String: Any]
    switch call.method {
    case "syncSessionConfig":
      let loggedIn = (args?["isLoggedIn"] as? Bool) ?? false
      let userId = ((args?["userId"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      let apiKey = ((args?["apiKey"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      let projectId = ((args?["projectId"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      let idToken = (args?["idToken"] as? String)?.trimmingCharacters(in: .whitespaces)
      let alertedIds = (args?["alertedIds"] as? [String]) ?? []

      lock.lock()
      defaults.set(loggedIn && !userId.isEmpty, forKey: keyLoggedIn)
      defaults.set(userId, forKey: keyUserId)
      defaults.set(apiKey, forKey: keyApiKey)
      defaults.set(projectId, forKey: keyProjectId)
      if let token = idToken, !token.isEmpty {
        defaults.set(token, forKey: keyIdToken)
        defaults.set(Date().timeIntervalSince1970, forKey: keyTokenTs)
      } else if !loggedIn {
        defaults.removeObject(forKey: keyIdToken)
        defaults.removeObject(forKey: keyTokenTs)
      }
      if loggedIn && !userId.isEmpty && !alertedIds.isEmpty {
        appendIdsLocked(forKey: "\(keyAlertedPrefix)\(userId)", ids: alertedIds)
      }
      lock.unlock()

      if loggedIn && !userId.isEmpty {
        scheduleAppRefreshIfNeeded()
      } else if #available(iOS 13.0, *) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: bgTaskId)
      }
      result(nil)

    case "recordAlertedIds":
      let userId = ((args?["userId"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      let ids = (args?["ids"] as? [String]) ?? []
      if !userId.isEmpty && !ids.isEmpty {
        lock.lock()
        appendIdsLocked(forKey: "\(keyAlertedPrefix)\(userId)", ids: ids)
        lock.unlock()
      }
      result(nil)

    case "consumeNativeAlertedIds":
      let userId = ((args?["userId"] as? String) ?? "").trimmingCharacters(in: .whitespaces)
      var consumed: [String] = []
      if !userId.isEmpty {
        lock.lock()
        let key = "\(keyPendingNativePrefix)\(userId)"
        consumed = defaults.stringArray(forKey: key) ?? []
        defaults.removeObject(forKey: key)
        lock.unlock()
      }
      result(consumed)

    case "consumeLaunchPayload":
      let payload = pendingLaunchPayload
      pendingLaunchPayload = nil
      result(payload)

    case "isIgnoringBatteryOptimizations":
      result(true)

    case "requestIgnoreBatteryOptimizations":
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func pollAndAlertIfNeeded(completion: @escaping (Bool) -> Void) {
    guard isSessionActive() else {
      completion(false)
      return
    }
    let userId = (defaults.string(forKey: keyUserId) ?? "").trimmingCharacters(in: .whitespaces)
    let apiKey = (defaults.string(forKey: keyApiKey) ?? "").trimmingCharacters(in: .whitespaces)
    let projectId = (defaults.string(forKey: keyProjectId) ?? "").trimmingCharacters(in: .whitespaces)
    let storedToken = defaults.string(forKey: keyIdToken)
    let tokenAge = Date().timeIntervalSince1970 - defaults.double(forKey: keyTokenTs)

    let proceedWithToken: (String?) -> Void = { [weak self] token in
      guard let self = self, let token = token, !token.isEmpty else {
        completion(false)
        return
      }
      self.fetchNotifications(projectId: projectId, idToken: token) { items in
        guard let items = items, !items.isEmpty else {
          completion(false)
          return
        }
        self.dispatchUnseenNotifications(items, userId: userId, completion: completion)
      }
    }

    if let token = storedToken, !token.isEmpty, tokenAge < (45 * 60) {
      proceedWithToken(token)
    } else {
      refreshAnonymousToken(apiKey: apiKey, completion: proceedWithToken)
    }
  }

  private func refreshAnonymousToken(apiKey: String, completion: @escaping (String?) -> Void) {
    guard let url = URL(string: "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=\(apiKey)") else {
      completion(nil)
      return
    }
    var req = URLRequest(url: url, timeoutInterval: 10)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.httpBody = #"{"returnSecureToken":true}"#.data(using: .utf8)

    URLSession.shared.dataTask(with: req) { [weak self] data, resp, _ in
      guard let self = self,
            let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
            let data = data,
            let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let token = (obj["idToken"] as? String)?.trimmingCharacters(in: .whitespaces),
            !token.isEmpty else {
        completion(nil)
        return
      }
      self.lock.lock()
      self.defaults.set(token, forKey: self.keyIdToken)
      self.defaults.set(Date().timeIntervalSince1970, forKey: self.keyTokenTs)
      self.lock.unlock()
      completion(token)
    }.resume()
  }

  private func fetchNotifications(
    projectId: String,
    idToken: String,
    completion: @escaping ([[String: Any]]?) -> Void
  ) {
    guard let url = URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents:runQuery") else {
      completion(nil)
      return
    }
    var req = URLRequest(url: url, timeoutInterval: 10)
    req.httpMethod = "POST"
    req.setValue("application/json", forHTTPHeaderField: "Content-Type")
    req.setValue("Bearer \(idToken)", forHTTPHeaderField: "Authorization")
    let bodyObj: [String: Any] = [
      "structuredQuery": [
        "from": [["collectionId": "notifications"]],
        "orderBy": [["field": ["fieldPath": "dateTime"], "direction": "DESCENDING"]],
        "limit": 25
      ]
    ]
    req.httpBody = try? JSONSerialization.data(withJSONObject: bodyObj)

    URLSession.shared.dataTask(with: req) { data, resp, _ in
      guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode),
            let data = data,
            let entries = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
        completion(nil)
        return
      }
      let docs = entries.compactMap { $0["document"] as? [String: Any] }
      completion(docs)
    }.resume()
  }

  private func dispatchUnseenNotifications(
    _ docs: [[String: Any]],
    userId: String,
    completion: @escaping (Bool) -> Void
  ) {
    lock.lock()
    let alerted = Set(defaults.stringArray(forKey: "\(keyAlertedPrefix)\(userId)") ?? [])
    lock.unlock()

    let now = Date()
    var newlyAlerted: [String] = []
    let center = UNUserNotificationCenter.current()

    for doc in docs {
      guard let fields = doc["fields"] as? [String: Any] else { continue }
      let fallbackId = ((doc["name"] as? String) ?? "").components(separatedBy: "/").last ?? ""
      let id = (fsString(fields, "id").isEmpty ? fallbackId : fsString(fields, "id"))
      if id.isEmpty || alerted.contains(id) { continue }
      if fsBool(fields, "isRead") { continue }
      let excluded = fsStringArray(fields, "excludedMemberIds")
      if excluded.contains(userId) { continue }
      let targeted = fsStringArray(fields, "targetMemberIds")
      if !targeted.isEmpty && !targeted.contains(userId) { continue }
      guard let date = parseIso8601(fsString(fields, "dateTime")),
            abs(now.timeIntervalSince(date)) <= 24 * 60 * 60 else { continue }

      let title = fsString(fields, "title").isEmpty ? "L.M.T App" : fsString(fields, "title")
      let description = fsString(fields, "description")
      if title.isEmpty && description.isEmpty { continue }

      let category = fsString(fields, "category")
      let rawTone = fsString(fields, "tone")
      let tone = rawTone.isEmpty
        ? (category == "calendar" ? "calendar" : (category == "chat" ? "chatMessage" : "normal"))
        : rawTone

      var payloadDict: [String: Any] = ["notifId": id]
      if let tab = fsInt(fields, "targetTabIndex") { payloadDict["tab"] = tab }
      let groupId = fsString(fields, "targetGroupId")
      if !groupId.isEmpty { payloadDict["groupId"] = groupId }
      let eventId = fsString(fields, "targetEventId")
      if !eventId.isEmpty { payloadDict["eventId"] = eventId }
      let route = fsString(fields, "targetRoute")
      if !route.isEmpty { payloadDict["route"] = route }

      let payloadData = (try? JSONSerialization.data(withJSONObject: payloadDict)) ?? Data()
      let payloadStr = String(data: payloadData, encoding: .utf8) ?? ""

      let content = UNMutableNotificationContent()
      content.title = title
      content.body = description
      content.userInfo = ["lmt_notif_payload": payloadStr]
      if tone == "calendar",
         Bundle.main.url(forResource: "calendar_notifications", withExtension: "wav") != nil {
        content.sound = UNNotificationSound(named: UNNotificationSoundName("calendar_notifications.wav"))
      } else if Bundle.main.url(forResource: "normal_notifications", withExtension: "wav") != nil {
        content.sound = UNNotificationSound(named: UNNotificationSoundName("normal_notifications.wav"))
      } else {
        content.sound = .default
      }

      let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
      center.add(request, withCompletionHandler: nil)
      newlyAlerted.append(id)
    }

    if !newlyAlerted.isEmpty {
      lock.lock()
      appendIdsLocked(forKey: "\(keyAlertedPrefix)\(userId)", ids: newlyAlerted)
      appendIdsLocked(forKey: "\(keyPendingNativePrefix)\(userId)", ids: newlyAlerted)
      lock.unlock()
      completion(true)
    } else {
      completion(false)
    }
  }

  private func appendIdsLocked(forKey key: String, ids: [String]) {
    var list = defaults.stringArray(forKey: key) ?? []
    for id in ids {
      let trimmed = id.trimmingCharacters(in: .whitespacesAndNewlines)
      if !trimmed.isEmpty && !list.contains(trimmed) {
        list.append(trimmed)
      }
    }
    if list.count > 300 {
      list = Array(list.suffix(300))
    }
    defaults.set(list, forKey: key)
  }

  private func fsString(_ fields: [String: Any], _ key: String) -> String {
    guard let map = fields[key] as? [String: Any],
          let str = map["stringValue"] as? String else { return "" }
    return str.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private func fsBool(_ fields: [String: Any], _ key: String) -> Bool {
    guard let map = fields[key] as? [String: Any],
          let b = map["booleanValue"] as? Bool else { return false }
    return b
  }

  private func fsInt(_ fields: [String: Any], _ key: String) -> Int? {
    guard let map = fields[key] as? [String: Any],
          let s = map["integerValue"] as? String else { return nil }
    return Int(s)
  }

  private func fsStringArray(_ fields: [String: Any], _ key: String) -> [String] {
    guard let map = fields[key] as? [String: Any],
          let arrMap = map["arrayValue"] as? [String: Any],
          let vals = arrMap["values"] as? [[String: Any]] else { return [] }
    return vals.compactMap { ($0["stringValue"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) }
      .filter { !$0.isEmpty }
  }

  private func parseIso8601(_ raw: String) -> Date? {
    guard !raw.isEmpty else { return nil }
    if #available(iOS 11.0, *) {
      let f = ISO8601DateFormatter()
      f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let d = f.date(from: raw) { return d }
      f.formatOptions = [.withInternetDateTime]
      if let d = f.date(from: raw) { return d }
    }
    for fmt in ["yyyy-MM-dd'T'HH:mm:ss.SSSSSS", "yyyy-MM-dd'T'HH:mm:ss"] {
      let df = DateFormatter()
      df.locale = Locale(identifier: "en_US_POSIX")
      df.dateFormat = fmt
      if let d = df.date(from: raw) { return d }
    }
    return nil
  }
}
