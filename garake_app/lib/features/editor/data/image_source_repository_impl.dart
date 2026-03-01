// Fetches camera/gallery images through image_picker and returns raw bytes.
/*
Dependency Memo
- Depends on: image_source_repository.dart and app_exception.dart for contract/error flow.
- Requires methods: ImagePicker.pickImage().
- Provides methods: pickFromCamera(), pickFromGallery().
*/
import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/repositories/image_source_repository.dart';

class ImageSourceRepositoryImpl implements ImageSourceRepository {
  ImageSourceRepositoryImpl({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<Uint8List> pickFromCamera() {
    return _pick(ImageSource.camera);
  }

  @override
  Future<Uint8List> pickFromGallery() {
    return _pick(ImageSource.gallery);
  }

  Future<Uint8List> _pick(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 100,
    );
    if (file == null) {
      throw const AppException('画像の選択をキャンセルしました。');
    }
    return file.readAsBytes();
  }
}
