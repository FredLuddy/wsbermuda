import 'dart:html';
import 'package:http/browser_client.dart';

main() async {
  var el = document.querySelector('#message');
  el.text = 'main.dart locked and loaded :-)';
  // communicate with server via XHR
  var client = new BrowserClient();
  var url = '/log';
  var response =  await client.post(url, body: 'hello from the client');
  print('Response status: ${response.statusCode}');
  print('Response body: ${response.body}');
}
