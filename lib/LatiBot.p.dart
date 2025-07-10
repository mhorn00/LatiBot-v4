import 'dart:async';
import 'dart:io';

import 'package:nyxx/nyxx.dart';
import 'package:nyxx_commands/nyxx_commands.dart';
import 'package:yaml/yaml.dart';

part 'LatiParts.p.dart';
part 'LatiCommands.p.dart';
part 'LatiListeners.p.dart';

typedef LatiBotConfig = ({
  Snowflake guildId,
  RegExp prefix,
});

//! Entry Point
void main(List<String> arguments) async {
  final (LatiBotConfig config, String token) = (() {
    final File file = File('config.yaml');
    if (!file.existsSync()) throw Exception('config.yaml file not found in the project root directory');

    final String content = file.readAsStringSync();
    dynamic yamlMap = loadYaml(content);

    if (yamlMap['guildId'] == null) throw Exception('guildId key not found in config.yaml');
    if (yamlMap['guildId'] is! num) throw Exception('guildId value must be a string in config.yaml');
    final guildId = Snowflake(yamlMap['guildId']);

    if (yamlMap['prefix'] == null) throw Exception('prefix key not found in config.yaml');
    if (yamlMap['prefix'] == null && yamlMap['prefix'] is! String) throw Exception('prefix value must be a string in config.yaml');
    String prefixStr = yamlMap['prefix'];
    if (prefixStr.isEmpty) throw Exception('prefix value must not be empty in config.yaml');
    final prefix = RegExp(prefixStr);

    if (yamlMap['token'] == null) throw Exception('token key not found in config.yaml');
    if (yamlMap['token'] is! String) throw Exception('token value must be a string in config.yaml');

    return (
      (
        guildId: guildId,
        prefix: prefix,
      ),
      yamlMap['token'] as String
    );
  })();

  final LatiBot latibot = LatiBot.init(config);
  await latibot.init(token);
  return;
}

sealed class LatiBot {
//[ ===== Constants ===== ]
  static const String name = "LatiBot";
  static const String version = "4.0.0";
  static const String description = "Pong!";
//[ ===== ]
//[ ===== Static Instance ===== ]
  static late final LatiBot _instance;
  static bool _isInitialized = false;
//[ ===== ]
//[ ===== Data Members ===== ]
  /// The config passed in from the config.yaml file.
  final LatiBotConfig config;

  /// The client instance of the bot.
  NyxxGateway? _client;

  /// Whether the client has been initialized.
  bool clientIntialized = false;

  /// The commands plugin instance of the bot.
  CommandsPlugin? _commands;

  /// Whether the commands plugin has been initialized.
  bool commandsPluginInitialized = false;
//[ ===== ]
//[ ===== Getters ===== ]

  /// Non nullable getter for the client.
  /// If the client is not initialized, it will throw a [StateError].
  NyxxGateway get client => _client != null && clientIntialized ? _client! : (throw StateError('NyxxGateway client is not initialized. Please call LatiBot.init() first.'));

  /// Non nullable getter for the commands plugin.
  /// If the commands plugin is not initialized, it will throw a [StateError].
  CommandsPlugin get commands => _commands != null && commandsPluginInitialized ? _commands! : (throw StateError('CommandsPlugin is not initialized. Please call LatiBot.init() first.'));

  /// The bot's prefix.
  RegExp get prefix => config.prefix;

  /// The [Snowflake] if of the guild the bot acts in.
  Snowflake get guildId => config.guildId;

  LatiBot get instance => _instance;
  PartialUser get user => client.user;
  Snowflake get latibotId => user.id;

  LatiPermsManager get permsManager => this as LatiPermsManager;
  LatiListeners get listeners => this as LatiListeners;
  LatiCommands get commandsManager => this as LatiCommands;
//[ ===== ]
//[ ===== Constructor ===== ]
  LatiBot._(this.config);

  factory LatiBot() = _LatiBotImpl;

  factory LatiBot.init(final LatiBotConfig config) = _LatiBotImpl._init;
//[ ===== ]
//[ ===== Initialization ===== ]
  Future<void> init(final String token);
//[ ===== ]
}

final class _LatiBotImpl extends LatiBot
    with
        LatiCommands,
        LatiPermsManager,
        LatiListeners,
        LatiReadyListener,
        LatiGuildMemberUpdateListener,
        LatiMessageCreateListener, //>
        LatiMessageReactionAddListener {
  //[ ===== Constructor ===== ]

  _LatiBotImpl._(super.config) : super._();

  factory _LatiBotImpl() {
    if (LatiBot._isInitialized) return LatiBot._instance as _LatiBotImpl;
    throw Exception('Latibot is not initialized. Please call Latibot.init() first.');
  }

  factory _LatiBotImpl._init(final LatiBotConfig config) {
    if (LatiBot._isInitialized) return LatiBot._instance as _LatiBotImpl;
    try {
      LatiBot._instance = _LatiBotImpl._(config);
      LatiBot._isInitialized = true;
      return LatiBot._instance as _LatiBotImpl;
    } catch (e) {
      print('Error initializing Latibot in factory: $e');
      LatiBot._isInitialized = false;
      rethrow;
    }
  }

  //[ ===== Methods ===== ]

  @override
  Future<void> init(final String token) async {
    //> build the commands plugin
    this._commands = _buildCommandsPlugin();
    if (this._commands == null) throw StateError("Failed to create Nyxx CommandsPlugin instance?");
    this.commandsPluginInitialized = true;

    //> add and init all the commands
    commandsManager.initCommands();

    //> build the gateway client
    this._client = await _buildGateway(token);
    if (this._client == null) throw StateError("Failed to create NyxxGateway instance?");
    this.clientIntialized = true;

    //> init all the listeners
    listeners.initListeners();

    //TODO: check that latibot has needed perms

    //> get all the servers the bot is in
    final List<UserGuild> guilds = await client.users.listCurrentUserGuilds();

    if (guilds.isEmpty) throw Exception('Latibot is not in any guilds. Please invite it to a guild first.');
    if (!guilds.any((g) => g.id == config.guildId)) throw Exception('Latibot is not in the guild with id ${config.guildId}. Please invite it to the guild first.');

    //> get the guild with the id from the config
    // final UserGuild g = guilds.reduce((val, g) => g.id == guildId ? g : val);

    //> wait for the bot to fire the ready event
    await listeners.readyListener.waitForReady;

    return;
  }

  CommandsPlugin _buildCommandsPlugin() => CommandsPlugin(prefix: (p) => config.prefix);

  FutureOr<NyxxGateway> _buildGateway(final String token) async => clientIntialized
      ? client
      : commandsPluginInitialized
          ? Nyxx.connectGatewayWithOptions(
              GatewayApiOptions(
                intents: GatewayIntents.allUnprivileged | GatewayIntents.guildMembers | GatewayIntents.messageContent | GatewayIntents.guildMessageReactions,
                token: token,
              ),
              GatewayClientOptions(
                loggerName: "Latibot",
                voiceStateConfig: CacheConfig<VoiceState>(shouldCache: (arg) => true),
                memberCacheConfig: CacheConfig<Member>(shouldCache: (arg) => true),
                userCacheConfig: CacheConfig<User>(shouldCache: (arg) => true),
                emojiCacheConfig: CacheConfig<Emoji>(shouldCache: (arg) => true),
                plugins: [
                  logging,
                  cliIntegration,
                  commands,
                ],
              ),
            )
          : throw StateError("Unable to build NyxxGateway, NyxxCommands plugin is null");
}
