// Declares platform video restyling so recorded clips can be degraded consistently before export.
/*
Dependency Memo
- Depends on: none.
- Requires methods: none.
- Provides methods: renderDisposableCameraVideo().
*/
abstract class VideoStyleRenderer {
  Future<String> renderDisposableCameraVideo(String inputPath);
}
