import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_proxy/shelf_proxy.dart' as shelf_proxy;
import 'package:shelf_route/shelf_route.dart';


main(List<String> args) async {
  var options = _parseArgs(args);

  // using shelf_route
  Router r = router(middleware: shelf.logRequests());
  r.add('/echo', ['GET'], _echoRequest, exactMatch: false);
  r.add('/log', ['POST'], _log, exactMatch: false);
  // pub serve for transform and static files out of working dir
  var rph = await _getPubProxy(options['pubport'], options['dir']);
  r.add('/', ['GET'], rph, exactMatch: false);

  io.serve(r.handler, '0.0.0.0', options['port']).then((server) {
    print('Serving at http://${server.address.host}:${server.port}');
  });
}

shelf.Response _echoRequest(shelf.Request request) {
  return new shelf.Response.ok('Request for "${request.url}"');
}

Future<shelf.Response> _log(shelf.Request request) async {
  var t = await request.readAsString();
  print('[client] $t');
  return new shelf.Response.ok('Received client log: $t');
}

// run pub serve and return a shelf proxy to the pub serve port
Future<shelf.Handler> _getPubProxy(port, workingDir) async {
  Process p = await Process.start("pub", ["serve", "--port", "$port"], workingDirectory: workingDir);
  p.stdout.transform(UTF8.decoder).transform(const LineSplitter()).listen((v) => print('[pub serve] $v'));
  p.stderr.transform(UTF8.decoder).transform(const LineSplitter()).listen((v) => print('[pub serve] $v'));
  p.exitCode.then((exitCode) {
    print('pub serve exit code: $exitCode');
  });

  // under VSCODE, the child is sometimes left running without these handlers
  killPubServe(ProcessSignal signal) {
    print("Killing pub serve");
    p.kill();
    exit(0);
  }

  ProcessSignal.SIGTERM.watch().listen(killPubServe);
  ProcessSignal.SIGINT.watch().listen(killPubServe);

  print('Launched pub serve at port $port, pid ${p.pid}');
  return shelf_proxy.proxyHandler(Uri.parse('http://localhost:$port'));
}

_parseArgs(List<String> args) {
  var options = {};
  var parser = new ArgParser()
    ..addOption('port', abbr: 'p', defaultsTo: '8080')
    ..addOption('pubport', abbr: 'x', defaultsTo: '9090')
    ..addOption('dir', abbr: 'd', defaultsTo: '.');

  var t = parser.parse(args);
  options['port'] = int.parse(t['port'], onError: (val) {
    print('Could not parse port value "$val" into a number');
    exit(1);
  });

  options['pubport'] = int.parse(t['pubport'], onError: (val) {
    print('Could not parse port value "$val" into a number');
    exit(1);
  });

  options['dir'] = t['dir'];
  return options;
}
