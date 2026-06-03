abstract class VideoIdentifiable {
  String get videoUrl;

  String? get thumbnailUrl;

  bool get isReadyToPlay;

  bool get hasPlaybackError;
}
