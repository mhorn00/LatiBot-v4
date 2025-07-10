part of 'LatiBot.p.dart';

base mixin LatiCommands on LatiBot {
  void initCommands() {
    commands.addCommand(pingCommand);
  }

  final ChatCommand pingCommand = buildSlashCommand(
    name: "ping",
    description: "pong!",
    execute: (InteractionChatContext context) async {
      await context.respond(MessageBuilder(content: "Pong! (~${context.client.gateway.latency.inMilliseconds}ms)"));
    },
    checks: [],
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
