import 'dart:convert';
import 'package:airplane_thoriq/ui/pages/qrviewexample.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ScanResultPage extends StatefulWidget {
  final String rawpnr;
  final String token;

  const ScanResultPage({
    Key? key,
    required this.rawpnr,
    required this.token,
  }) : super(key: key);

  @override
  _ScanResultPageState createState() => _ScanResultPageState();
}

class _ScanResultPageState extends State<ScanResultPage> {
  late String _token;
  bool _isLoading = true;
  Map<String, dynamic> _scanResult = {};

  @override
  void initState() {
    super.initState();
    _initializeTokenAndSendData();
  }

  Future<void> _initializeTokenAndSendData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');
    String? tokenExpiry = prefs.getString('token_expiry');

    if (token != null && tokenExpiry != null) {
      DateTime expiryDate = DateTime.parse(tokenExpiry);
      if (DateTime.now().isBefore(expiryDate)) {
        setState(() {
          _token = token;
        });
        await _sendDataToAPI(token);
      } else {
        bool tokenRefreshed = await _refreshToken();
        if (tokenRefreshed) {
          setState(() {
            _token = prefs.getString('token')!;
          });
          await _sendDataToAPI(prefs.getString('token')!);
        } else {
          _showSnackBar('Token expired. Please log in again.');
        }
      }
    } else {
      _showSnackBar('No token found. Please log in again.');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => QRViewExample()),
        );
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Scan Result'),
        ),
        body: Center(
          child: _isLoading
              ? CircularProgressIndicator()
              : SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 5),
                        width: 400,
                        height: 100,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/injourney_colour.png'),
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildField(
                          'Flight Number', _scanResult['flight_number'] ?? ''),
                      _buildField(
                          'Flight Date', _scanResult['flight_date'] ?? ''),
                      _buildField('Origin', _scanResult['origin'] ?? ''),
                      _buildField(
                          'Destination', _scanResult['destination'] ?? ''),
                      _buildField('Last Name', _scanResult['last_name'] ?? ''),
                      _buildField(
                          'First Name', _scanResult['first_name'] ?? ''),
                      _buildField('Seat Number', _scanResult['seat_num'] ?? ''),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      children: [
        Text(
          '$label:',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(fontSize: 16),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Future<void> _sendDataToAPI(String token) async {
    String apiUrl = 'https://dashapigcp.travelin.co.id/external/validate/pnr';
    String devid = 'mobile-external';

    String guid = _hashGuid(token, devid);

    String basicAuthCredentials = base64Encode(
        utf8.encode('external-mobile-apps:FVNUxQlNhcUBhsMsqBez9yyN'));

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Basic $basicAuthCredentials',
          'Content-Type': 'application/json',
          'guid': guid,
        },
        body: jsonEncode({
          'rawPnr': widget.rawpnr,
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        print('Data received from API: $data'); // Debug statement

        // Access pnrDetail from the API response
        var pnrDetail = data['data']['pnrDetail'];

        setState(() {
          _scanResult = {
            'flight_number': pnrDetail['flight_number']?.toString() ?? '',
            'flight_date': pnrDetail['flight_date']?.toString() ?? '',
            'origin': pnrDetail['origin']?.toString() ?? '',
            'destination': pnrDetail['destination']?.toString() ?? '',
            'last_name': pnrDetail['last_name']?.toString() ?? '',
            'first_name': pnrDetail['first_name']?.toString() ?? '',
            'seat_num': pnrDetail['seat_num']?.toString() ?? '',
          };
        });
        print(
            'Scan result after setting state: $_scanResult'); // Debug statement
        _showSnackBar('Data sent successfully');
      } else {
        _showSnackBar('Failed to send data');
      }
    } catch (e) {
      print('Error occurred: $e'); // Debug statement
      _showSnackBar('An error occurred');
    }
  }

  String _hashGuid(String token, String devid) {
    String combinedString = '$devid-$token';
    var bytes = utf8.encode(combinedString);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> _refreshToken() async {
    String refreshTokenUrl =
        'https://dashapigcp.travelin.co.id/external/validate/pnr';
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String basicAuthCredentials = base64Encode(
        utf8.encode('external-mobile-apps:FVNUxQlNhcUBhsMsqBez9yyN'));

    try {
      var response = await http.post(
        Uri.parse(refreshTokenUrl),
        headers: {
          'Authorization': 'Basic $basicAuthCredentials',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'token': prefs.getString('token'),
        }),
      );

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        if (data['code'] == 200 && data['data'].containsKey('token')) {
          String newToken = data['data']['token'];
          await prefs.setString('token', newToken);
          await prefs.setString('token_expiry',
              DateTime.now().add(Duration(hours: 1)).toIso8601String());
          return true;
        }
      }
    } catch (e) {
      print('Error: $e');
    }

    return false;
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
