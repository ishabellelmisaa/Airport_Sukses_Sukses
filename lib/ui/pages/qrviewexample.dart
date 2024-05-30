import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_sdk/dynamsoft_barcode.dart';
import 'package:flutter_barcode_sdk/flutter_barcode_sdk.dart';
import 'package:camera/camera.dart';
import 'ScanResultPage.dart';
import 'get_started_page.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  bool isNavigating = false;
  bool isFlashOn = false;
  late CameraController _cameraController;
  late FlutterBarcodeSdk barcodeSdk;
  bool _isScanning = false;

  @override
  void initState() {
    super.initState();
    barcodeSdk = FlutterBarcodeSdk(); // Inisialisasi BarcodeReader
    barcodeSdk.setBarcodeFormats(BarcodeFormat.ALL);
    _setDeblurLevel(5); // Set deblur level
    _initializeCamera();
  }

  Future<void> _setDeblurLevel(int level) async {
    String params = await barcodeSdk.getParameters();
    dynamic obj = jsonDecode(params);
    if (obj['ImageParameter'] != null) {
      obj['ImageParameter']['DeblurLevel'] = level;
    } else {
      obj['deblurLevel'] = level;
    }
    await barcodeSdk.setParameters(json.encode(obj));
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final camera = cameras.first;
    _cameraController = CameraController(camera, ResolutionPreset.high);

    await _cameraController.initialize();
    _cameraController.startImageStream((CameraImage image) {
      if (!_isScanning) {
        _isScanning = true;
        _processCameraImage(image);
      }
    });
    setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      // Convert CameraImage to Uint8List
      final WriteBuffer allBytes = WriteBuffer();
      for (Plane plane in image.planes) {
        allBytes.putUint8List(plane.bytes);
      }
      final bytes = allBytes.done().buffer.asUint8List();

      // Decode the image buffer
      final List<BarcodeResult> results = await barcodeSdk.decodeImageBuffer(
        bytes,
        image.width,
        image.height,
        image.planes[0].bytesPerRow,
        ImagePixelFormat.IPF_NV21.index,
      );

      if (results.isNotEmpty) {
        String barcodeResult = results.first.text;
        print("Scan result: $barcodeResult");
        _handleScanResult(barcodeResult);
      }
    } catch (e) {
      print("Error decoding image buffer: $e");
    } finally {
      _isScanning = false;
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    //barcodeSdk.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _cameraController.value.isInitialized
              ? CameraPreview(_cameraController)
              : Center(child: CircularProgressIndicator()),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GetStartedPage(),
                    ),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text('Cancel'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScanResult(String barcodeScanRes) {
    if (!mounted) return;

    print("Handling scan result: $barcodeScanRes");
    if (barcodeScanRes.isNotEmpty) {
      _navigateToScanResultPage(barcodeScanRes);
    } else {
      print("Scan result is empty or invalid");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => GetStartedPage()),
        (route) => false,
      );
    }
  }

  void _navigateToScanResultPage(String code) async {
    if (!isNavigating) {
      setState(() {
        isNavigating = true;
      });

      print("Navigating to ScanResultPage with code: $code");

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultPage(
            rawpnr: code,
            token: '', // Pastikan ini diisi dengan token yang valid
          ),
        ),
      );
      setState(() {
        isNavigating = false;
      });
    }
  }
}
