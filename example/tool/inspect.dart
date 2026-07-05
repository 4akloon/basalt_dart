// One-command launcher for the basalt DevTools inspector — no IDE required.
//
// DevTools only discovers extensions for projects that a Dart Tooling Daemon
// (DTD) knows about. A plain `dart run --observe` starts no DTD, and even
// `--print-dtd` starts one with no workspace roots — so the Extensions menu
// stays empty. This script starts a DTD, points it at this repo
// (setIDEWorkspaceRoots), runs the target app, and opens DevTools wired to
// both, so the "basalt" tab is discoverable.
//
// Usage (from the repo root):
//   dart run example/tool/inspect.dart [app.dart]
//     app.dart  target to run (default: the inspector demo)
//   dart run example/tool/inspect.dart --check
//     just verify the DTD sees this project's packages, then exit
//
// After DevTools opens, enable "basalt" from the Extensions menu (top-right).
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dtd/dtd.dart';

const _defaultTarget = 'example/tool/inspector_demo.dart';

Future<void> main(List<String> args) async {
  final checkOnly = args.contains('--check');
  final target =
      args.where((a) => !a.startsWith('--')).firstOrNull ?? _defaultTarget;
  final workspaceRoot = Directory.current.uri;

  // 1. Start a DTD and point it at this repo.
  final daemon = await Process.start('dart', ['tooling-daemon', '--machine']);
  final line = await daemon.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .firstWhere((l) => l.contains('tooling_daemon_details'));
  final details =
      (jsonDecode(line) as Map)['tooling_daemon_details'] as Map;
  final dtdUri = details['uri'] as String;
  final secret = details['trusted_client_secret'] as String;

  final dtd = await DartToolingDaemon.connect(Uri.parse(dtdUri));
  await dtd.setIDEWorkspaceRoots(secret, [workspaceRoot]);
  final roots = await dtd.getProjectRoots();
  stdout.writeln('DTD workspace root: ${workspaceRoot.toFilePath()}');
  stdout.writeln('DTD project roots : ${roots.uris?.map((u) => u.toFilePath()).toList()}');

  if (checkOnly) {
    await dtd.close();
    daemon.kill();
    return;
  }

  // 2. Run the target app with the VM service on (no auth code → clean URI).
  final app = await Process.start(
    'dart',
    ['run', '--observe=0', '--disable-service-auth-codes', target],
  );
  final vmUri = Completer<String>();
  app.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen((l) {
    stdout.writeln('[app] $l');
    final m = RegExp(r'listening on (http://[^\s]+)').firstMatch(l);
    if (m != null && !vmUri.isCompleted) vmUri.complete(m.group(1));
  });
  app.stderr.transform(utf8.decoder).listen(stderr.write);
  final vm = await vmUri.future.timeout(const Duration(seconds: 30));

  // 3. Open DevTools connected to the app + our DTD.
  stdout.writeln('\nOpening DevTools (enable "basalt" in the Extensions menu)…');
  final devtools = await Process.start(
    'dart',
    ['devtools', '--dtd-uri=$dtdUri', vm],
  );
  devtools.stdout.transform(utf8.decoder).listen(stdout.write);
  devtools.stderr.transform(utf8.decoder).listen(stderr.write);

  Future<void> shutdown() async {
    devtools.kill();
    app.kill();
    await dtd.close();
    daemon.kill();
  }

  ProcessSignal.sigint.watch().listen((_) async {
    await shutdown();
    exit(0);
  });
  await devtools.exitCode;
  await shutdown();
}
