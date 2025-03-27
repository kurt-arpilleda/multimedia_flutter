import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'auto_update.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class SoftwareWebViewScreen extends StatefulWidget {
  final int linkID;

  SoftwareWebViewScreen({required this.linkID});

  @override
  _SoftwareWebViewScreenState createState() => _SoftwareWebViewScreenState();
}

class _SoftwareWebViewScreenState extends State<SoftwareWebViewScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _idController = TextEditingController();
  final ApiService apiService = ApiService();

  InAppWebViewController? webViewController;
  PullToRefreshController? pullToRefreshController;

  String? _webUrl;
  String? _savedIdNumber;
  String? _profilePictureUrl;
  String? _firstName;
  String? _surName;
  bool _isLoading = true;
  int? _currentLanguageFlag;
  double _progress = 0;
  String? _phOrJp;

  @override
  void initState() {
    super.initState();

    pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(
        color: Colors.blue,
      ),
      onRefresh: () async {
        if (webViewController != null) {
          await webViewController!.reload();
        }
      },
    );
    _fetchAndLoadUrl();
    _loadIdNumber();
    _fetchProfile();
    _loadCurrentLanguageFlag();
    _loadPhOrJp();

    AutoUpdate.checkForUpdate(context);
  }
  Future<void> _loadPhOrJp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _phOrJp = prefs.getString('phorjp');
    });
  }

  Future<void> _loadIdNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _savedIdNumber = prefs.getString('IDNumber');
    if (_savedIdNumber != null) {
      setState(() {
        _idController.text = _savedIdNumber!;
      });
    }
  }

  Future<void> _fetchProfile() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idNumber = prefs.getString('IDNumber');

    if (idNumber != null) {
      try {
        final profileData = await apiService.fetchProfile(idNumber);
        if (profileData["success"] == true) {
          String profilePictureFileName = profileData["picture"];

          String primaryUrl = "${ApiService.apiUrls[0]}V4/11-A%20Employee%20List%20V2/profilepictures/$profilePictureFileName";
          bool isPrimaryUrlValid = await _isImageAvailable(primaryUrl);

          String fallbackUrl = "${ApiService.apiUrls[1]}V4/11-A%20Employee%20List%20V2/profilepictures/$profilePictureFileName";
          bool isFallbackUrlValid = await _isImageAvailable(fallbackUrl);

          setState(() {
            _firstName = profileData["firstName"];
            _surName = profileData["surName"];
            _profilePictureUrl = isPrimaryUrlValid ? primaryUrl : isFallbackUrlValid ? fallbackUrl : null;
            _currentLanguageFlag = profileData["languageFlag"];
          });
        }
      } catch (e) {
        print("Error fetching profile: $e");
      }
    }
  }

  Future<bool> _isImageAvailable(String url) async {
    try {
      final response = await http.head(Uri.parse(url)).timeout(Duration(seconds: 2));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<void> _saveIdNumber() async {
    String newIdNumber = _idController.text.trim();

    if (newIdNumber.isEmpty) {
      setState(() {
        _idController.text = _savedIdNumber ?? '';
      });

      Fluttertoast.showToast(
        msg: "ID Number cannot be empty!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    if (newIdNumber == _savedIdNumber) {
      Fluttertoast.showToast(
        msg: "Edit the ID number first!",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.orange,
        textColor: Colors.white,
        fontSize: 16.0,
      );
      return;
    }

    try {
      bool idExists = await apiService.checkIdNumber(newIdNumber);

      if (idExists) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('IDNumber', newIdNumber);
        _savedIdNumber = newIdNumber;

        Fluttertoast.showToast(
          msg: "ID Number saved successfully!",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        _fetchAndLoadUrl();
        _fetchProfile();
      } else {
        Fluttertoast.showToast(
          msg: "This ID Number does not exist in the employee database.",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        setState(() {
          _idController.text = _savedIdNumber ?? '';
        });
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: "Failed to verify ID Number",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
      );

      setState(() {
        _idController.text = _savedIdNumber ?? '';
      });
    }
  }

  Future<void> _fetchAndLoadUrl() async {
    try {
      String url = await apiService.fetchSoftwareLink(widget.linkID);
      if (mounted) {
        setState(() {
          _webUrl = url;
          _isLoading = true;
        });
        if (webViewController != null) {
          await webViewController!.loadUrl(urlRequest: URLRequest(url: WebUri(url)));
        }
      }
    } catch (e) {
      debugPrint("Error fetching link: $e");
    }
  }

  Future<void> _loadCurrentLanguageFlag() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentLanguageFlag = prefs.getInt('languageFlag');
    });
  }

  Future<void> _updateLanguageFlag(int flag) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idNumber = prefs.getString('IDNumber');

    if (idNumber != null) {
      setState(() {
        _currentLanguageFlag = flag;
      });
      try {
        await apiService.updateLanguageFlag(idNumber, flag);
        await prefs.setInt('languageFlag', flag);

        if (webViewController != null) {
          await webViewController!.reload();
        }
      } catch (e) {
        print("Error updating language flag: $e");
      }
    }
  }

  Future<void> _updatePhOrJp(String value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('phorjp', value);
    setState(() {
      _phOrJp = value;
    });

    String? idNumber = prefs.getString('IDNumber');
    String? idNumberJP = prefs.getString('IDNumberJP');

    if (value == "ph") {
      if (idNumber == null) {
        Navigator.pushReplacementNamed(context, '/idInput');
      } else {
        Navigator.pushReplacementNamed(context, '/webView');
      }
    } else if (value == "jp") {
      if (idNumberJP == null) {
        Navigator.pushReplacementNamed(context, '/idInputJP');
      } else {
        Navigator.pushReplacementNamed(context, '/webViewJP');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (webViewController != null && await webViewController!.canGoBack()) {
      webViewController!.goBack();
      return false;
    } else {
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        resizeToAvoidBottomInset: false,
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight - 20),
          child: SafeArea(
            child: AppBar(
              backgroundColor: Color(0xFF3452B4),
              centerTitle: true,
              toolbarHeight: kToolbarHeight - 20,
              leading: Padding(
                padding: const EdgeInsets.only(left: 10.0),
                child: IconButton(
                  icon: Icon(
                    Icons.settings,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    _scaffoldKey.currentState?.openDrawer();
                  },
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 10.0),
                  child: IconButton(
                    icon: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                      alignment: Alignment.center,
                      width: 36,
                      height: 36,
                      child: Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    onPressed: () {
                      if (Platform.isIOS) {
                        exit(0);
                      } else {
                        SystemNavigator.pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        drawer: SizedBox(
          width: MediaQuery.of(context).size.width * 0.70,
          child: Drawer(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.zero,
            ),
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            color: Color(0xFF2053B3),
                            padding: EdgeInsets.only(top: 50, bottom: 20),
                            child: Column(
                              children: [
                                Align(
                                  alignment: Alignment.center,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: Colors.white,
                                    backgroundImage: _profilePictureUrl != null
                                        ? NetworkImage(_profilePictureUrl!)
                                        : null,
                                    child: _profilePictureUrl == null
                                        ? FlutterLogo(size: 60)
                                        : null,
                                  ),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  _firstName != null && _surName != null
                                      ? "$_firstName $_surName"
                                      : "User Name",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              children: [
                                Text(
                                  "Language",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 25),
                                GestureDetector(
                                  onTap: () => _updateLanguageFlag(1),
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        'assets/images/americanFlag.gif',
                                        width: 40,
                                        height: 40,
                                      ),
                                      if (_currentLanguageFlag == 1)
                                        Container(
                                          height: 2,
                                          width: 40,
                                          color: Colors.blue,
                                        ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 30),
                                GestureDetector(
                                  onTap: () => _updateLanguageFlag(2),
                                  child: Column(
                                    children: [
                                      Image.asset(
                                        'assets/images/japaneseFlag.gif',
                                        width: 40,
                                        height: 40,
                                      ),
                                      if (_currentLanguageFlag == 2)
                                        Container(
                                          height: 2,
                                          width: 40,
                                          color: Colors.blue,
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "User",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 5),
                                TextField(
                                  controller: _idController,
                                  decoration: InputDecoration(
                                    hintText: "ID Number",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _saveIdNumber,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFF2053B3),
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      "Save",
                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Text(
                          "Country",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 25),
                        GestureDetector(
                          onTap: () => _updatePhOrJp("ph"),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/philippines.png',
                                width: 40,
                                height: 40,
                              ),
                              if (_phOrJp == "ph")
                                Container(
                                  height: 2,
                                  width: 40,
                                  color: Colors.blue,
                                ),
                            ],
                          ),
                        ),
                        SizedBox(width: 30),
                        GestureDetector(
                          onTap: () => _updatePhOrJp("jp"),
                          child: Column(
                            children: [
                              Image.asset(
                                'assets/images/japan.png',
                                width: 40,
                                height: 40,
                              ),
                              if (_phOrJp == "jp")
                                Container(
                                  height: 2,
                                  width: 40,
                                  color: Colors.blue,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              if (_webUrl != null)
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(_webUrl!)),
                  initialSettings: InAppWebViewSettings(
                    mediaPlaybackRequiresUserGesture: false,
                    javaScriptEnabled: true,
                    useHybridComposition: true,
                    allowsInlineMediaPlayback: true,
                    allowContentAccess: true,
                    allowFileAccess: true,
                    javaScriptCanOpenWindowsAutomatically: true,
                    allowUniversalAccessFromFileURLs: true,
                    allowFileAccessFromFileURLs: true,
                  ),
                  pullToRefreshController: pullToRefreshController,
                  onWebViewCreated: (controller) {
                    webViewController = controller;
                  },
                  onLoadStart: (controller, url) {
                    setState(() {
                      _isLoading = true;
                      _progress = 0;
                    });
                  },
                  onLoadStop: (controller, url) {
                    pullToRefreshController?.endRefreshing();
                    setState(() {
                      _isLoading = false;
                      _progress = 1;
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    setState(() {
                      _progress = progress / 100;
                    });
                  },
                  onReceivedServerTrustAuthRequest: (controller, challenge) async {
                    return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
                  },
                  onPermissionRequest: (controller, request) async {
                    List<Permission> permissionsToRequest = [];

                    if (request.resources.contains(PermissionResourceType.CAMERA)) {
                      permissionsToRequest.add(Permission.camera);
                    }
                    if (request.resources.contains(PermissionResourceType.MICROPHONE)) {
                      permissionsToRequest.add(Permission.microphone);
                    }

                    Map<Permission, PermissionStatus> statuses = await permissionsToRequest.request();
                    bool allGranted = statuses.values.every((status) => status.isGranted);

                    return PermissionResponse(
                      resources: request.resources,
                      action: allGranted ? PermissionResponseAction.GRANT : PermissionResponseAction.DENY,
                    );
                  },
                  onDownloadStartRequest: (controller, url) async {
                    Fluttertoast.showToast(
                      msg: "Downloading: ${url.url}",
                      toastLength: Toast.LENGTH_SHORT,
                      gravity: ToastGravity.BOTTOM,
                    );

                    PermissionStatus storageStatus = await Permission.storage.request();
                    if (!storageStatus.isGranted) {
                      Fluttertoast.showToast(
                        msg: "Storage permission denied! Download may fail.",
                        toastLength: Toast.LENGTH_SHORT,
                        gravity: ToastGravity.BOTTOM,
                        backgroundColor: Colors.red,
                      );
                    }
                  },
                ),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
            ],
          ),
        ),
      ),
    );
  }
}