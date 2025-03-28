import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class ApiService {
  static const List<String> apiUrls = [
    "https://192.168.254.163/",
    "https://126.209.7.246/"
  ];

  static const Duration requestTimeout = Duration(seconds: 2);
  static const int maxRetries = 6;
  static const Duration initialRetryDelay = Duration(seconds: 1);

  late http.Client httpClient;

  ApiService() {
    httpClient = _createHttpClient();
  }

  http.Client _createHttpClient() {
    final HttpClient client = HttpClient()
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(client);
  }
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
    );
  }

  Future<String> fetchSoftwareLink(int linkID) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idNumber = prefs.getString('IDNumber');

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      for (int i = 0; i < apiUrls.length; i++) {
        String apiUrl = apiUrls[i];
        try {
          final uri = Uri.parse("${apiUrl}V4/Others/Kurt/ArkLinkAPI/kurt_fetchLink.php?linkID=$linkID");
          final response = await httpClient.get(uri).timeout(requestTimeout);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data.containsKey("softwareLink")) {
              String relativePath = data["softwareLink"];
              String fullUrl = Uri.parse(apiUrl).resolve(relativePath).toString();
              if (idNumber != null) {
                fullUrl += "?idNumber=$idNumber";
              }
              return fullUrl;
            } else {
              throw Exception(data["error"]);
            }
          }
        } catch (e) {
          // print("Error accessing $apiUrl on attempt $attempt");
          // _showToast("Error accessing $apiUrl on attempt $attempt");

          if (i == 0 && apiUrls.length > 1) {
            // _showToast("Falling back to ${apiUrls[1]}");
          }
        }
      }
      if (attempt < maxRetries) {
        final delay = initialRetryDelay * (1 << (attempt - 1));
        // print("Waiting for ${delay.inSeconds} seconds before retrying...");
        // _showToast("Waiting for ${delay.inSeconds} seconds before retrying...");
        await Future.delayed(delay);
      }
    }
    // _showToast("All API URLs are unreachable after $maxRetries attempts");
    throw Exception("All API URLs are unreachable after $maxRetries attempts");
  }

  Future<bool> checkIdNumber(String idNumber) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      for (String apiUrl in apiUrls) {
        try {
          final uri = Uri.parse("${apiUrl}V4/Others/Kurt/ArkLinkAPI/kurt_checkIdNumber.php");
          final response = await httpClient.post(
            uri,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"idNumber": idNumber}),
          ).timeout(requestTimeout);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return data["success"] == true;
          }
        } catch (e) {
          // print("Error accessing $apiUrl on attempt $attempt: $e");
        }
      }
      if (attempt < maxRetries) {
        final delay = initialRetryDelay * (1 << (attempt - 1));
        // print("Waiting for ${delay.inSeconds} seconds before retrying...");
        await Future.delayed(delay);
      }
    }
    throw Exception("Both API URLs are unreachable after $maxRetries attempts");
  }

  Future<Map<String, dynamic>> fetchProfile(String idNumber) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      for (String apiUrl in apiUrls) {
        try {
          final uri = Uri.parse("${apiUrl}V4/Others/Kurt/ArkLinkAPI/kurt_fetchProfile.php?idNumber=$idNumber");
          final response = await httpClient.get(uri).timeout(requestTimeout);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return data["success"] == true ? data : throw Exception(data["message"]);
          }
        } catch (e) {
          // print("Error accessing $apiUrl on attempt $attempt: $e");
        }
      }
      if (attempt < maxRetries) {
        final delay = initialRetryDelay * (1 << (attempt - 1));
        // print("Waiting for ${delay.inSeconds} seconds before retrying...");
        await Future.delayed(delay);
      }
    }
    throw Exception("Both API URLs are unreachable after $maxRetries attempts");
  }

  Future<void> updateLanguageFlag(String idNumber, int languageFlag) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      for (String apiUrl in apiUrls) {
        try {
          final uri = Uri.parse("${apiUrl}V4/Others/Kurt/ArkLinkAPI/kurt_updateLanguage.php");
          final response = await httpClient.post(
            uri,
            body: {'idNumber': idNumber, 'languageFlag': languageFlag.toString()},
          ).timeout(requestTimeout);

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            if (data["success"] == true) return;
          }
        } catch (e) {
          // print("Error accessing $apiUrl on attempt $attempt: $e");
        }
      }
      if (attempt < maxRetries) {
        final delay = initialRetryDelay * (1 << (attempt - 1));
        // print("Waiting for ${delay.inSeconds} seconds before retrying...");
        await Future.delayed(delay);
      }
    }
    throw Exception("Both API URLs are unreachable after $maxRetries attempts");
  }
  static void setupHttpOverrides() {
    HttpOverrides.global = MyHttpOverrides();
  }
}
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}