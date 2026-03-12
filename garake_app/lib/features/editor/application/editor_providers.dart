// Registers Riverpod providers for editor dependencies, face detection, state controller, and video styling.
/*
Dependency Memo
- Depends on: data implementations, core processors, editor_image_pipeline.dart, and video style renderer abstractions.
- Requires methods: concrete repository constructors.
- Provides methods: editorControllerProvider and dependency providers.
*/
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/image_processing/garake_filter_engine_impl.dart';
import '../../../core/image_processing/sticker_composer_impl.dart';
import '../data/mlkit_face_feature_detector_impl.dart';
import '../data/export_repository_impl.dart';
import '../data/image_source_repository_impl.dart';
import '../data/platform_video_style_renderer_impl.dart';
import '../domain/entities/filter_config.dart';
import '../domain/repositories/export_repository.dart';
import '../domain/repositories/face_feature_detector.dart';
import '../domain/repositories/filter_engine.dart';
import '../domain/repositories/image_source_repository.dart';
import '../domain/repositories/sticker_composer.dart';
import '../domain/repositories/video_style_renderer.dart';
import 'editor_controller.dart';
import 'editor_image_pipeline.dart';
import 'editor_state.dart';

final filterConfigProvider = Provider<FilterConfig>((_) => FilterConfig.v1);

final imageSourceRepositoryProvider = Provider<ImageSourceRepository>(
  (_) => ImageSourceRepositoryImpl(),
);

final filterEngineProvider = Provider<FilterEngine>(
  (_) => GarakeFilterEngineImpl(),
);

final faceFeatureDetectorProvider = Provider<FaceFeatureDetector>((ref) {
  final FaceFeatureDetector detector = MlKitFaceFeatureDetectorImpl();
  ref.onDispose(() {
    detector.dispose();
  });
  return detector;
});

final editorImagePipelineProvider = Provider<EditorImagePipeline>((ref) {
  return EditorImagePipeline(
    filterEngine: ref.read(filterEngineProvider),
    faceFeatureDetector: ref.read(faceFeatureDetectorProvider),
    filterConfig: ref.read(filterConfigProvider),
  );
});

final stickerComposerProvider = Provider<StickerComposer>(
  (_) => StickerComposerImpl(),
);

final exportRepositoryProvider = Provider<ExportRepository>(
  (_) => ExportRepositoryImpl(),
);

final videoStyleRendererProvider = Provider<VideoStyleRenderer>(
  (_) => PlatformVideoStyleRendererImpl(),
);

final editorControllerProvider =
    StateNotifierProvider<EditorController, EditorState>((ref) {
      return EditorController(
        imageSourceRepository: ref.read(imageSourceRepositoryProvider),
        imagePipeline: ref.read(editorImagePipelineProvider),
        stickerComposer: ref.read(stickerComposerProvider),
        exportRepository: ref.read(exportRepositoryProvider),
        filterConfig: ref.read(filterConfigProvider),
      );
    });
