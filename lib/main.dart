import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('scan_history');
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      theme: const CupertinoThemeData(brightness: Brightness.light),
      home: CupertinoMainPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CupertinoMainPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.qrcode_viewfinder),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.clock),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.person),
            label: 'Profile',
          ),
        ],
      ),
      tabBuilder: (context, index) {
        switch (index) {
          case 0:
            return CupertinoScanPage();
          case 1:
            return CupertinoHistoryPage();
          case 2:
            return CupertinoProfilePage();
          default:
            return Container();
        }
      },
    );
  }
}

class CupertinoScanPage extends StatefulWidget {
  @override
  _CupertinoScanPageState createState() => _CupertinoScanPageState();
}

class _CupertinoScanPageState extends State<CupertinoScanPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  bool isFrontCamera = false;

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  void _toggleCamera() {
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
    controller?.flipCamera();
  }

  void _pickImageAndDecode() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      // Handle decoding here (additional implementation needed for external packages)
      _showResultDialog('Feature to decode image QR coming soon!');
    } else {
      _showResultDialog('No image selected.');
    }
  }

  void _showResultDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('QR Code Result'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('QR Scanner'),
      ),
      child: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
              key: qrKey,
              onQRViewCreated: _onQRViewCreated,
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (result != null)
                  Column(
                    children: [
                      Text('Result: ${result!.code ?? 'No data'}'),
                      const SizedBox(height: 10),
                      CupertinoButton(
                        child: const Text('Copy Link'),
                        onPressed: () {
                          if (result?.code != null) {
                            Clipboard.setData(
                                ClipboardData(text: result!.code!));
                            _showResultDialog('Link copied to clipboard!');
                          } else {
                            _showResultDialog('No QR code to copy.');
                          }
                        },
                      ),
                    ],
                  )
                else
                  const Text('Scan a QR code'),
                const SizedBox(height: 10),
                CupertinoButton.filled(
                  child: const Text('Toggle Camera'),
                  onPressed: _toggleCamera,
                ),
                const SizedBox(height: 10),
                CupertinoButton(
                  child: const Text('Upload Image'),
                  onPressed: _pickImageAndDecode,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      Hive.box('scan_history').add(scanData.code);
    });
  }
}

class CupertinoHistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final historyBox = Hive.box('scan_history');
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Scan History'),
      ),
      child: ListView.builder(
        itemCount: historyBox.length,
        itemBuilder: (context, index) {
          final qrData = historyBox.getAt(index) as String;
          return ListTile(
            title: Text(qrData),
          );
        },
      ),
    );
  }
}

class CupertinoProfilePage extends StatefulWidget {
  @override
  _CupertinoProfilePageState createState() => _CupertinoProfilePageState();
}

class _CupertinoProfilePageState extends State<CupertinoProfilePage> {
  String inputText = '';

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Profile'),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CupertinoTextField(
              placeholder: 'Enter text to generate QR',
              onChanged: (value) => setState(() => inputText = value),
            ),
          ],
        ),
      ),
    );
  }
}
