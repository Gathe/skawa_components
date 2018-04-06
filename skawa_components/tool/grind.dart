import 'dart:async';
import 'dart:io';
import 'package:angular_utility/src/grind.dart' as ang;
import 'package:angular_utility/src/process_start_task.dart' as ang;
import 'package:grinder/grinder.dart';
import 'package:logging/logging.dart';
import 'package:ansicolor/ansicolor.dart';

Future<Null> main(List<String> args) async => grind(args);

@Task('compile scss')
Future sass() async {
  ang.config.sassBuildConfig.package = 'skawa_components';
  return await ang.sassBuild();
}

@DefaultTask()
@Task('checking for bad imports')
Future checkimport() async {
  ang.config.importOptimize.packagesToCheck = ['skawa_components'];
  await ang.checkImport();
}

@Task('watch scss')
Future sasswatch() async {
  ang.config.sassWatchConfig.package = 'skawa_components';
  return await ang.sassWatch();
}

@Task('run test')
Future test(GrinderContext args) async {
  bool dry = args.invocation.arguments.getFlag('dry');
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord rec) => logEvent(rec, !dry));
  ang.ServeProcess serveProcess = new ang.ServeProcess();
  await serveProcess.processStart(pubServe, false);
  await ang.processStart(normalTest, dry);
  await serveProcess.close();
}

const ang.ProcessInformation pubServe =
    const ang.ProcessInformation('pub', const ['serve', 'test', '--port=8080', '--web-compiler=dart2js'], 'Pub serve');

const ang.ProcessInformation normalTest =
    const ang.ProcessInformation('pub', const ['run', 'test', 'test/', '-pchrome', '--pub-serve=8080', '--timeout=2x'], 'Run test');

/// Prints a log event to stdout
void logEvent(LogRecord rec, bool verbose) {
  var color;
  if (rec.level == Level.WARNING) {
    color = _yellow;
  } else if (rec.level == Level.SEVERE) {
    color = _red;
  } else if (rec.level == Level.FINER) {
    color = _blue;
  } else if (rec.level == Level.INFO) {
    color = _cyan;
  } else if (rec.level == Level.FINEST) {
    if (!verbose) return;
    color = _magenta;
  } else {
    color = _green;
  }
  stdout.writeln(color('[${rec.level.name}]\t${rec.time.toLocal()}\t${rec.message}'));
  if (rec.error != null) {
    stdout.writeln(color('\n${rec.error}'));
    if (rec.stackTrace != null) {
      stdout.writeln(color('${rec.stackTrace}'));
    }
  }
}

final _green = new AnsiPen()..green();
final _red = new AnsiPen()..red();
final _yellow = new AnsiPen()..yellow();
final _blue = new AnsiPen()..blue(bold: true);
final _cyan = new AnsiPen()..cyan();
final _magenta = new AnsiPen()..magenta(bold: true);
