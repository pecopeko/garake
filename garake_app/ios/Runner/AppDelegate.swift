import AVFoundation
import CoreImage
import Flutter
import UIKit

// Boots Flutter and exposes disposable-camera video rendering to Dart.
/*
Dependency Memo
- Depends on: Flutter method channels plus AVFoundation/CoreImage for native video export.
- Requires methods: FlutterMethodChannel.setMethodCallHandler(), AVAssetExportSession.exportAsynchronously(), AVMutableVideoComposition(asset:applyingCIFiltersWithHandler:), and FileManager temporaryDirectory APIs.
- Provides methods: application(_:didFinishLaunchingWithOptions:), GarakeVideoStyleRenderer.handle(call:result:).
*/
@main
@objc class AppDelegate: FlutterAppDelegate {
  private let videoStyleChannelName = "garake/video_style_renderer"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let renderer = GarakeVideoStyleRenderer()
      let channel = FlutterMethodChannel(
        name: videoStyleChannelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        renderer.handle(call: call, result: result)
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

private final class GarakeVideoStyleRenderer {
  private let fileManager = FileManager.default
  private let targetFPS: Int32 = 12
  private let maxDimension: CGFloat = 480
  private static var messageLocale: String {
    let identifier = Locale.preferredLanguages.first ?? Locale.current.identifier
    if identifier.hasPrefix("ja") {
      return "ja"
    }
    if identifier.hasPrefix("zh") {
      return "zh"
    }
    return "en"
  }
  private lazy var faceDetector: CIDetector? = {
    CIDetector(
      ofType: CIDetectorTypeFace,
      context: nil,
      options: [
        CIDetectorAccuracy: CIDetectorAccuracyLow,
        CIDetectorTracking: true,
        CIDetectorMinFeatureSize: 0.12,
      ]
    )
  }()

  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "renderDisposableCameraVideo" else {
      result(FlutterMethodNotImplemented)
      return
    }

    guard
      let arguments = call.arguments as? [String: Any],
      let inputPath = arguments["inputPath"] as? String,
      !inputPath.isEmpty
    else {
      result(
        FlutterError(
          code: "bad_args",
          message: Self.localizedMessage(
            ja: "動画ファイルの指定が不正です。",
            en: "The video file path is invalid.",
            zh: "视频文件路径无效。"
          ),
          details: nil
        )
      )
      return
    }

    renderDisposableCameraVideo(inputPath: inputPath, result: result)
  }

  private func renderDisposableCameraVideo(
    inputPath: String,
    result: @escaping FlutterResult
  ) {
    let inputURL = URL(fileURLWithPath: inputPath)
    guard fileManager.fileExists(atPath: inputURL.path) else {
      result(
        FlutterError(
          code: "missing_input",
          message: Self.localizedMessage(
            ja: "加工前の動画が見つかりません。",
            en: "The source video could not be found.",
            zh: "未找到原始视频。"
          ),
          details: nil
        )
      )
      return
    }

    let asset = AVURLAsset(url: inputURL)
    guard let videoTrack = asset.tracks(withMediaType: .video).first else {
      result(
        FlutterError(
          code: "missing_video_track",
          message: Self.localizedMessage(
            ja: "動画トラックを読み込めませんでした。",
            en: "The video track could not be loaded.",
            zh: "无法读取视频轨道。"
          ),
          details: nil
        )
      )
      return
    }

    guard
      let exportSession = AVAssetExportSession(
        asset: asset,
        presetName: AVAssetExportPresetMediumQuality
      )
    else {
      result(
        FlutterError(
          code: "export_unavailable",
          message: Self.localizedMessage(
            ja: "端末側で動画の再圧縮を開始できませんでした。",
            en: "Video recompression could not start on this device.",
            zh: "无法在此设备上启动视频重新压缩。"
          ),
          details: nil
        )
      )
      return
    }

    guard let outputFileType = bestOutputType(for: exportSession) else {
      result(
        FlutterError(
          code: "unsupported_output",
          message: Self.localizedMessage(
            ja: "動画の書き出し形式を決められませんでした。",
            en: "The video export format could not be determined.",
            zh: "无法确定视频导出格式。"
          ),
          details: nil
        )
      )
      return
    }

    let outputURL = makeOutputURL(for: outputFileType)
    removeFileIfNeeded(at: outputURL)

    let videoComposition = AVMutableVideoComposition(
      asset: asset,
      applyingCIFiltersWithHandler: { [weak self] request in
        self?.finishFiltering(request: request)
      }
    )
    videoComposition.renderSize = scaledRenderSize(for: orientedSize(of: videoTrack))
    videoComposition.frameDuration = CMTime(value: 1, timescale: targetFPS)

    exportSession.outputURL = outputURL
    exportSession.outputFileType = outputFileType
    exportSession.videoComposition = videoComposition
    exportSession.shouldOptimizeForNetworkUse = false

    exportSession.exportAsynchronously { [weak self] in
      DispatchQueue.main.async {
        guard let self = self else {
          result(
            FlutterError(
              code: "renderer_released",
              message: Self.localizedMessage(
                ja: "動画の加工処理が途中で破棄されました。",
                en: "The video processing task was released before finishing.",
                zh: "视频处理在完成前被释放了。"
              ),
              details: nil
            )
          )
          return
        }

        switch exportSession.status {
        case .completed:
          result(outputURL.path)
        case .failed, .cancelled:
          self.removeFileIfNeeded(at: outputURL)
          result(
            FlutterError(
              code: "export_failed",
              message: Self.localizedMessage(
                ja: "動画をガラ写風に加工できませんでした。",
                en: "Could not finish the garasha video style.",
                zh: "无法完成 garasha 视频风格处理。"
              ),
              details: exportSession.error?.localizedDescription
            )
          )
        default:
          self.removeFileIfNeeded(at: outputURL)
          result(
            FlutterError(
              code: "export_incomplete",
              message: Self.localizedMessage(
                ja: "動画の加工が完了しませんでした。",
                en: "The video processing did not finish.",
                zh: "视频处理未能完成。"
              ),
              details: exportSession.error?.localizedDescription
            )
          )
        }
      }
    }
  }

  private func finishFiltering(request: AVAsynchronousCIImageFilteringRequest) {
    let extent = request.sourceImage.extent
    let sourceImage = request.sourceImage.clampedToExtent()
    var image = applyCuteFaceBeauty(to: sourceImage, extent: extent)

    image = image.applyingFilter(
      "CIColorControls",
      parameters: [
        kCIInputSaturationKey: 0.82,
        kCIInputBrightnessKey: 0.01,
        kCIInputContrastKey: 0.92,
      ]
    )
    image = image.applyingFilter(
      "CIBloom",
      parameters: [
        kCIInputRadiusKey: 1.8,
        kCIInputIntensityKey: 0.06,
      ]
    )

    let grain = grainImage(for: extent)
    image = grain.applyingFilter(
      "CISoftLightBlendMode",
      parameters: [kCIInputBackgroundImageKey: image]
    )
    image = image.applyingFilter(
      "CIUnsharpMask",
      parameters: [
        kCIInputRadiusKey: 1.0,
        kCIInputIntensityKey: 0.24,
      ]
    )
    image = image.applyingFilter(
      "CIVignette",
      parameters: [
        kCIInputIntensityKey: 0.32,
        kCIInputRadiusKey: 1.25,
      ]
    )

    request.finish(with: image.cropped(to: extent), context: nil)
  }

  private func applyCuteFaceBeauty(to image: CIImage, extent: CGRect) -> CIImage {
    let faces = detectedFaces(in: image)
    guard !faces.isEmpty else {
      return image
    }

    let warped = applyCuteWarp(to: image, faces: faces).cropped(to: extent)
    let softened = warped
      .applyingFilter(
        "CIGaussianBlur",
        parameters: [kCIInputRadiusKey: 1.5]
      )
      .cropped(to: extent)
    let brightened = warped
      .applyingFilter(
        "CIColorControls",
        parameters: [
          kCIInputSaturationKey: 1.03,
          kCIInputBrightnessKey: 0.008,
          kCIInputContrastKey: 0.99,
        ]
      )
      .applyingFilter(
        "CIExposureAdjust",
        parameters: [kCIInputEVKey: 0.06]
      )
      .cropped(to: extent)

    let skinMask = faceMask(
      for: faces,
      extent: extent,
      widthScale: 1.08,
      heightScale: 1.16
    )
    let glowMask = faceMask(
      for: faces,
      extent: extent,
      widthScale: 0.88,
      heightScale: 0.96
    )

    let smoothed = softened
      .applyingFilter(
        "CIBlendWithMask",
        parameters: [
          kCIInputBackgroundImageKey: image,
          kCIInputMaskImageKey: skinMask,
        ]
      )
      .cropped(to: extent)
    let lifted = brightened
      .applyingFilter(
        "CIBlendWithMask",
        parameters: [
          kCIInputBackgroundImageKey: smoothed,
          kCIInputMaskImageKey: glowMask,
        ]
      )
      .cropped(to: extent)

    return lifted
  }

  private func applyCuteWarp(to image: CIImage, faces: [CIFaceFeature]) -> CIImage {
    var warped = image
    for face in faces {
      let cheekRadius = max(face.bounds.width * 0.18, 18)
      let cheekY = face.bounds.midY
      let leftCheek = CGPoint(x: face.bounds.minX + face.bounds.width * 0.20, y: cheekY)
      let rightCheek = CGPoint(x: face.bounds.maxX - face.bounds.width * 0.20, y: cheekY)
      let chinCenter = CGPoint(x: face.bounds.midX, y: face.bounds.minY + face.bounds.height * 0.12)

      warped = warped.applyingFilter(
        "CIPinchDistortion",
        parameters: ["inputCenter": CIVector(cgPoint: leftCheek), kCIInputRadiusKey: cheekRadius, kCIInputScaleKey: 0.22]
      )
      warped = warped.applyingFilter(
        "CIPinchDistortion",
        parameters: ["inputCenter": CIVector(cgPoint: rightCheek), kCIInputRadiusKey: cheekRadius, kCIInputScaleKey: 0.22]
      )
      warped = warped.applyingFilter(
        "CIPinchDistortion",
        parameters: ["inputCenter": CIVector(cgPoint: chinCenter), kCIInputRadiusKey: max(face.bounds.width * 0.22, 22), kCIInputScaleKey: 0.12]
      )
    }
    return warped
  }

  private func detectedFaces(in image: CIImage) -> [CIFaceFeature] {
    guard let faceDetector else {
      return []
    }

    return faceDetector.features(in: image).compactMap { feature in
      feature as? CIFaceFeature
    }
  }

  private func faceMask(
    for faces: [CIFaceFeature],
    extent: CGRect,
    widthScale: CGFloat,
    heightScale: CGFloat
  ) -> CIImage {
    var mask = CIImage(color: CIColor.clear).cropped(to: extent)
    for face in faces {
      let expandedBounds = CGRect(
        x: face.bounds.minX - face.bounds.width * (widthScale - 1) * 0.5,
        y: face.bounds.minY - face.bounds.height * (heightScale - 1) * 0.46,
        width: face.bounds.width * widthScale,
        height: face.bounds.height * heightScale
      )
      let radius0 = max(expandedBounds.width, expandedBounds.height) * 0.28
      let radius1 = max(expandedBounds.width, expandedBounds.height) * 0.56
      let gradient = CIFilter(
        name: "CIRadialGradient",
        parameters: [
          "inputCenter": CIVector(
            x: expandedBounds.midX,
            y: expandedBounds.midY
          ),
          "inputRadius0": radius0,
          "inputRadius1": radius1,
          "inputColor0": CIColor(red: 1, green: 1, blue: 1, alpha: 1),
          "inputColor1": CIColor(red: 0, green: 0, blue: 0, alpha: 0),
        ]
      )?.outputImage?.cropped(to: extent)
        ?? CIImage(color: CIColor.clear).cropped(to: extent)

      mask = gradient
        .applyingFilter(
          "CISourceOverCompositing",
          parameters: [kCIInputBackgroundImageKey: mask]
        )
        .cropped(to: extent)
    }
    return mask
  }

  private func grainImage(for extent: CGRect) -> CIImage {
    let random = CIFilter(name: "CIRandomGenerator")?.outputImage?.cropped(to: extent)
      ?? CIImage(color: CIColor.clear).cropped(to: extent)

    return random.applyingFilter(
      "CIColorMatrix",
      parameters: [
        "inputRVector": CIVector(x: 0.18, y: 0, z: 0, w: 0),
        "inputGVector": CIVector(x: 0, y: 0.18, z: 0, w: 0),
        "inputBVector": CIVector(x: 0, y: 0, z: 0.18, w: 0),
        "inputAVector": CIVector(x: 0, y: 0, z: 0, w: 0.06),
        "inputBiasVector": CIVector(x: 0.42, y: 0.42, z: 0.42, w: 0),
      ]
    )
    .cropped(to: extent)
  }

  private func orientedSize(of track: AVAssetTrack) -> CGSize {
    let transformed = track.naturalSize.applying(track.preferredTransform)
    return CGSize(width: abs(transformed.width), height: abs(transformed.height))
  }

  private func scaledRenderSize(for sourceSize: CGSize) -> CGSize {
    guard sourceSize.width > 0, sourceSize.height > 0 else {
      return CGSize(width: 180, height: 320)
    }

    let scale = min(1, maxDimension / max(sourceSize.width, sourceSize.height))
    let width = max(120, Int((sourceSize.width * scale).rounded(.down)))
    let height = max(160, Int((sourceSize.height * scale).rounded(.down)))

    return CGSize(
      width: evenPixelValue(width),
      height: evenPixelValue(height)
    )
  }

  private func evenPixelValue(_ value: Int) -> CGFloat {
    let evenValue = value % 2 == 0 ? value : value - 1
    return CGFloat(max(2, evenValue))
  }

  private func bestOutputType(for exportSession: AVAssetExportSession) -> AVFileType? {
    if exportSession.supportedFileTypes.contains(.mp4) {
      return .mp4
    }
    if exportSession.supportedFileTypes.contains(.mov) {
      return .mov
    }
    return exportSession.supportedFileTypes.first
  }

  private static func localizedMessage(ja: String, en: String, zh: String) -> String {
    switch messageLocale {
    case "ja":
      return ja
    case "zh":
      return zh
    default:
      return en
    }
  }

  private func makeOutputURL(for outputType: AVFileType) -> URL {
    let fileExtension = outputType == .mov ? "mov" : "mp4"
    let fileName = "garasha_disposable_\(Int(Date().timeIntervalSince1970 * 1000)).\(fileExtension)"
    return fileManager.temporaryDirectory.appendingPathComponent(fileName)
  }

  private func removeFileIfNeeded(at url: URL) {
    if fileManager.fileExists(atPath: url.path) {
      try? fileManager.removeItem(at: url)
    }
  }
}
