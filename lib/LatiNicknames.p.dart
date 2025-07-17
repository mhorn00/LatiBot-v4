part of "LatiBot.p.dart";

// Nickname History Management
mixin LatiNicknames on LatiBot {
  static const String _nicknamesFilePath = "nicknames.json";
  Map<String, NicknameHistory>? _nicknamesHistory;
  final Map<String, NicknameCmdInfo> _hashes = {};

  /// Populates nickname history from the JSON file
  Future<void> populateHistory(NyxxGateway client) async {
    final file = File(_nicknamesFilePath);

    // Create file if it doesn't exist
    if (!await file.exists()) {
      try {
        await file.create();
        await file.writeAsString("{}");
      } catch (e) {
        logger.warning("Error creating nicknames.json: $e");
        return;
      }
    }

    _nicknamesHistory = <String, NicknameHistory>{};

    try {
      final content = await file.readAsString();
      if (content.isEmpty || content.trim() == "{}") return;

      final Map<String, dynamic> json = jsonDecode(content);

      for (final guildId in json.keys) {
        final List<dynamic> members = json[guildId];
        for (final memberData in members) {
          final nicknameHistory = NicknameHistory.fromJson(memberData, client);
          if (nicknameHistory != null) {
            _nicknamesHistory![memberData[NicknameHistory.keyMember][NicknameHistory.keyMemberId]] = nicknameHistory;
          }
        }
      }
    } catch (e) {
      logger.warning("Error reading nicknames.json: $e");
    }
  }

  /// Writes the current nickname history to JSON file
  Future<void> writeJson() async {
    if (_nicknamesHistory == null) return;

    final Map<String, List<Map<String, dynamic>>> json = {};

    for (final nicknameHistory in _nicknamesHistory!.values) {
      final guildId = nicknameHistory.guildId.toString();
      json.putIfAbsent(guildId, () => []);
      json[guildId]!.add(nicknameHistory.toJson());
    }

    try {
      final file = File(_nicknamesFilePath);
      await file.writeAsString(jsonEncode(json));
      print("Wrote nicknames.json");
    } catch (e) {
      print("Error writing nicknames.json: $e");
    }
  }

  /// Creates a hash for nickname change tracking
  String hashNameChange(String? oldNickname, String newNickname, String userId) {
    try {
      final input = '${oldNickname ?? ""}$newNickname$userId';
      final bytes = utf8.encode(input);
      final digest = sha256.convert(bytes);
      final hash = digest.toString();
      return hash.length >= 95 ? hash.substring(0, 95) : hash;
    } catch (e) {
      print("Error hashing name change, using fallback: $e");
      // Backup "hash"
      final backup = '${oldNickname ?? ""}$newNickname$userId';
      return backup.length >= 95 ? backup.substring(0, 95) : backup;
    }
  }

  /// Adds a hash for tracking nickname changes from commands
  void addHash(String hash, NicknameCmdInfo info) {
    _hashes[hash] = info;
  }

  /// Confirms a hash and processes the nickname change
  Future<bool> confirmHash(String hash) async {
    if (!_hashes.containsKey(hash)) {
      print("Error confirming hash! Hash not found: $hash");
      return false;
    }

    final info = _hashes[hash]!;
    if (info.needsConfirm && info.confirmed) {
      _nicknamesHistory ??= {};
      if (_nicknamesHistory!.containsKey(info.victimId)) {
        _nicknamesHistory![info.victimId]!.addNickname(info.newNickname, info.aggressorId);
        await writeJson();
        return true;
      }
    }

    print("Error confirming hash! Not confirmed or victim not found: $hash");
    return false;
  }

  /// Handles nickname update events
  Future<void> onNicknameUpdate(LatiBot self, String userId, String? oldNickname, String? newNickname, String? aggressorId) async {
    // Ignore if nickname is null or blank
    if (newNickname == null || newNickname.trim().isEmpty) return;

    // Initialize history if needed
    _nicknamesHistory ??= {};

    // Create history entry for user if it doesn't exist
    if (!_nicknamesHistory!.containsKey(userId)) {
      _nicknamesHistory![userId] = NicknameHistory(
        guildId: LatiBot._instance.guildId,
        userId: Snowflake.parse(userId),
        username: "", // Will be updated when member data is available
        nicknames: [],
      );
    }

    // Check for command-based nickname changes
    if (_hashes.isNotEmpty) {
      final hash = hashNameChange(oldNickname, newNickname, userId);
      if (_hashes.containsKey(hash)) {
        final info = _hashes[hash]!;
        if (info.needsConfirm) {
          info.confirm();
          return;
        }
        _nicknamesHistory![userId]!.addNickname(newNickname, info.aggressorId);
        await writeJson();
        return;
      }
    }

    // Default to self-change
    print("Received nickname change event with no hash! Assuming self change.");
    _nicknamesHistory![userId]!.addNickname(newNickname, aggressorId ?? userId);
    await writeJson();
  }

  /// Gets nickname history for a user
  List<NicknameEntry> getNicknameHistory(String userId) => _nicknamesHistory?[userId]?.nicknames ?? [];

  /// Gets all nickname history
  Map<String, NicknameHistory> getAllHistory() => Map.unmodifiable(_nicknamesHistory ?? {});

  /// Clears history for a specific user
  Future<void> clearUserHistory(String userId) async {
    _nicknamesHistory?.remove(userId);
    await writeJson();
  }

  /// Initializes the nickname system
  Future<void> initialize(NyxxGateway client) async {
    await populateHistory(client);
  }
}

