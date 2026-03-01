// Declares camera/gallery byte acquisition for editor sessions.
/*
Dependency Memo
- Depends on: dart:typed_data for image payloads.
- Requires methods: none.
- Provides methods: pickFromCamera(), pickFromGallery().
*/
import 'dart:typed_data';

abstract class ImageSourceRepository {
  Future<Uint8List> pickFromCamera();

  Future<Uint8List> pickFromGallery();
}
