# safe_video_player

Flutter video player built on top of [`video_player`](https://pub.dev/packages/video_player) with an internal operation queue that prevents race conditions on rapid play/pause/seek calls. Includes a ready-to-use multi-video vertical feed (TikTok-style) with automatic pre-caching and smart disposal.

## Features

- **Race-condition-safe controller** — every `play`, `pause`, `seekTo`, `initialize`, and `dispose` call is serialized through an internal queue. Rapid UI interactions never corrupt playback state.
- **Single-video widget** — thumbnail → video transition, tap to play/pause, swipe gestures, auto-detects horizontal vs. vertical aspect ratio.
- **Multi-video vertical feed** — `PageView`-based feed that auto-plays the focused video, pre-caches the 5 surrounding videos, and disposes distant ones.
- **Built-in UI controls** — mute toggle, play/pause overlay, progress/buffer slider, back button.
- **Overlay builder** — inject any custom UI (likes, comments, captions) over each video in the feed.

## Getting started

Add the dependency:

```yaml
dependencies:
  safe_video_player:
    git:
      url: https://github.com/rasheeqzaman/safe-video-player.git
      path: safe_video_player
```

iOS — add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
</dict>
```

Android — no extra steps required.

## Usage

### Single video

```dart
import 'package:safe_video_player/safe_video_player.dart';

// 1. Create and initialize the controller
final controller = SafeVideoPlayerController.networkUrl(
  Uri.parse('https://example.com/video.mp4'),
);
await controller.initialize();

// 2. Render
VideoPlayerWidget(
  videoController: controller,
  thumbnailUrl: 'https://example.com/thumb.jpg',
  onTapPlayPause: () { /* called after each tap */ },
  onChangePlayerValue: () { /* called on position/state change */ },
  onInitVideo: () { /* called once on widget init */ },
  onSwipeRight: () { /* called on right swipe */ },
  onSwipeLeft: () { /* called on left swipe */ },
);

// 3. Dispose
await controller.dispose();
```

### Multi-video feed

**Step 1 — implement `VideoIdentifiable` on your model:**

```dart
class MyVideo implements VideoIdentifiable {
  final String url;
  final String? thumbnail;
  final bool ready;
  final bool error;

  const MyVideo({
    required this.url,
    this.thumbnail,
    this.ready = true,
    this.error = false,
  });

  @override
  String get videoUrl => url;

  @override
  String? get thumbnailUrl => thumbnail;

  @override
  bool get isReadyToPlay => ready;

  @override
  bool get hasPlaybackError => error;
}
```

**Step 2 — create the controller (hold it in your State or provider):**

```dart
final _multiController = SafeMultiVideoPlayerController<MyVideo>();
```

**Step 3 — render the feed:**

```dart
final videos = [
  MyVideo(url: 'https://example.com/a.mp4', thumbnail: 'https://example.com/a.jpg'),
  MyVideo(url: 'https://example.com/b.mp4', thumbnail: 'https://example.com/b.jpg'),
  MyVideo(url: 'https://example.com/c.mp4', thumbnail: 'https://example.com/c.jpg'),
];

MultiVideoPlayerWidget<MyVideo>(
  initialVideoIndex: 0,
  videoModels: videos,
  multiVideoPlayerController: _multiController,
  onTapBackButton: () => Navigator.pop(context),

  // Optional callbacks
  onPageChange: (previousIndex, currentIndex) async { /* analytics, load more, etc. */ },
  onInitVideoScreen: (index) { /* called when a video screen initialises */ },

  // Custom overlay per video (likes, comments, username…)
  overlayBuilder: (videoModel, index) => Positioned(
    bottom: 80,
    left: 16,
    child: Text(videoModel.url, style: const TextStyle(color: Colors.white)),
  ),
);
```

**Step 4 — clean up:**

```dart
@override
void dispose() {
  _multiController.clearAll();
  super.dispose();
}
```

### Controller API

| Member | Description |
|--------|-------------|
| `initialize()` | Initialize the underlying player. Skips if already initialized. |
| `play()` | Play. Cancels any pending play/pause ops before enqueuing. |
| `pause()` | Pause. Cancels any pending play/pause ops before enqueuing. |
| `seekTo(Duration)` | Seek. Cancels any pending seek ops before enqueuing. |
| `reset()` | Pause then seek to `Duration.zero`. |
| `dispose()` | Pause, cancel pending seeks, dispose. |
| `isVideoInitialized` | `true` after successful `initialize()`. |
| `isVideoPlaying` | `true` while playing. |
| `isVideoEnded` | `true` when playback reached the end. |
| `isBuffering` | `true` while buffering. |
| `hasError` | `true` if an error occurred. |
| `currentPosition` | Current `Duration`, or `null` if at the end. |
| `totalDuration` | Total video `Duration`. |
| `bufferedRanges` | List of buffered `DurationRange`s. |

### `SafeMultiVideoPlayerController` API

| Member | Description |
|--------|-------------|
| `startFocusedVideo(index, models)` | Begin playback session at `index`. Call once on widget init. |
| `stopFocusedVideo()` | Pause focused video and clear session state. |
| `onChangePage(index, models)` | Call from `PageView.onPageChanged`. Handles pause/play/seek transitions. |
| `playFocusedVideo()` | Resume focused video (e.g. after returning from another screen). |
| `switchMuteFocusedVideo()` | Toggle mute on the focused video. |
| `isMutedFocusedVideo` | `true` if focused video is muted. |
| `isVideoPlayingFocusedVideo` | `true` if focused video is playing. |
| `focusedPageIndex` | Current page index. |
| `videoControllers` | Map from model → controller (for direct access if needed). |
| `preCache(index, ...)` | Manually trigger pre-caching around an index. Called automatically by `startFocusedVideo`. |
| `clearAll()` | Pause and dispose all controllers. Call on widget dispose. |

## How the operation queue works

`SafeVideoPlayerController` wraps every async operation in a serial queue. When you call `play()` immediately followed by `seekTo()`, they execute in order without overlapping. Redundant operations are cancelled automatically — e.g. calling `seekTo` three times quickly cancels the first two and only the last one runs.

This eliminates a common class of bugs in video players where rapid user interaction (fast-forwarding, switching videos) triggers overlapping async calls that leave the controller in an inconsistent state.