// Nickname Entry Data Class
@immutable
class NicknameEntry {
  static const String keyNickname = "nickname";
  static const String keyChangedById = "changedById";
  static const String keyDatetime = "datetime";
  final DateTime timestamp;
  final String nickname;
  final int changedById;

  const NicknameEntry({
    required this.nickname,
    required this.timestamp,
    required this.changedById,
  });

  Map<String, dynamic> toJson() => {
        keyNickname: nickname,
        keyChangedById: changedById,
        keyDatetime: timestamp.toIso8601String(),
      };

  static NicknameEntry? fromJson(Map<String, dynamic> json) {
    try {
      return NicknameEntry(
        nickname: json[keyNickname] as String,
        changedById: json[keyChangedById] as int,
        timestamp: DateTime.parse(json[keyDatetime] as String),
      );
    } catch (e) {
      LatiBot.slogger.warning("Exception parsing NicknameEntry json: $e");
      return null;
    }
  }
}

// Nickname History Data Class
class NicknameHistory {
  static const String keyGuildId = "guild";
  static const String keyMember = "member";
  static const String keyMemberUsername = "username";
  static const String keyMemberId = "id";
  static const String keyNicknames = "nicknames";
  final int guildId;
  final int userId;
  final String username;
  final List<NicknameEntry> nicknames;

  NicknameHistory({
    required this.guildId,
    required this.userId,
    required this.username,
    required this.nicknames,
  });

  void addNickname(String newNickname, Snowflake changedById) {
    nicknames.add(NicknameEntry(
      nickname: newNickname,
      timestamp: DateTime.now(),
      changedById: changedById.value,
    ));
  }

  NicknameEntry? get latestNickname => nicknames.isEmpty ? null : nicknames.last;

  Map<String, dynamic> toJson() => {
        keyGuildId: guildId,
        keyMember: {
          keyMemberId: userId,
          keyMemberUsername: username,
        },
        keyNicknames: nicknames.map((e) => e.toJson()).toList(),
      };

  static NicknameHistory? fromJson(Map<String, dynamic> json, NyxxGateway client) {
    try {
      final guildId = json["guild"] as int;
      final memberData = json["member"] as Map<String, dynamic>;
      final userId = memberData["id"] as int;
      final username = memberData["username"] as String;
      final nicknamesList = (json["nicknames"] as List<Map<String, dynamic>>).map((e) => NicknameEntry.fromJson(e)).where((e) => e != null).cast<NicknameEntry>().toList();

      return NicknameHistory(
        guildId: guildId,
        userId: userId,
        username: username,
        nicknames: nicknamesList,
      );
    } catch (e) {
      LatiBot.slogger.warning("Exception parsing NicknameHistory json: $e");
      return null;
    }
  }
}

// Nickname Command Info Data Class
class NicknameCmdInfo {
  final String? oldNickname;
  final String newNickname;
  final int victimId;
  final int aggressorId;
  final String hash;
  final bool needsConfirm;
  final String? msgId;
  bool confirmed;

  NicknameCmdInfo({
    required this.oldNickname,
    required this.newNickname,
    required this.victimId,
    required this.aggressorId,
    required this.hash,
    this.needsConfirm = false,
    this.msgId,
    this.confirmed = false,
  });

  NicknameCmdInfo.withConfirmation({
    required this.oldNickname,
    required this.newNickname,
    required this.victimId,
    required this.aggressorId,
    required this.hash,
    required this.msgId,
  })  : needsConfirm = true,
        confirmed = false;

  void confirm() {
    confirmed = true;
  }
}
