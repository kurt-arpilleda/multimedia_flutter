import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'id_input_dialog.dart'; // For Philippines
import 'webview.dart'; // For Philippines
import 'japanFolder/id_input_dialogJP.dart'; // For Japan
import 'japanFolder/webviewJP.dart'; // For Japan

class PhOrJpScreen extends StatelessWidget {
  Future<void> _setPreference(String value, BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phorjp', value);

    if (value == 'ph') {
      // Check if IDNumber already exists in SharedPreferences
      String? idNumber = prefs.getString('IDNumber');
      if (idNumber != null && idNumber.isNotEmpty) {
        // Navigate directly to WebView
        _navigateWithTransition(context, SoftwareWebViewScreen(linkID: 4));
      } else {
        // Navigate to IdInputDialog
        _navigateWithTransition(context, IdInputDialog());
      }
    } else if (value == 'jp') {
      // Check if IDNumber already exists in SharedPreferences
      String? idNumber = prefs.getString('IDNumberJP');
      if (idNumber != null && idNumber.isNotEmpty) {
        // Navigate directly to WebViewJP
        _navigateWithTransition(context, SoftwareWebViewScreenJP(linkID: 4));
      } else {
        // Navigate to IdInputDialogJP
        _navigateWithTransition(context, IdInputDialogJP());
      }
    }
  }

  void _navigateWithTransition(BuildContext context, Widget screen) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0); // Slide from right
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: Duration(milliseconds: 300), // Adjust duration for smoothness
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Make the dialog compact
          children: [
            Text(
              'PH or JP',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => _setPreference('ph', context),
                  child: Image.asset(
                    'assets/images/philippines.png',
                    width: 75, // Reduced size
                    height: 75, // Reduced size
                    fit: BoxFit.contain,
                  ),
                ),
                SizedBox(width: 40), // Reduced space between flags
                GestureDetector(
                  onTap: () => _setPreference('jp', context),
                  child: Image.asset(
                    'assets/images/japan.png',
                    width: 75, // Reduced size
                    height: 75, // Reduced size
                    fit: BoxFit.contain,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}