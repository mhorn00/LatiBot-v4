part of 'LatiBot.p.dart';

// Audio Track Information Class
class AudioTrackInfo {
  final String title;
  final String url;
  final String duration;
  final Member requestedBy;
  final DateTime requestedAt;

  AudioTrackInfo({
    required this.title,
    required this.url,
    required this.duration,
    required this.requestedBy,
  }) : requestedAt = DateTime.now();

  @override
  String toString() => '$title requested by ${requestedBy.nick ?? requestedBy.user?.globalName ?? requestedBy.user?.username ?? "Unknown"}';
}

// Song Queue Management Class
class SongQueue {
  final List<AudioTrackInfo> _queue = [];
  AudioTrackInfo? _currentTrack;

  void add(AudioTrackInfo track) {
    if (_currentTrack == null) {
      _currentTrack = track;
    } else {
      _queue.add(track);
    }
  }

  void addFirst(AudioTrackInfo track) {
    if (_currentTrack == null) {
      _currentTrack = track;
    } else {
      _queue.insert(0, track);
    }
  }

  AudioTrackInfo? next() {
    _currentTrack = _queue.isEmpty ? null : _queue.removeAt(0);
    return _currentTrack;
  }

  AudioTrackInfo? get current => _currentTrack;

  void clear() {
    _queue.clear();
    _currentTrack = null;
  }

  bool get isEmpty => _queue.isEmpty && _currentTrack == null;

  bool get isQueueEmpty => _queue.isEmpty;

  void shuffle() {
    _queue.shuffle();
  }

  AudioTrackInfo? get(int index) {
    if (index < 0 || index >= _queue.length) return null;
    return _queue[index];
  }

  int get size => _queue.length;

  List<AudioTrackInfo> get queueItems => List.unmodifiable(_queue);
}

// Audio Manager Class
class AudioManager {
  final SongQueue queue = SongQueue();
  bool isPaused = false;
  bool shouldRepeat = false;
  bool isPlaying = false;

  void queueTrack(AudioTrackInfo track) {
    queue.add(track);
    if (!isPlaying) {
      playNext();
    }
  }

  void queueNow(AudioTrackInfo track) {
    queue.addFirst(track);
    if (!isPlaying) {
      playNext();
    } else {
      skip();
    }
  }

  void queueNext(AudioTrackInfo track) {
    queue.addFirst(track);
    if (!isPlaying) {
      playNext();
    }
  }

  bool togglePause() {
    isPaused = !isPaused;
    // TODO: Implement actual audio pause/resume
    return isPaused;
  }

  void clearQueue() {
    queue.clear();
    // TODO: Stop current playback
    isPlaying = false;
  }

  void skip() {
    // TODO: Stop current track
    playNext();
  }

  bool toggleRepeat() {
    shouldRepeat = !shouldRepeat;
    return shouldRepeat;
  }

  void shuffleQueue() {
    queue.shuffle();
  }

  void playNext() {
    if (shouldRepeat && queue.current != null) {
      // TODO: Replay current track
      isPlaying = true;
    } else {
      final next = queue.next();
      if (next != null) {
        // TODO: Play next track
        isPlaying = true;
      } else {
        isPlaying = false;
      }
    }
  }

  void onTrackEnd() {
    playNext();
  }
}

// URL Replacement Utility
class UrlReplacer {
  static final Map<String, String> _replacements = {
    'twitter.com': 'vxtwitter.com',
    'x.com': 'vxtwitter.com',
    'tiktok.com': 'vxtiktok.com',
    'instagram.com': 'ddinstagram.com',
    'reddit.com': 'rxddit.com',
  };

  static String? replaceUrl(String text) {
    String? replacedUrl;
    for (final entry in _replacements.entries) {
      if (text.contains(entry.key)) {
        replacedUrl = text.replaceAll(entry.key, entry.value);
        break;
      }
    }
    return replacedUrl;
  }
}

/// Midnight Manager for sending a scheduled message at midnight
mixin LatiMidnightManager on LatiBot {
  static const int _channelId = 142409638556467200;
  static Timer? _midnightTimer;
  static bool _isRunning = false;

  static void scheduleMidnight() {
    if (_isRunning) return;
    _isRunning = true;

    _scheduleNextMidnight();
  }

  static void _scheduleNextMidnight() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 5); // 5 seconds after midnight
    final timeUntilMidnight = tomorrow.difference(now);

    _midnightTimer = Timer(timeUntilMidnight, () {
      _sendMidnight();
      _scheduleNextMidnight(); // Schedule the next one
    });
  }

  static void _sendMidnight() {
    final bot = LatiBot._instance;
    try {
      bot._ensureInitialized(); // Ensure bot is initialized
      final channel = bot.client.channels[Snowflake(_channelId)] as PartialTextChannel;
      channel.sendMessage(MessageBuilder(content: "midnight"));
      bot.logger.info("midnight");
    } catch (e) {
      bot.logger.warning("Failed to send midnight message!", e);
    }
  }

  static void stop() {
    _midnightTimer?.cancel();
    _midnightTimer = null;
    _isRunning = false;
  }
}

// Bot Status Management
mixin LatiStatus on LatiBot {
  static const String defaultStatus = "she ctor on my static member until i dtor";
  String currentStatus = defaultStatus;
  CurrentUserStatus currentPresenceStatus = CurrentUserStatus.online;
  ActivityType currentActivityType = ActivityType.custom;

  /// Initializes the bot status with the default values
  void initStatus() {
    _ensureInitialized(); //> bot client must be initialized

    client.updatePresence(PresenceBuilder(
      activities: [
        ActivityBuilder(
          name: "status",
          type: currentActivityType,
          state: defaultStatus,
        )
      ],
      status: currentPresenceStatus,
      isAfk: false,
    ));
  }

  /// Updates the bot's status and presence.
  void updateStatus(String status, {CurrentUserStatus? presenceStatus, ActivityType? activityType}) {
    _ensureInitialized(); //> bot client must be initialized
    if (presenceStatus != null) currentPresenceStatus = presenceStatus;
    if (activityType != null) currentActivityType = activityType;
    currentStatus = status;

    client.updatePresence(PresenceBuilder(
      activities: [
        ActivityBuilder(
          name: status,
          type: currentActivityType,
          state: status,
        )
      ],
      status: currentPresenceStatus,
      isAfk: false,
    ));
  }
}

base mixin LatiPermsManager on LatiBot {
  static const Permissions requiredPermissions = Permissions(0x0000247C2F35EC40);

  // Future<bool> checkHasRequiredPermissions() async {
  //   final Member member = await (await guild.fetch()).members.fetch(latibotId);

  //   // member.roles.first.manager.

  //   print(member.nick ?? "Latibot has no nickname.");
  //   print(member.user?.username ?? "Latibot has no username.");
  //   if (member.permissions == null) {
  //     print("Latibot does not have any permissions.");
  //     return false;
  //   }
  //   member.permissions!.forEach((p) => print("Latibot has permission: $p"));
  //   return requiredPermissions.every((p) => member.permissions != null && member.permissions!.has(p));
  // }
}
