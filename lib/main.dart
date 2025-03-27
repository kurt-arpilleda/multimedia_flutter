  import 'package:flutter/material.dart';
  import 'webview.dart';
  import 'id_input_dialog.dart';
  import 'phorjapan.dart';
  import 'japanFolder/id_input_dialogJP.dart';
  import 'japanFolder/webviewJP.dart';
  import 'package:shared_preferences/shared_preferences.dart';
  import 'api_service.dart';
  void main() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? phOrJp = prefs.getString('phorjp');
    String? idNumber;
    ApiService.setupHttpOverrides();
    String initialRoute;

    if (phOrJp == null) {
      initialRoute = '/phorjapan';
    } else if (phOrJp == "ph") {
      idNumber = prefs.getString('IDNumber');
      if (idNumber == null) {
        initialRoute = '/idInput';
      } else {
        initialRoute = '/webView';
      }
    } else if (phOrJp == "jp") {
      idNumber = prefs.getString('IDNumberJP');
      if (idNumber == null) {
        initialRoute = '/idInputJP';
      } else {
        initialRoute = '/webViewJP';
      }
    } else {
      initialRoute = '/phorjapan';
    }

    runApp(MyApp(initialRoute: initialRoute));
  }

  class MyApp extends StatelessWidget {
    final String initialRoute;

    MyApp({required this.initialRoute});

    @override
    Widget build(BuildContext context) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Multi Search',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: initialRoute,
        routes: {
          '/phorjapan': (context) => PhOrJpScreen(),
          '/idInput': (context) => IdInputDialog(),
          '/webView': (context) => SoftwareWebViewScreen(linkID: 4),// change this base on the software in system_softwareLinks in ph
          '/idInputJP': (context) => IdInputDialogJP(),
          '/webViewJP': (context) => SoftwareWebViewScreenJP(linkID: 4),// change this base on the software in system_softwareLinks in japan
        },
      );
    }
  }