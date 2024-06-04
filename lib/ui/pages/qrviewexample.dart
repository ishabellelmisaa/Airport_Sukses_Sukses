import 'dart:convert';
import 'dart:typed_data';
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
  CameraController? _cameraController; // Use nullable type
  late FlutterBarcodeSdk _barcodeReader;
  bool _isScanning = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeBarcodeReader();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.first;
      _cameraController = CameraController(camera, ResolutionPreset.high);
      await _cameraController!.initialize();
      setState(() {});

      _cameraController!.startImageStream((CameraImage image) {
        if (!_isScanning && !_isProcessing) {
          _isScanning = true;
          _processCameraImage(image);
        }
      });
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _initializeBarcodeReader() async {
    _barcodeReader = FlutterBarcodeSdk();
    await _barcodeReader.setLicense(
        'DLS2eyJoYW5kc2hha2VDb2RlIjoiMjAwMDAxLTE2NDk4Mjk3OTI2MzUiLCJvcmdhbml6YXRpb25JRCI6IjIwMDAwMSIsInNlc3Npb25QYXNzd29yZCI6IndTcGR6Vm05WDJrcEQ5YUoifQ==');
    await _barcodeReader.init();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      final Uint8List bytes = _concatenatePlanes(image.planes);
      final List<BarcodeResult> results =
          await _barcodeReader.decodeImageBuffer(
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

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final List<Uint8List> bytesList =
        planes.map((plane) => plane.bytes).toList();
    final int totalLength =
        bytesList.fold(0, (prev, bytes) => prev + bytes.length);
    final Uint8List concatenatedBytes = Uint8List(totalLength);
    int offset = 0;
    for (final Uint8List bytes in bytesList) {
      concatenatedBytes.setRange(offset, offset + bytes.length, bytes);
      offset += bytes.length;
    }
    return concatenatedBytes;
  }

  @override
  void dispose() {
    _cameraController?.dispose(); // Use null-aware operator
    super.dispose();
  }

  void _handleScanResult(String barcodeScanRes) {
    if (!mounted || _isProcessing) return;

    print("Handling scan result: $barcodeScanRes");
    if (barcodeScanRes.isNotEmpty) {
      _isProcessing = true;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ScanResultPage(
            rawpnr: barcodeScanRes,
            token: '', // Pastikan ini diisi dengan token yang valid
          ),
        ),
      ).then((_) {
        _isProcessing = false;
      });
    } else {
      print("Scan result is empty or invalid");
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => GetStartedPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _cameraController != null && _cameraController!.value.isInitialized
              ? CameraPreview(_cameraController!)
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
}
