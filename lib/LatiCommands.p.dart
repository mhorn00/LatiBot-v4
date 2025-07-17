part of 'LatiBot.p.dart';

base mixin LatiCommands on LatiBot {
  void initCommands() {
    // Bot commands
    commands.addCommand(pingCommand);
    commands.addCommand(sayCommand);
    commands.addCommand(shutdownCommand);
    commands.addCommand(joinVoiceCommand);
    commands.addCommand(leaveVoiceCommand);

    // Audio commands
    commands.addCommand(playCommand);
    commands.addCommand(pauseCommand);
    commands.addCommand(skipCommand);
    commands.addCommand(clearCommand);
    commands.addCommand(queueCommand);
    commands.addCommand(nowPlayingCommand);
    commands.addCommand(repeatCommand);
    commands.addCommand(shuffleCommand);
    commands.addCommand(speakCommand);

    // Misc commands
    commands.addCommand(statusCommand);
    commands.addCommand(replaceUrlCommand);
    commands.addCommand(toggleReplaceCommand);
    commands.addCommand(toggleWebhooksCommand);
    commands.addCommand(getEmotesCommand);
    commands.addCommand(emoteStatsCommand);

    // User commands
    commands.addCommand(nicknameCommand);
    commands.addCommand(nicknamesCommand);
  }

  final ChatCommand pingCommand = buildSlashCommand(
    name: "ping",
    description: "pong!",
    execute: id('ping', (InteractionChatContext context) async {
      await context.respond(MessageBuilder(content: "Pong! (~${context.client.gateway.latency.inMilliseconds}ms)"));
    }),
    checks: [],
  );

  // === BOT COMMANDS ===

  final ChatCommand sayCommand = buildSlashCommand(
    name: "say",
    description: "Say something as the bot.",
    execute: (InteractionChatContext context) async {
      final message = context.rawArguments['message'] as String;
      final reply = context.rawArguments['reply'] as String?;

      // TODO: Add logging

      if (reply == null) {
        await context.respond(MessageBuilder(content: "ok"), level: ResponseLevel.private);
        await context.channel.sendMessage(MessageBuilder(content: message));
      } else {
        try {
          // TODO: Implement message retrieval and reply functionality
          await context.respond(MessageBuilder(content: "ok"), level: ResponseLevel.private);
          // final replyMsg = await context.channel.get(Snowflake.parse(reply));
          // await replyMsg.manager.reply(MessageBuilder(content: message));
        } catch (e) {
          await context.respond(MessageBuilder(content: "Couldn't find message with ID '$reply' in channel!"), level: ResponseLevel.private);
        }
      }
    },
  );

  final ChatCommand shutdownCommand = buildSlashCommand(
    name: "shutdown",
    description: "Shuts down the bot",
    execute: (InteractionChatContext context) async {
      // TODO: Implement TTS shutdown
      // TODO: Close audio connection
      await context.respond(MessageBuilder(content: "ok bye bye!"));
      // TODO: Implement graceful shutdown
      exit(0);
    },
    checks: [
      // TODO: Add administrator permission check
    ],
  );

  final ChatCommand joinVoiceCommand = buildSlashCommand(
    name: "joinvoice",
    description: "Join a voice channel",
    execute: (InteractionChatContext context) async {
      // TODO: Implement voice channel joining logic
      await context.respond(MessageBuilder(content: "Voice functionality not yet implemented"), level: ResponseLevel.private);
    },
  );

  final ChatCommand leaveVoiceCommand = buildSlashCommand(
    name: "leavevoice",
    description: "Leave the current voice channel",
    execute: (InteractionChatContext context) async {
      // TODO: Implement voice channel leaving logic
      await context.respond(MessageBuilder(content: "Voice functionality not yet implemented"), level: ResponseLevel.private);
    },
  );

  // === AUDIO COMMANDS ===

  final ChatCommand playCommand = buildSlashCommand(
    name: "play",
    description: "Adds a song to the queue.",
    execute: (InteractionChatContext context) async {
      final link = context.rawArguments['link'] as String;
      final type = context.rawArguments['type'] as String?;
      final silent = context.rawArguments['silent'] as bool?;
      final isSilent = silent ?? false;

      // TODO: Check if user is in voice channel
      // TODO: Connect to voice channel if needed
      // TODO: Implement actual audio source resolution

      final trackInfo = AudioTrackInfo(
        title: "Mock Track: $link",
        url: link.startsWith('http') ? link : "https://youtube.com/search?q=$link",
        duration: "3:45",
        requestedBy: context.member!,
      );

      switch (type?.toLowerCase()) {
        case 'next':
          LatiBot._instance.audioManager.queueNext(trackInfo);
          break;
        case 'now':
          LatiBot._instance.audioManager.queueNow(trackInfo);
          break;
        default:
          LatiBot._instance.audioManager.queueTrack(trackInfo);
      }

      await context.respond(MessageBuilder(content: "Added to queue: ${trackInfo.title}"), level: isSilent ? ResponseLevel.private : ResponseLevel.public);
    },
  );

  final ChatCommand pauseCommand = buildSlashCommand(
    name: "pause",
    description: "Pauses the current song.",
    execute: (InteractionChatContext context) async {
      final isPaused = LatiBot._instance.audioManager.togglePause();
      await context.respond(MessageBuilder(content: isPaused ? "Playback paused" : "Playback resumed"), level: ResponseLevel.private);
    },
  );

  final ChatCommand skipCommand = buildSlashCommand(
    name: "skip",
    description: "Skips the current song.",
    execute: (InteractionChatContext context) async {
      LatiBot._instance.audioManager.skip();
      await context.respond(MessageBuilder(content: "Skipped current track"), level: ResponseLevel.private);
    },
  );

  final ChatCommand clearCommand = buildSlashCommand(
    name: "clear",
    description: "Clears the song queue.",
    execute: (InteractionChatContext context) async {
      LatiBot._instance.audioManager.clearQueue();
      await context.respond(MessageBuilder(content: "Music queue cleared"), level: ResponseLevel.private);
    },
  );

  final ChatCommand queueCommand = buildSlashCommand(
    name: "queue",
    description: "Shows the current song queue.",
    execute: (InteractionChatContext context) async {
      final audioManager = LatiBot._instance.audioManager;
      final current = audioManager.queue.current;
      final queueItems = audioManager.queue.queueItems;

      String queueText = "**Music Queue**\n";
      if (current != null) {
        queueText += "🎵 **Now Playing:** ${current.title}\n\n";
      } else {
        queueText += "Nothing currently playing\n\n";
      }

      if (queueItems.isNotEmpty) {
        queueText += "**Up Next:**\n";
        for (int i = 0; i < queueItems.length && i < 10; i++) {
          queueText += "${i + 1}. ${queueItems[i].title}\n";
        }
        if (queueItems.length > 10) {
          queueText += "... and ${queueItems.length - 10} more";
        }
      } else {
        queueText += "Queue is empty";
      }

      await context.respond(MessageBuilder(content: queueText), level: ResponseLevel.private);
    },
  );

  final ChatCommand nowPlayingCommand = buildSlashCommand(
    name: "nowplaying",
    description: "Shows the currently playing song.",
    execute: (InteractionChatContext context) async {
      final current = LatiBot._instance.audioManager.queue.current;
      if (current != null) {
        await context.respond(MessageBuilder(content: "🎵 **Now Playing:** ${current.title}\nRequested by: ${current.requestedBy.nick ?? current.requestedBy.user?.username ?? "Unknown"}"),
            level: ResponseLevel.private);
      } else {
        await context.respond(MessageBuilder(content: "Nothing is currently playing"), level: ResponseLevel.private);
      }
    },
  );

  final ChatCommand repeatCommand = buildSlashCommand(
    name: "repeat",
    description: "Toggles repeat mode.",
    execute: (InteractionChatContext context) async {
      final isRepeating = LatiBot._instance.audioManager.toggleRepeat();
      await context.respond(MessageBuilder(content: isRepeating ? "Repeat mode enabled" : "Repeat mode disabled"), level: ResponseLevel.private);
    },
  );

  final ChatCommand shuffleCommand = buildSlashCommand(
    name: "shuffle",
    description: "Shuffles the queue.",
    execute: (InteractionChatContext context) async {
      LatiBot._instance.audioManager.shuffleQueue();
      await context.respond(MessageBuilder(content: "Queue shuffled"), level: ResponseLevel.private);
    },
  );

  final ChatCommand speakCommand = buildSlashCommand(
    name: "speak",
    description: "Use text-to-speech to speak a message.",
    execute: (InteractionChatContext context) async {
      final text = context.rawArguments['text'] as String;
      // TODO: Implement TTS functionality using DecTalk wrapper
      await context.respond(MessageBuilder(content: "TTS functionality not yet implemented (text: $text)"), level: ResponseLevel.private);
    },
  );

  // === MISC COMMANDS ===

  final ChatCommand statusCommand = buildSlashCommand(
    name: "status",
    description: "Set the bot status",
    execute: (InteractionChatContext context) async {
      final status = context.rawArguments['status'] as String;
      final type = context.rawArguments['type'] as String?;

      await context.respond(MessageBuilder(content: "Status set to: $status (type: ${type ?? 'PLAYING'})"), level: ResponseLevel.private);
    },
    checks: [
      // TODO: Add appropriate permission checks
    ],
  );

  final ChatCommand replaceUrlCommand = buildSlashCommand(
    name: "replaceurl",
    description: "Test URL replacement functionality",
    execute: (InteractionChatContext context) async {
      final url = context.rawArguments['url'] as String?;

      if (url == null) {
        await context.respond(MessageBuilder(content: "Current URL replacements:\n${UrlReplacer._replacements.entries.map((e) => "${e.key} → ${e.value}").join('\n')}"), level: ResponseLevel.private);
      } else {
        final replaced = UrlReplacer.replaceUrl(url);
        if (replaced != null && replaced != url) {
          await context.respond(MessageBuilder(content: "Replaced URL:\n$url\n→\n$replaced"), level: ResponseLevel.private);
        } else {
          await context.respond(MessageBuilder(content: "No replacement found for: $url"), level: ResponseLevel.private);
        }
      }
    },
  );

  final ChatCommand toggleReplaceCommand = buildSlashCommand(
    name: "togglereplace",
    description: "Toggle URL replacement functionality",
    execute: (InteractionChatContext context) async {
      // TODO: Implement URL replacement toggle
      await context.respond(MessageBuilder(content: "URL replacement toggle not yet implemented"), level: ResponseLevel.private);
    },
  );

  final ChatCommand toggleWebhooksCommand = buildSlashCommand(
    name: "togglewebhooks",
    description: "Toggle webhook usage for URL replacements",
    execute: (InteractionChatContext context) async {
      // TODO: Implement webhook toggle functionality
      await context.respond(MessageBuilder(content: "Webhook toggle not yet implemented"), level: ResponseLevel.private);
    },
  );

  final ChatCommand getEmotesCommand = buildSlashCommand(
    name: "getemotes",
    description: "Get emotes from the server",
    execute: (InteractionChatContext context) async {
      try {
        // TODO: Implement proper emote fetching when nyxx supports it
        await context.respond(MessageBuilder(content: "Emote fetching not yet fully implemented"), level: ResponseLevel.private);
      } catch (e) {
        await context.respond(MessageBuilder(content: "Failed to fetch emotes: $e"), level: ResponseLevel.private);
      }
    },
  );

  final ChatCommand emoteStatsCommand = buildSlashCommand(
    name: "emotestats",
    description: "Show emote usage statistics",
    execute: (InteractionChatContext context) async {
      final topEmotes = {}; //EmoteStats.getTopEmotes(limit: 10);

      if (topEmotes.isEmpty) {
        await context.respond(MessageBuilder(content: "No emote usage data available"), level: ResponseLevel.private);
        return;
      }

      String statsText = "**Top Emotes:**\n";
      int position = 1;
      for (final entry in topEmotes.entries) {
        statsText += "$position. <:emote:${entry.key.value}> - ${entry.value} uses\n";
        position++;
      }

      await context.respond(MessageBuilder(content: statsText), level: ResponseLevel.private);
    },
  );

  // === USER COMMANDS ===

  final ChatCommand nicknameCommand = buildSlashCommand(
    name: "nickname",
    description: "Change a user's nickname",
    execute: (InteractionChatContext context) async {
      final user = context.rawArguments['user'] as Member;
      final nickname = context.rawArguments['nickname'] as String;

      try {
        final oldNickname = user.nick ?? user.user?.globalName ?? user.user?.username;
        final aggressorId = context.user.id.toString();
        final victimId = user.id.toString();

        // Create hash for tracking
        final hash = LatiNicknames.hashNameChange(oldNickname, nickname, victimId);

        // Create command info for tracking
        final cmdInfo = NicknameCmdInfo(
          oldNickname: oldNickname,
          newNickname: nickname,
          victimId: victimId,
          aggressorId: aggressorId,
          hash: hash,
        );

        // Add hash for tracking
        LatiNicknames.addHash(hash, cmdInfo);

        // Store new nickname in history
        // LatiNicknames.addNickname(user.id, nickname);

        await context.respond(MessageBuilder(content: "Changed ${user.user?.username ?? "Unknown"}'s nickname to: $nickname"), level: ResponseLevel.private);
      } catch (e) {
        await context.respond(MessageBuilder(content: "Failed to change nickname: $e"), level: ResponseLevel.private);
      }
    },
  );

  final ChatCommand nicknamesCommand = buildSlashCommand(
    name: "nicknames",
    description: "View nickname history for a user",
    execute: (InteractionChatContext context) async {
      final user = context.rawArguments['user'] as Member;

      final history = LatiNicknames.getNicknameHistory(user.id.toString());
      if (history.isEmpty) {
        await context.respond(MessageBuilder(content: "No nickname history found for ${user.user?.username ?? "this user"}"), level: ResponseLevel.private);
      } else {
        final recentNicknames = history.take(20);
        final nicknameList = recentNicknames.map((entry) {
          final date = entry.timestamp.toIso8601String().split('T')[0]; // Just the date part
          return "• ${entry.nickname} (${date})";
        }).join("\n");

        await context.respond(MessageBuilder(content: "**Nickname history for ${user.user?.username ?? "this user"}:**\n$nicknameList"), level: ResponseLevel.private);
      }
    },
  );
}

ChatCommand buildSlashCommand({
  required String name,
  required String description,
  required Function(InteractionChatContext context) execute,
  CommandOptions? options,
  List<AbstractCheck> checks = const [],
  List<String> aliases = const [],
}) =>
    ChatCommand(
      name,
      description,
      execute,
      checks: [
        //> default checks
        PermissionsCheck(Permissions.sendMessages, allowsOverrides: true, requiresAll: true, name: "Minimum Required Permissions Check"),
        ...checks,
      ],
      options: CommandOptions(
        acceptBotCommands: options?.acceptBotCommands ?? false,
        acceptSelfCommands: options?.acceptSelfCommands ?? false,
        autoAcknowledgeInteractions: options?.autoAcknowledgeInteractions ?? true,
        autoAcknowledgeDuration: options?.autoAcknowledgeDuration,
        defaultResponseLevel: options?.defaultResponseLevel ?? ResponseLevel.public,
        caseInsensitiveCommands: true,
        type: CommandType.slashOnly,
      ),
      aliases: aliases,
    );
