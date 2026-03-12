// Holds app copy and locale helpers for Japanese, English, and Simplified Chinese.
/*
Dependency Memo
- Depends on: Flutter localization APIs and intl.dart for app-wide locale propagation.
- Requires methods: Localizations.of(), SynchronousFuture(), Intl.defaultLocale.
- Provides methods: AppLocalizations.of(), AppLocalizations.current, AppLocalizations.delegate, BuildContext.l10n, and locale-aware UI text/date helpers.
*/
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

part 'app_localizations_values.dart';

class AppLocalizations {
  AppLocalizations(Locale locale) : locale = _normalize(locale);

  final Locale locale;

  static AppLocalizations _current = AppLocalizations(const Locale('ja'));

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = <Locale>[
    Locale('ja'),
    Locale('en'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  ];

  static AppLocalizations get current => _current;

  static AppLocalizations of(BuildContext context) {
    final AppLocalizations? localizations = Localizations.of<AppLocalizations>(
      context,
      AppLocalizations,
    );
    assert(localizations != null, 'AppLocalizations is not available.');
    return localizations!;
  }

  static Locale _normalize(Locale locale) {
    switch (locale.languageCode) {
      case 'ja':
        return const Locale('ja');
      case 'zh':
        return const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans');
      default:
        return const Locale('en');
    }
  }

  String get _languageKey =>
      locale.languageCode == 'zh' ? 'zh' : locale.languageCode;

  bool get isJapanese => _languageKey == 'ja';

  String _text(String key) => _localizedText[_languageKey]![key]!;

  String get appName => _text('appName');
  String get homeBrandBanner => '✿ $appName ✿';
  String get brandWordmark => appName;
  String get shareSubject => appName;
  String get exportFileStem => 'garasha';
  String get statusCarrierMark => _text('statusCarrierMark');
  String get confirmKeyLabel => _text('confirmKeyLabel');
  String get stickerSelectionPrefix => _text('stickerSelectionPrefix');

  String get homeTakePhoto => _text('homeTakePhoto');
  String get homeTakeVideo => _text('homeTakeVideo');
  String get homeEditPhoto => _text('homeEditPhoto');

  String get keyHome => _text('keyHome');
  String get keyBack => _text('keyBack');
  String get keySticker => _text('keySticker');
  String get keyDecorate => _text('keyDecorate');
  String get keySave => _text('keySave');
  String get keyShare => _text('keyShare');
  String get keySaveShare => _text('keySaveShare');
  String get keyDisabled => _text('keyDisabled');

  String get modeReady => _text('modeReady');
  String get modeMove => _text('modeMove');
  String get modeScale => _text('modeScale');

  String get busyLoading => _text('busyLoading');
  String get busyProcessing => _text('busyProcessing');
  String get busyOpeningCamera => _text('busyOpeningCamera');
  String get busyOpeningVideoCamera => _text('busyOpeningVideoCamera');
  String get busyReadingCapturedPhoto => _text('busyReadingCapturedPhoto');
  String get busyOpeningAlbum => _text('busyOpeningAlbum');
  String get busyProcessingPhoto => _text('busyProcessingPhoto');
  String get busyProcessingAlbumPhoto => _text('busyProcessingAlbumPhoto');
  String get busyPreparingFaceRetouch => _text('busyPreparingFaceRetouch');
  String get busyPreparingSaveImage => _text('busyPreparingSaveImage');
  String get busyPreparingShareImage => _text('busyPreparingShareImage');
  String get busyAutoSavingVideo => _text('busyAutoSavingVideo');
  String get busySavingVideo => _text('busySavingVideo');
  String get busyOpeningShareSheet => _text('busyOpeningShareSheet');
  String get busyDeletingVideo => _text('busyDeletingVideo');

  String get panelTitleAddSticker => _text('panelTitleAddSticker');
  String get panelTitleFaceRetouch => _text('panelTitleFaceRetouch');
  String get panelTitleVideoMenu => _text('panelTitleVideoMenu');
  String get panelTitleEditMenu => _text('panelTitleEditMenu');
  String get menuHintTapSelect => _text('menuHintTapSelect');

  String get livePhotoAction => _text('livePhotoAction');
  String get liveVideoAction => _text('liveVideoAction');
  String get liveStopAction => _text('liveStopAction');
  String get liveRetryVideoAction => _text('liveRetryVideoAction');
  String get liveSelectionShot => _text('liveSelectionShot');
  String get liveSelectionStandby => _text('liveSelectionStandby');
  String get liveSelectionError => _text('liveSelectionError');
  String get liveSelectionRecording => _text('liveSelectionRecording');
  String get liveSelectionClip => _text('liveSelectionClip');
  String get liveStatusPhoto => _text('liveStatusPhoto');
  String get liveStatusVideo => _text('liveStatusVideo');
  String get liveStatusClipReady => _text('liveStatusClipReady');
  String get liveHintTakePhoto => _text('liveHintTakePhoto');
  String get liveHintRecordVideo => _text('liveHintRecordVideo');
  String get liveHintStopRecording => _text('liveHintStopRecording');
  String get liveHintSaveOrShare => _text('liveHintSaveOrShare');
  String get liveShellModeCamera => _text('liveShellModeCamera');
  String get liveShellModeVideo => _text('liveShellModeVideo');

  String get cameraInitializingLabel => _text('cameraInitializingLabel');
  String get recordingStartedMessage => _text('recordingStartedMessage');
  String get shareSheetOpenedMessage => _text('shareSheetOpenedMessage');
  String get recordedVideoDeletedMessage =>
      _text('recordedVideoDeletedMessage');
  String get genericVideoActionFailedMessage =>
      _text('genericVideoActionFailedMessage');
  String get genericVideoProcessFailedMessage =>
      _text('genericVideoProcessFailedMessage');
  String get imageLoadedMessage => _text('imageLoadedMessage');
  String get imageLoadFailedMessage => _text('imageLoadFailedMessage');
  String get selectPhotoFirstMessage => _text('selectPhotoFirstMessage');
  String get stickerAddedMessage => _text('stickerAddedMessage');
  String get selectStickerToDeleteMessage =>
      _text('selectStickerToDeleteMessage');
  String get stickerDeletedMessage => _text('stickerDeletedMessage');
  String get addStickerFirstMessage => _text('addStickerFirstMessage');
  String get stickerSelectedMessage => _text('stickerSelectedMessage');
  String get moveModeMessage => _text('moveModeMessage');
  String get scaleModeMessage => _text('scaleModeMessage');
  String get faceRetouchFailedMessage => _text('faceRetouchFailedMessage');
  String get faceRetouchNoFaceMessage => _text('faceRetouchNoFaceMessage');
  String get saveFailedMessage => _text('saveFailedMessage');
  String get shareFailedMessage => _text('shareFailedMessage');
  String get sharePhotoText => _text('sharePhotoText');
  String get shareVideoText => _text('shareVideoText');

  String get savePermissionDeniedMessage =>
      _text('savePermissionDeniedMessage');
  String get savePhotoFailedMessage => _text('savePhotoFailedMessage');
  String get saveVideoMissingMessage => _text('saveVideoMissingMessage');
  String get saveVideoFailedMessage => _text('saveVideoFailedMessage');
  String get shareVideoMissingMessage => _text('shareVideoMissingMessage');
  String get imagePickCanceledMessage => _text('imagePickCanceledMessage');
  String get videoResultMissingMessage => _text('videoResultMissingMessage');
  String get videoRenderFailedMessage => _text('videoRenderFailedMessage');
  String get unsupportedImageFormatMessage =>
      _text('unsupportedImageFormatMessage');

  String get photoModeOnlyMessage => _text('photoModeOnlyMessage');
  String get videoModeOnlyMessage => _text('videoModeOnlyMessage');
  String get takePhotoFailedMessage => _text('takePhotoFailedMessage');
  String get startRecordingFailedMessage =>
      _text('startRecordingFailedMessage');
  String get recordingNotStartedMessage => _text('recordingNotStartedMessage');
  String get finishVideoStyleFailedMessage =>
      _text('finishVideoStyleFailedMessage');
  String get noCameraFoundMessage => _text('noCameraFoundMessage');
  String get openVideoCameraFailedMessage =>
      _text('openVideoCameraFailedMessage');
  String get openCameraFailedMessage => _text('openCameraFailedMessage');
  String get cameraNotReadyMessage => _text('cameraNotReadyMessage');
  String get recordVideoFirstMessage => _text('recordVideoFirstMessage');
  String get cannotSwitchWhileRecordingMessage =>
      _text('cannotSwitchWhileRecordingMessage');
  String get cannotSwitchWithUnsavedClipMessage =>
      _text('cannotSwitchWithUnsavedClipMessage');

  String get stickerHeartRed => _text('stickerHeartRed');
  String get stickerHeartPink => _text('stickerHeartPink');
  String get stickerStarYellow => _text('stickerStarYellow');
  String get stickerStarOrange => _text('stickerStarOrange');
  String get stickerSparkleGold => _text('stickerSparkleGold');
  String get stickerSparklePink => _text('stickerSparklePink');

  String get menuSave => _text('menuSave');
  String get menuShare => _text('menuShare');
  String get menuDelete => _text('menuDelete');
  String get faceRetouchOff => _text('faceRetouchOff');
  String get faceRetouchCute => _text('faceRetouchCute');
  String get faceRetouchMenuLabel => _text('faceRetouchMenuLabel');

  String get noneShort => _text('noneShort');

  String lensDirectionLabel({required bool isFront}) {
    return isFront ? _text('lensFront') : _text('lensBack');
  }

  String lensToggleLabel({required bool isFront}) {
    return isFront ? _text('lensToggleFront') : _text('lensToggleBack');
  }

  String switchedLensMessage({required bool isFront}) {
    final String lensLabel = lensDirectionLabel(isFront: isFront);
    switch (_languageKey) {
      case 'ja':
        return '$lensLabelに切り替えました。';
      case 'zh':
        return '已切换到$lensLabel。';
      default:
        return 'Switched to $lensLabel.';
    }
  }

  String unavailableCameraMessage({required bool isFront}) {
    return isFront
        ? _text('frontCameraUnavailableMessage')
        : _text('backCameraUnavailableMessage');
  }

  String faceRetouchLabel({required bool enabled}) {
    return enabled ? faceRetouchCute : faceRetouchOff;
  }

  String faceRetouchUnchangedMessage(String label) {
    switch (_languageKey) {
      case 'ja':
        return '顔加工は $label のままです。';
      case 'zh':
        return '脸部修饰保持为 $label。';
      default:
        return 'Face retouch is already set to $label.';
    }
  }

  String faceRetouchUpdatedMessage(String label) {
    switch (_languageKey) {
      case 'ja':
        return '顔加工を $label にしました。';
      case 'zh':
        return '脸部修饰已切换为 $label。';
      default:
        return 'Face retouch set to $label.';
    }
  }

  String videoAutoSaveRetryMessage(String errorMessage) {
    switch (_languageKey) {
      case 'ja':
        return '$errorMessage 保存/シェアからやり直せます。';
      case 'zh':
        return '$errorMessage 你可以在保存/分享里重试。';
      default:
        return '$errorMessage You can retry from Save/Share.';
    }
  }

  String get videoAutoSaveRetryFallbackMessage =>
      _text('videoAutoSaveRetryFallbackMessage');

  String stickerSelectionLabel({int? selectedIndex, required int total}) {
    final String prefix = stickerSelectionPrefix;
    if (total == 0) {
      return '$prefix:0/0';
    }
    if (selectedIndex == null) {
      return '$prefix:$noneShort/$total';
    }
    return '$prefix:$selectedIndex/$total';
  }

  String formatHomeDate(DateTime date) {
    return "${formatDateStamp(date)} (${weekdayShort(date.weekday)})";
  }

  String formatLaunchDate(DateTime date) {
    return formatDateStamp(date);
  }

  String formatLaunchWeekday(DateTime date) {
    return '(${weekdayShort(date.weekday)})';
  }

  String formatDateStamp(DateTime date) {
    final String year = (date.year % 100).toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return "'$year.$month.$day";
  }

  String weekdayShort(int weekday) => _weekdays[_languageKey]![weekday - 1];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return <String>{'ja', 'en', 'zh'}.contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) {
    final AppLocalizations localizations = AppLocalizations(locale);
    AppLocalizations._current = localizations;
    Intl.defaultLocale = switch (localizations.locale.languageCode) {
      'ja' => 'ja',
      'zh' => 'zh_Hans',
      _ => 'en',
    };
    return SynchronousFuture<AppLocalizations>(localizations);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;
  }
}

extension AppLocalizationsBuildContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
