import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class EmergencyBooking extends StatefulWidget {
  @override
  _EmergencyBookingState createState() => _EmergencyBookingState();
}

class _EmergencyBookingState extends State<EmergencyBooking> {
  final _formKey = GlobalKey<FormState>();
  String patientName = '';
  String email = '';
  String phoneNumber = '';
  String ambulanceType = 'Standard Ambulance';
  bool useCurrentLocation = false;
  bool useMapForDestination = false;
  LatLng? _currentLocation;
  LatLng? _hospitalLocation;
  LatLng? _destinationLocation;
  double _currentZoom = 15.0;
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  double? _estimatedCost;
  bool isLoading = false;
  bool isSuccessBooked = false;
  bool updateLocation = false;
  bool getDriverLocation = true;
  String _driverName = '';
  String _driverPhone = '';
  String? driverName;
  String? driverPhone;
  LatLng? _driverLocation;
  Timer? _locationTimer;
  String _bookingId = '';
  String _driverId = '';
  bool activeLocation = false;
  int? driverId2;
  int? patientId;
  int? bookingId1;
  @override
  void initState() {
    super.initState();
    _loadHospitals();
    _startTrackingLocation();
    _loadBookingStatus();
  }

  Future<void> _getDriverLocationAndUpdateMap(int? driverId) async {
    print('Đang lấy vị trí tài xế...');
    try {
      // Gọi API với driverId được truyền qua đường dẫn
      final response = await http.get(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/patientlocation/get-driver-location/$driverId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final double latitude = data['driverLatitude'];
        final double longitude = data['driverLongitude'];
        LatLng driverLocation = LatLng(latitude, longitude);
        print(driverLocation);

        setState(() {
          _driverLocation = driverLocation;
          // Cập nhật vị trí tài xế trên bản đồ nếu cần
          // _mapController.move(_driverLocation!, _currentZoom);
        });
      } else {
        print(
            'Failed to load driver location. Status Code: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching driver location: $e');
    }
  }

  String generatePassword() {
    const String lowerCase = 'abcdefghijklmnopqrstuvwxyz';
    const String upperCase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const String numbers = '0123456789';
    const String specialCharacters = '@#\$%^&*()_+!';

    const String allCharacters =
        lowerCase + upperCase + numbers + specialCharacters;
    final Random random = Random();

    // Generate the password
    String password = List.generate(8, (index) {
      return allCharacters[random.nextInt(allCharacters.length)];
    }).join();

    return password;
  }

  Future<void> callPhoneNumber(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );

    if (await canLaunch(launchUri.toString())) {
      await launch(launchUri.toString());
    } else {
      throw 'Could not launch $launchUri';
    }
  }

