import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'webview.dart';
import 'api_service.dart'; // Import the ApiService class
import 'phorjapan.dart'; // Import the PhOrJpScreen

class IdInputDialog extends StatefulWidget {
  @override
  _IdInputDialogState createState() => _IdInputDialogState();
}

class _IdInputDialogState extends State<IdInputDialog> {
  final TextEditingController _idController = TextEditingController();
  String? _errorText; // To store the error message
  final ApiService _apiService = ApiService(); // Create an instance of ApiService

  Future<void> _saveIdNumber(BuildContext context) async {
    String idNumber = _idController.text.trim();

    // Check if the field is empty
    if (idNumber.isEmpty) {
      // Set the error message
      setState(() {
        _errorText = 'ID Number cannot be empty';
      });
      return; // Exit the function if the field is empty
    }

    // Clear any existing error message
    setState(() {
      _errorText = null;
    });

    try {
      // Check if the ID number exists using the API
      bool idExists = await _apiService.checkIdNumber(idNumber);

      if (idExists) {
        // Save the ID number to SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('IDNumber', idNumber);

        // Navigate to the WebView screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SoftwareWebViewScreen(linkID: 4),
          ),
        );
      } else {
        // If the ID number does not exist, show an error message
        setState(() {
          _errorText = 'This ID Number does not exist in the employee database.';
        });
      }
    } catch (e) {
      // Handle any errors that occur during the API call
      setState(() {
        _errorText = 'Failed to verify ID Number';
      });
    }
  }

  void _navigateBackToPhOrJp(BuildContext context) {
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => PhOrJpScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(-1.0, 0.0); // Slide from left
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AlertDialog(
          title: Text('Input your ID Number'),
          content: TextField(
            controller: _idController,
            decoration: InputDecoration(
              hintText: 'ID Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset('assets/images/philippines.png', width: 24, height: 24), // Add the image here
              ),
              errorText: _errorText, // Show error message if _errorText is not null
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () => _navigateBackToPhOrJp(context),
              icon: Icon(Icons.arrow_back),
              label: Text('Back'),
            ),
            TextButton(
              onPressed: () => _saveIdNumber(context),
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}