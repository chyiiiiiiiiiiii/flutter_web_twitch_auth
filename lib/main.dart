import 'dart:convert';

import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'package:http/http.dart' as http;

const String clientId = "YOUR_CLIENT_ID";

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(primarySwatch: Colors.blue),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _token;
  html.WindowBase _popupWin;

  Future<String> _validateToken() async {
    final response = await http.get(
      Uri.parse('https://id.twitch.tv/oauth2/validate'),
      headers: {'Authorization': 'OAuth $_token'},
    );
    return (jsonDecode(response.body) as Map<String, dynamic>)['login']
        .toString();
  }

  void _login(String data) {
    // Parse data to extract the token.
    final items = data.split(RegExp(r'#|&'));
    for (final e in items) {
      if (e.startsWith('access_token=')) {
        setState(() => _token = e.substring('access_token='.length));
        break;
      }
    }
    if (_popupWin != null) {
      _popupWin.postMessage('close', '*');
      _popupWin = null;
    }
  }

  @override
  void initState() {
    super.initState();

    html.window.onMessage.listen((event) {
      if ((event.data as String).contains('access_token=')) _login(event.data);
    });

    // You are not connected so redirect to the Twitch authentication page.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final redirectUri = 'http://localhost:8080/static.html';
      final authUrl =
          'https://id.twitch.tv/oauth2/authorize?response_type=token&client_id=$clientId&redirect_uri=$redirectUri&scope=viewing_activity_read';
      _popupWin = html.window.open(
          authUrl, "Twitch Auth", "width=800, height=900, scrollbars=yes");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Twitch web login')),
      body: Center(
        child: _token != null && _token.isNotEmpty
            ? FutureBuilder<String>(
                future: _validateToken(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) return CircularProgressIndicator();
                  return Container(child: Text('Welcome ${snapshot.data}'));
                },
              )
            : Container(
                child: Text('You are not connected'),
              ),
      ),
    );
  }
}
