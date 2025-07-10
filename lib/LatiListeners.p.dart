part of 'LatiBot.p.dart';

base mixin LatiListeners on LatiBot {
  //[ ===== Getters ===== ]

  LatiGuildMemberUpdateListener get guildMemberUpdateListener => this as LatiGuildMemberUpdateListener;
  LatiReadyListener get readyListener => this as LatiReadyListener;
  LatiMessageCreateListener get messageCreateListener => this as LatiMessageCreateListener;
  LatiMessageReactionAddListener get messageReactionAddListener => this as LatiMessageReactionAddListener;

  /// Initializes the listeners for the bot.
  void initListeners() {
    client.onReady.listen(readyListener.readyinvoker);
    client.onMessageCreate.listen(messageCreateListener.messageCreateInvoker);
    client.onGuildMemberUpdate.listen(guildMemberUpdateListener.guildMemberUpdateInvoker);
    client.onMessageReactionAdd.listen(messageReactionAddListener.m0essageReactionAddInvoker);
  }
}

base mixin LatiGuildMemberUpdateListener on LatiBot {
  void Function(GuildMemberUpdateEvent event) get guildMemberUpdateInvoker => (e) => _onGuildMemberUpdate(instance, e);

  void _onGuildMemberUpdate(final LatiBot self, final GuildMemberUpdateEvent event) async {
    print("member updated");
  }
}

base mixin LatiMessageCreateListener on LatiBot {
  void Function(MessageCreateEvent event) get messageCreateInvoker => (e) => _onMessageCreate(instance, e);

  void _onMessageCreate(final LatiBot self, final MessageCreateEvent event) async {
    if (event.message.content.contains("latibot")) {
      await event.message.react(
        ReactionBuilder.fromEmoji(await self.client.guilds[self.guildId].emojis.fetch(Snowflake(1150947082383925278))),
      );
    }
  }
}

base mixin LatiMessageReactionAddListener on LatiBot {
  void Function(MessageReactionAddEvent event) get m0essageReactionAddInvoker => (e) => _onMessageReactionAdd(instance, e);

  void _onMessageReactionAdd(final LatiBot self, final MessageReactionAddEvent event) {
    print("reaction added");
  }
}

base mixin LatiReadyListener on LatiBot {
  Completer<void> readyCompleter = Completer<void>();
  Future<void> get waitForReady => readyCompleter.future;

  void Function(ReadyEvent event) get readyinvoker => (e) => _onReady(instance, e);

  /// Called when the bot is ready.
  void _onReady(final LatiBot self, final ReadyEvent event) async {
    print("Ready!");
    if (!readyCompleter.isCompleted) readyCompleter.complete();
    // List<GuildChannel> c = await event.guilds.firstWhere((g) => g.id == guildId).fetchChannels();
    // await (c.firstWhere((c) => c.name == "cum-zone" && c.type == ChannelType.guildText) as PartialTextChannel).sendMessage(MessageBuilder(content: "penis"));
  }
}
