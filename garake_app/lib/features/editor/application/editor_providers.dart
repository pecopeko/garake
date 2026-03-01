// Registers Riverpod providers for editor dependencies and state controller.
/*
Dependency Memo
- Depends on: data implementations and core processors.
- Requires methods: concrete repository constructors.
- Provides methods: editorControllerProvider and dependency providers.
*/
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/image_processing/garake_filter_engine_impl.dart';
import '../../../core/image_processing/sticker_composer_impl.dart';
import '../data/export_repository_impl.dart';
import '../data/image_source_repository_impl.dart';
import '../domain/entities/filter_config.dart';
import '../domain/repositories/export_repository.dart';
import '../domain/repositories/filter_engine.dart';
import '../domain/repositories/image_source_repository.dart';
import '../domain/repositories/sticker_composer.dart';
import 'editor_controller.dart';
import 'editor_state.dart';

final filterConfigProvider = Provider<FilterConfig>((_) => FilterConfig.v1);

final imageSourceRepositoryProvider = Provider<ImageSourceRepository>(
  (_) => ImageSourceRepositoryImpl(),
);

final filterEngineProvider = Provider<FilterEngine>(
  (_) => GarakeFilterEngineImpl(),
);

final stickerComposerProvider = Provider<StickerComposer>(
  (_) => StickerComposerImpl(),
);

final exportRepositoryProvider = Provider<ExportRepository>(
  (_) => ExportRepositoryImpl(),
);

final editorControllerProvider =
    StateNotifierProvider<EditorController, EditorState>((ref) {
      return EditorController(
        imageSourceRepository: ref.read(imageSourceRepositoryProvider),
        filterEngine: ref.read(filterEngineProvider),
        stickerComposer: ref.read(stickerComposerProvider),
        exportRepository: ref.read(exportRepositoryProvider),
        filterConfig: ref.read(filterConfigProvider),
      );
    });