  Future<void> _saveMarkerPositions() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setDouble('currentLat', _currentLocation!.latitude);
    prefs.setDouble('currentLng', _currentLocation!.longitude);
    prefs.setDouble('destinationLat', _destinationLocation!.latitude);
    prefs.setDouble('destinationLng', _destinationLocation!.longitude);
    prefs.setString('driverName', _driverName);
    prefs.setString('driverPhone', _driverPhone);
    prefs.setString('bookingId', _bookingId);
    prefs.setString('driverId', _driverId);
  }

  Future<void> _loadMarkerPositions() async {
    final prefs = await SharedPreferences.getInstance();
    final double? currentLat = prefs.getDouble('currentLat');
    final double? currentLng = prefs.getDouble('currentLng');
    final double? destinationLat = prefs.getDouble('destinationLat');
    final double? destinationLng = prefs.getDouble('destinationLng');
    final String? driverName = prefs.getString('driverName');
    final String? driverPhone = prefs.getString('driverPhone');
    final String? bookingId = prefs.getString('bookingId');
    final String? driverId = prefs.getString('driverId');
    setState(() {
      _currentLocation = LatLng(currentLat!, currentLng!);
      _destinationLocation = LatLng(destinationLat!, destinationLng!);
      _driverName = driverName!;
      _driverPhone = driverPhone!;
      _bookingId = bookingId!;
      _driverId = driverId!;
    });
    print(_driverId);
    _locationTimer = Timer.periodic(Duration(seconds: 5), (Timer timer) {
      try {
        print("id tai xe " + driverId2.toString() + "  lasy vi tri tai xe");
        _getDriverLocationAndUpdateMap(driverId2);
        if (updateLocation == false) {
          if(_currentLocation != null){
            print(_currentLocation);
            _sendLocationUpdate();
          }
        }
      } catch (e) {
        print('Error converting driver ID to int: $e');
      }
    });
  }

  void _loadBookingStatus() async {
    print('load booking status');
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSuccessBooked = prefs.getBool('isSuccessBooked') ?? false;
    });
  }

  void _clearBookingStatus() async {
    updateLocation = true;
    _upDateBookingStatus(bookingId1);
    print("=== Cập nhật trạng thái driver sau khi clear booking====");
    print(driverId2);
    String status1 = "Active";
    await _updateDriverStatus(driverId2,
        status1);
    print('chuyen trang thai thanh da xong');
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('isSuccessBooked');
    print("");
    // Cập nhật trạng thái ban đầu
    if (_locationTimer != null) {
      _locationTimer!.cancel();
      print("Timer stopped");
    }
    setState(() {
      isSuccessBooked = false;
      _currentLocation = null;
      _hospitalLocation = null;
      _destinationLocation = null;
      _driverName = '';
      _driverPhone = '';
    });

    // Gọi hàm cập nhật trạng thái đặt chỗ

    // Cập nhật trạng thái driver sau khi clear booking'
     // Chuyển driverId thành chuỗi và đợi cập nhật trạng thái
  }

  Future<void> _updateDriverStatus(int? driverId, String status) async {
    try {
      print("driver_id" + driverId.toString() + "status la:" + status);
      final response = await http.post(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/drivers/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': driverId,
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        print("Driver status updated successfully!");
      } else {
        print('Error: ${response.statusCode}, ${response.body}');
      }
    } catch (error) {
      print('Exception: $error');
    }
  }

  Future<void> _upDateBookingStatus(int? bookingId1) async {
    print('thuc hien goi aPi chuyen trang thai booking sang complete');
    try {
      String status = 'Completed';

      print('Booking ID:' + bookingId1.toString());
      print('Booking Status: $status');

      // Thay thế URL API của bạn vào đây
      final response = await http.post(
        Uri.parse('https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/bookings/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'bookingStatus': status,
          'bookingId': bookingId1,
        }),
      );

      if (response.statusCode == 200) {
        showTemporaryMessage(context, "Emergency booking complete!");
      } else {
        showTemporaryMessage(context, "Error during submit, Please try again.");
        print('Error: ${response.statusCode}, ${response.body}');
      }
    } catch (error) {
      showTemporaryMessage(context, "Error during submit, Please try again.");
      print('Exception: $error');
    }
  }


  // Danh sách bệnh viện và danh sách gợi ý
  List<Map<String, dynamic>> allHospitals = [];
  TextEditingController hospitalNameController = TextEditingController();
  TextEditingController destinationController = TextEditingController();

  final List<String> ambulanceTypes = [
    'Standard Ambulance',
    'Advanced Life Support Ambulance'
  ];

  OverlayEntry? currentOverlayEntry;

  void showTemporaryMessage(BuildContext context, String message) {
    if (currentOverlayEntry != null) {
      currentOverlayEntry!.remove();
    }

    currentOverlayEntry = OverlayEntry(
      builder: (context) => Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.only(left: 12, right: 12),
            decoration: BoxDecoration(
              color: blackColor.withOpacity(0.7),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              message,
              style: const TextStyle(
                  color: whiteColor,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(currentOverlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      currentOverlayEntry?.remove();
      currentOverlayEntry = null;
    });
  }

  Future<void> _loadHospitals() async {
    print('tai danh sach benh vien');
    try {
      final response = await http.get(Uri.parse(
          'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/hospitals/all'));
      if (response.statusCode == 200) {
        List<dynamic> hospitalsData = json.decode(response.body);
        setState(() {
          allHospitals = hospitalsData
              .map((e) => {
                    'hospitalName': e['hospitalName'],
                    'latitude': e['latitude'],
                    'longitude': e['longitude'],
                  })
              .toList();
        });
      } else {
        print('Failed to load hospitals');
      }
    } catch (e) {
      print('Error loading hospitals: $e');
    }
  }

  Future<void> _sendLocationUpdate() async {
    print('gui vi tri GPS len server');
    if (_currentLocation != null) {
      final response = await http.post(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/patientlocation/update'),
        // Đường dẫn tới API cập nhật vị trí
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'patientId':patientId,
          'latitude': _currentLocation!.latitude,
          'longitude': _currentLocation!.longitude,
          // Thêm các dữ liệu cần thiết khác nếu có
        }),
      );

      if (response.statusCode == 200) {
        print("Location update successful");
      } else {
        print("Error updating location: ${response.statusCode}");
      }
    }
  }

  void _startTrackingLocation() {
    print('cap nhat vi tri lien tuc len map ');
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });
      print(_currentLocation);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentLocation != null) {
          _mapController.move(_currentLocation!, _currentZoom);
        }
      });
    });
  }

  void _showHospitalSuggestions({bool isDestination = false}) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return ListView.builder(
          itemCount: allHospitals.length,
          itemBuilder: (context, index) {
            return ListTile(
              title: Text(allHospitals[index]['hospitalName']),
              onTap: () {
                setState(() {
                  if (isDestination) {
                    // Cập nhật vị trí điểm đến
                    destinationController.text =
                        allHospitals[index]['hospitalName'];
                    _destinationLocation = LatLng(
                      allHospitals[index]['latitude'],
                      allHospitals[index]['longitude'],
                    );
                    _mapController.move(_destinationLocation!, _currentZoom);
                  } else {
                    // Tắt sử dụng vị trí hiện tại và cập nhật vị trí điểm đi
                    useCurrentLocation = false; // Tắt vị trí hiện tại
                    hospitalNameController.text =
                        allHospitals[index]['hospitalName'];
                    _hospitalLocation = LatLng(
                      allHospitals[index]['latitude'],
                      allHospitals[index]['longitude'],
                    );
                    _currentLocation =
                        _hospitalLocation; // Cập nhật _currentLocation thành vị trí bệnh viện
                    _mapController.move(_hospitalLocation!, _currentZoom);
                  }
                  _calculateCost(); // Tính lại chi phí sau khi chọn vị trí
                });
                Navigator.pop(context);
              },
            );
          },
        );
      },
    );
  }

  Future<void> _calculateCost() async {
    print('ham tinh tien');
    setState(() {
      isLoading = true;
    });
    if (_currentLocation != null && _destinationLocation != null) {
      // Gửi request tới API tính chi phí
      final response = await http.post(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/bookings/calculate-cost'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'startLatitude': _currentLocation!.latitude,
          'startLongitude': _currentLocation!.longitude,
          'destinationLatitude': _destinationLocation!.latitude,
          'destinationLongitude': _destinationLocation!.longitude,
        }),
      );

      if (response.statusCode == 200) {
        final costData = json.decode(response.body);
        print(response.body);
        final distance = costData['distance'];
        final cost = costData['costInUSD'];

        setState(() {
          _estimatedCost = cost;
        });

        showTemporaryMessage(context,
            'Distance: ${distance.toStringAsFixed(2)} km - Estimated cost: ${cost.toStringAsFixed(2)} USD.');
      } else {
        showTemporaryMessage(context, 'Error in calculating estimated cost.');
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _submitForm() async {
    setState(() {
      isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      print('kiem tra email');

      // Kiểm tra email
      final checkEmailResponse = await http.post(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/patients/check'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (checkEmailResponse.statusCode == 200) {
        final emailExists = json.decode(checkEmailResponse.body);

        if (emailExists) {
          print('email da co thuc hien cap nhat thong tin');
          // Cập nhật thông tin bệnh nhân
          final updateUserResponse = await http.put(
            Uri.parse(
                'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/patients/update'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'phoneNumber': phoneNumber,
              'patientName': patientName,
            }),
          );

          if (updateUserResponse.statusCode == 200) {
            final updatePatientData = json.decode(updateUserResponse.body);

            // Lấy patientId từ phản hồi
            final patientIdUpdate = updatePatientData['patientId']; // Đảm bảo DTO có trường này
            patientId = patientIdUpdate;
            await _bookEmergencyAmbulance();
          } else {
            print('Error fetching patient data');
          }
        } else {
          print('khong co email , dang ki benh nhan moi');
          // Đăng ký bệnh nhân mới
          final registerUserResponse = await http.post(
            Uri.parse(
                'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/patients/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'phoneNumber': phoneNumber,
              'patientName': patientName,
              'password': generatePassword(),
            }),
          );

          if (registerUserResponse.statusCode == 201) {;
          final registeredPatientData = json.decode(registerUserResponse.body);

          // Lấy patientId từ phản hồi
          final patientIdRegister = registeredPatientData['patientId']; // Đảm bảo DTO có trường này
          patientId = patientIdRegister;
          print('Registered patientId: $patientId');
            await _bookEmergencyAmbulance();
          } else {
            print('Error while registering new user');
          }
        }
      } else {
        print('Error checking email');
      }
    }
  }

  Future<void> _bookEmergencyAmbulance() async {
    print('thuc hien dat don booking');
    LatLng? bookingLocation;
    String? pickupAddress;

    if (useCurrentLocation && _currentLocation != null) {
      bookingLocation = _currentLocation;
      pickupAddress = 'Current location';
    } else if (hospitalNameController.text.isNotEmpty) {
      final selectedHospital = allHospitals.firstWhere((hospital) =>
          hospital['hospitalName'] == hospitalNameController.text);
      bookingLocation =
          LatLng(selectedHospital['latitude'], selectedHospital['longitude']);
      pickupAddress = hospitalNameController.text;
    }

    if (bookingLocation != null && _estimatedCost != null) {
      final bookingData = {
        'patient': {'email': email},
        'bookingType': 'Emergency',
        'pickupAddress': pickupAddress,
        'latitude': bookingLocation.latitude,
        'longitude': bookingLocation.longitude,
        'pickupTime': DateTime.now().toIso8601String(),
        'destinationLatitude': _destinationLocation?.latitude,
        'destinationLongitude': _destinationLocation?.longitude,
        'cost': _estimatedCost, // Thêm giá vào dữ liệu đặt xe
        'ambulanceType': ambulanceType, // Loại xe cứu thương
      };


      try {
        final response = await http.post(
          Uri.parse(
              'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/bookings/emergency'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(bookingData),
        );
        print(bookingData.toString());
        if (response.statusCode == 200 || response.statusCode == 201) {
          final bookingResponse = json.decode(response.body); // Lấy phản hồi
          bookingId1 =
              bookingResponse['bookingId'];
          print(bookingId1.toString() + " =========== booking Id"); // Lấy bookingId từ phản hồi API
          _bookingId = bookingId1.toString();
          _findNearestDriver(
              bookingId1); // Gửi bookingId vào hàm _findNearestDriver

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isSuccessBooked', true);
          _saveMarkerPositions();
          setState(() {
            isSuccessBooked = true;
          });
          showTemporaryMessage(
              context, 'Emergency ambulance booking successfully!');
        } else {
          showTemporaryMessage(
              context, 'Error in booking emergency ambulance!');
        }
      } catch (e) {
        showTemporaryMessage(context, 'Connection error while booking: $e');
      }
    } else {
      showTemporaryMessage(
          context, 'Estimated costs have not been calculated.');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _findNearestDriver(int? bookingId) async {
    print('bat dau tim tai xe ');
    print('toa do:' + _currentLocation.toString());
    if (_currentLocation != null) {
      final requestBody = json.encode({
        'latitude': _currentLocation!.latitude,
        'longitude': _currentLocation!.longitude,
        'bookingId': bookingId,
      });

      // In chuỗi JSON ra để kiểm tra
      print('JSON đang gửi: $requestBody');
      try {
        final nearestDriverResponse = await http.post(
          Uri.parse(
              'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/drivers/nearest'),
          headers: {'Content-Type': 'application/json'},
          body: requestBody,
        );

        print(nearestDriverResponse.body);

        if (nearestDriverResponse.statusCode == 200) {
          final nearestDriverData = json.decode(nearestDriverResponse.body);

          if (nearestDriverData != null && nearestDriverData.isNotEmpty) {
            // Lọc tài xế có status là "Active"
            print('active');
            final activeDrivers = nearestDriverData
                .where((driver) => driver['status'] == 'Active')
                .toList();

            if (activeDrivers.isNotEmpty) {
              // Lấy tài xế đầu tiên trong danh sách tài xế active
              // Sử dụng int.tryParse để chuyển đổi driverId an toàn
                // Hiển thị thông báo tài xế gần nhất
                showTemporaryMessage(context,
                    'Nearest active driver: ${activeDrivers[0]['driverPhone']}, Name: ${activeDrivers[0]['driverName']}');
                _driverName = activeDrivers[0]['driverName'];
                _driverPhone = activeDrivers[0]['driverPhone'];
                driverPhone = _driverPhone;
                driverName = _driverName;

                print(driverName);
                print(driverPhone);
              final driverIdStr = activeDrivers[0]['driverId'].toString();
                final driverId = int.tryParse(driverIdStr);
                driverId2 = driverId;
                if (driverId != null) {
                  String status = "Deactive";
                  await _updateDriverStatus(
                      driverId2, status); // Chuyển driverId sang chuỗi
                  print('ok');
                // Cập nhật đơn đặt xe với driverId và bookingId
                await _updateBookingWithDriverId(driverId, bookingId1);
                getDriverLocation = true;
                if (updateLocation == false) {
                  _loadMarkerPositions();
                    print(driverId.toString() + " dang cap nhat gui vi tri + thu vi tri");
                }
              } else {
                print("Error converting driver ID to int");
                showTemporaryMessage(context, 'Invalid driver ID');
              }
            } else {
              showTemporaryMessage(context, 'No active drivers found nearby');
              return;
            }
          } else {
            showTemporaryMessage(
                context, 'No nearest driver information found');
            return;
          }
        } else {
          showTemporaryMessage(context,
              'Error finding driver: ${nearestDriverResponse.statusCode}');
          return;
        }
      } catch (e) {
        showTemporaryMessage(context, 'Connection error: $e');
        return;
      }
    } else {
      showTemporaryMessage(context, 'Unable to get current location');
      return;
    }
    setState(() {
      isLoading = false;
    });
  }

// Hàm cập nhật đơn đặt xe với driverId
  Future<void> _updateBookingWithDriverId(int driverId, int? bookingId) async {
    print('cap nhat don dat xe');
    try {
      final response = await http.put(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/bookings/update-driver/$bookingId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'driverId': driverId, // Gửi driverId để cập nhật đơn đặt xe
        }),
      );

      if (response.statusCode == 200) {
        showTemporaryMessage(
            context, 'Booking updated with driverId: $driverId');
      } else {
        showTemporaryMessage(context, 'Error updating booking with driverId');
      }
    } catch (e) {
      showTemporaryMessage(
          context, 'Connection error while updating booking: $e');
    }
  }

  void _fitMarkers() {
    List<LatLng> markerPoints = [];

    if (_currentLocation != null) {
      markerPoints.add(_currentLocation!);
    }
    if (_hospitalLocation != null) {
      markerPoints.add(_hospitalLocation!);
    }
    if (_destinationLocation != null) {
      markerPoints.add(_destinationLocation!);
    }
    if (_driverLocation != null) {
      markerPoints.add(_driverLocation!);
    }

    if (markerPoints.isNotEmpty) {
      // Tính toán LatLngBounds từ danh sách marker points
      LatLngBounds bounds = LatLngBounds.fromPoints(markerPoints);

      // Fit bản đồ với LatLngBounds này
      _mapController.fitBounds(
        bounds,
        options: const FitBoundsOptions(
            padding: EdgeInsets.all(50)), // Thêm padding để không sát với cạnh
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    hospitalNameController.dispose();
    destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Scaffold(
        backgroundColor: whiteColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: whiteColor,
              size: 25,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          backgroundColor: primaryColor,
        ),
        body: isSuccessBooked
            ? Stack(
                children: [
                  SizedBox(
                    height: double.infinity,
                    width: double.infinity,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        center: _currentLocation ??
                            _hospitalLocation ??
                            LatLng(20.99167, 105.845),
                        zoom: _currentZoom,
                        onMapReady: _fitMarkers, // Gọi hàm khi map đã sẵn sàng
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                          subdomains: ['a', 'b', 'c'],
                        ),
                        if (_currentLocation != null ||
                            _hospitalLocation != null ||
                            _destinationLocation != null)
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 80.0,
                                height: 80.0,
                                point: _currentLocation != null
                                    ? _currentLocation!
                                    : (_hospitalLocation ??
                                        LatLng(20.99167, 105.845)),
                                builder: (ctx) => const Icon(Icons.location_pin,
                                    color: primaryColor, size: 40.0),
                              ),
                              if (_destinationLocation != null)
                                Marker(
                                  width: 80.0,
                                  height: 80.0,
                                  point: _destinationLocation!,
                                  builder: (ctx) => const Icon(Icons.flag,
                                      color: Colors.green, size: 40.0),
                                ),
                              if (_driverLocation != null)
                                Marker(
                                  width: 80.0,
                                  height: 80.0,
                                  point: _driverLocation!,
                                  builder: (ctx) => const Icon(
                                      Icons.directions_car,
                                      color: blueColor,
                                      size: 40.0),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      width: double.infinity,
                      color: whiteColor,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  'Driver: $driverName',

                                  style: const TextStyle(
                                      color: blackColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: Text(
                                  'Phone Number: $driverPhone',
                                  style: const TextStyle(
                                      color: blackColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              )
                            ],
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                height: 40,
                                width: 150,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      callPhoneNumber(_driverPhone),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Call Driver',
                                    style: TextStyle(
                                        color: whiteColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              Container(
                                height: 1,
                                color: whiteColor,
                              ),
                              SizedBox(
                                height: 40,
                                width: 150,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          backgroundColor: whiteColor,
                                          title: const Text(
                                            'Confirm Completion',
                                            style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                                color: blackColor),
                                          ),
                                          content: const Text(
                                              'Are you sure you want to mark the emergency as completed?',
                                              style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: blackColor)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(15),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                'Cancel',
                                                style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                _clearBookingStatus();
                                                Navigator.of(context).pop();
                                              },
                                              child: const Text(
                                                'Confirm',
                                                style: TextStyle(
                                                    color: primaryColor,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(0),
                                    ),
                                  ),
                                  child: const Text(
                                    'Complete',
                                    style: TextStyle(
                                        color: whiteColor,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  )
                ],
              )
            : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: <Widget>[
                      const SizedBox(
                        height: 20,
                      ),
                      const Center(
                        child: Text(
                          'Emergency Booking',
                          style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 22),
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          onSaved: (value) => patientName = value!,
                          cursorColor: Colors.black54,
                          style: const TextStyle(
                              color: blackColor,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.person,
                                color: Colors.black54,
                              ),
                            ),
                            hintText: 'Full Name',
                            hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            errorStyle: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Name cannot be empty';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          keyboardType: TextInputType.emailAddress,
                          onSaved: (value) => email = value!,
                          cursorColor: Colors.black54,
                          style: const TextStyle(
                              color: blackColor,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.email,
                                color: Colors.black54,
                              ),
                            ),
                            hintText: 'Email Address',
                            hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            errorStyle: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email address cannot be empty';
                            }
                            if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                .hasMatch(value)) {
                              return 'Invalid email address';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: TextFormField(
                          keyboardType: TextInputType.phone,
                          onSaved: (value) => phoneNumber = value!,
                          cursorColor: Colors.black54,
                          style: const TextStyle(
                              color: blackColor,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.phone_outlined,
                                color: Colors.black54,
                              ),
                            ),
                            hintText: 'Phone Number',
                            hintStyle: TextStyle(
                                color: Colors.black54,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            errorStyle: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Phone number cannot be empty';
                            }
                            if (!RegExp(r'^\d+$').hasMatch(value)) {
                              return 'Phone number must contain only digits';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: DropdownButtonFormField<String>(
                          dropdownColor: whiteColor,
                          decoration: const InputDecoration(
                            prefixIcon: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
                              child: Icon(
                                Icons.car_crash,
                                color: Colors.black54,
                              ),
                            ),
                            hintText: 'Type of ambulance',
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                                  BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius:
                                  BorderRadius.all(Radius.circular(15)),
                            ),
                          ),
                          value: ambulanceType,
                          items: ambulanceTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(
                                type,
                                style: const TextStyle(
                                    color: blackColor,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) =>
                              setState(() => ambulanceType = newValue!),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text(
                          'Use current location for pickup point',
                          style: TextStyle(
                              color: blackColor,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        value: useCurrentLocation,
                        activeColor: whiteColor,
                        activeTrackColor: primaryColor,
                        inactiveThumbColor: whiteColor,
                        inactiveTrackColor: Colors.black54,
                        onChanged: (value) {
                          setState(() {
                            useCurrentLocation = value;
                            if (useCurrentLocation) {
                              // Bật sử dụng vị trí hiện tại
                              hospitalNameController.clear();
                              _startTrackingLocation();
                            } else {
                              // Khi tắt công tắc, cho phép chọn vị trí từ danh sách gợi ý
                              updateLocation = true;
                              _hospitalLocation = null;
                              _currentLocation = null; // Đặt lại vị trí hiện tại
                            }
                          });
                        },
                      ),
                      SwitchListTile(
                        title: const Text(
                            'Select a location on the map for your destination',
                            style: TextStyle(
                                color: blackColor,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        value: useMapForDestination,
                        activeColor: whiteColor,
                        activeTrackColor: primaryColor,
                        inactiveThumbColor: whiteColor,
                        inactiveTrackColor: Colors.black54,
                        onChanged: (value) {
                          setState(() {
                            useMapForDestination = value;
                            if (useMapForDestination) {
                              destinationController.clear();
                            }
                          });
                        },
                      ),
                      if (!useCurrentLocation)
                        const SizedBox(
                          height: 20,
                        ),
                      if (!useCurrentLocation)
                        GestureDetector(
                          onTap: () {
                            _showHospitalSuggestions();
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              style: const TextStyle(
                                  color: blackColor,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold),
                              controller: hospitalNameController,
                              decoration: const InputDecoration(
                                prefixIcon: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.black54,
                                  ),
                                ),
                                hintText: 'Select Pickup Point',
                                hintStyle: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black54, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black54, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 1.0,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 1.0,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                errorStyle: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                              validator: (value) {
                                if (!useCurrentLocation &&
                                    (value == null || value.isEmpty)) {
                                  return 'Please select a hospital or use current location';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      if (!useMapForDestination)
                        const SizedBox(
                          height: 20,
                        ),
                      if (!useMapForDestination)
                        GestureDetector(
                          onTap: () {
                            _showHospitalSuggestions(isDestination: true);
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              style: const TextStyle(
                                  color: blackColor,
                                  fontSize: 16.0,
                                  fontWeight: FontWeight.bold),
                              controller: destinationController,
                              decoration: const InputDecoration(
                                hintText: 'Select Destination',
                                prefixIcon: Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Icon(
                                    Icons.location_on,
                                    color: Colors.black54,
                                  ),
                                ),
                                hintStyle: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black54, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                      color: Colors.black54, width: 1.0),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 1.0,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderSide: BorderSide(
                                    color: Colors.red,
                                    width: 1.0,
                                  ),
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(15)),
                                ),
                                errorStyle: TextStyle(
                                    color: Colors.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select destination';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      const SizedBox(
                        height: 20,
                      ),
                      SizedBox(
                        height: 200,
                        child: FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            center: _currentLocation ??
                                _hospitalLocation ??
                                LatLng(20.99167, 105.845),
                            zoom: _currentZoom,
                            onTap: (tapPosition, LatLng tappedPoint) {
                              if (useMapForDestination) {
                                setState(() {
                                  _destinationLocation = tappedPoint;
                                  _calculateCost(); // Tính toán chi phí sau khi chọn điểm đến
                                });
                              }
                            },
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                              subdomains: ['a', 'b', 'c'],
                            ),
                            if (_currentLocation != null ||
                                _hospitalLocation != null ||
                                _destinationLocation != null)
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: useCurrentLocation &&
                                            _currentLocation != null
                                        ? _currentLocation!
                                        : (_hospitalLocation ??
                                            LatLng(20.99167, 105.845)),
                                    builder: (ctx) => const Icon(
                                        Icons.location_pin,
                                        color: primaryColor,
                                        size: 40.0),
                                  ),
                                  if (_destinationLocation != null)
                                    Marker(
                                      width: 80.0,
                                      height: 80.0,
                                      point: _destinationLocation!,
                                      builder: (ctx) => const Icon(Icons.flag,
                                          color: Colors.green, size: 40.0),
                                    ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: whiteColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            side: const BorderSide(
                              color: primaryColor,
                              width: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: _calculateCost,
                          child: const Text(
                            'Calculate Estimated Cost',
                            style: TextStyle(
                                color: primaryColor,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _submitForm();
                            }
                          },
                          child: const Text(
                            'Book Now',
                            style: TextStyle(
                                color: whiteColor,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
      if (isLoading)
        Positioned.fill(
          child: Container(
            color: blackColor.withOpacity(0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(whiteColor),
              ),
            ),
          ),
        ),
    ]);
  }
}
