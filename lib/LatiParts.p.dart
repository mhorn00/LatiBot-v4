part of 'LatiBot.p.dart';

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
