# wsbermuda - web server written in Bermuda on a golf/tennis getaway

Braindead demo - eliminate the 404 on "packages/browser/dart.js" and subsequent build 
issues when running under webstorm or vscode debuggers 

Normally, "pub serve" both builds and serves assets at the request of the 
browser.  If you have a server that both has static assets and provides api support 
like rest, etc then it has to also provide code to find static files, package: files, and 
the compiled assets. 

The above can be accomplished by running a proxied "pub serve" process.  

Depends on shelf_route and shelf_proxy.

Here's the pseudo code that's the meat of the solution.  

```dart
  Process p = await Process.start("pub", ["serve", "--port", "$port"], workingDirectory: workingDir);
  ...
  print('Launched pub serve at port $port, pid ${p.pid}');
  return shelf_proxy.proxyHandler(Uri.parse('http://localhost:$port'));

```

PS If there's an easier / better way to do this, let me know :-) 
