import 'package:flutter/material.dart';
import 'package:flutter_zxing/flutter_zxing.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          ReaderWidget(
            onScan: (result) async {
              if (result != null && result.toString().isNotEmpty) {
                String barcodeResult = result.toString();
                print(
                    "Scan result: $barcodeResult"); // Tambahkan ini untuk debugging
                _handleScanResult(barcodeResult);
              }
            },
          ),
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
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(isFlashOn ? Icons.flash_off : Icons.flash_on,
                  color: Colors.white),
              onPressed: () {
                setState(() {
                  isFlashOn = !isFlashOn;
                });
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
                    MaterialPageRoute(builder: (context) => GetStartedPage()),
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

    print(
        "Handling scan result: $barcodeScanRes"); // Tambahkan ini untuk debugging
    if (barcodeScanRes.isNotEmpty &&
        barcodeScanRes != 'Gagal mendapatkan barcode.') {
      _navigateToScanResultPage(barcodeScanRes);
    } else {
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

      print(
          "Navigating to ScanResultPage with code: $code"); // Tambahkan ini untuk debugging

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
