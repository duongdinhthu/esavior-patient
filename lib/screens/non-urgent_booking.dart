import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class NonEmergencyBooking extends StatefulWidget {
  @override
  _NonEmergencyBookingState createState() => _NonEmergencyBookingState();
}

class _NonEmergencyBookingState extends State<NonEmergencyBooking> {
  final _formKey = GlobalKey<FormState>();
  String patientName = '';
  String email = '';
  String phoneNumber = '';
  String ambulanceType = 'Standard Ambulance';
  LatLng? _currentLocation;
  LatLng? _hospitalLocation;
  LatLng? _destinationLocation;
  double _currentZoom = 15.0;
  DateTime? _selectedPickupTime;
  bool isLoading = false;

  bool useCurrentLocationForPickup = false; // Công tắc cho điểm đi
  bool useMapForDestination = false; // Công tắc cho điểm đến
  final MapController _mapController = MapController();
  StreamSubscription<Position>? _positionStream;
  double? _estimatedCost;

  // Khai báo TextEditingController cho các trường
  TextEditingController hospitalNameController = TextEditingController();
  TextEditingController destinationController = TextEditingController();
  TextEditingController zipCodeController =
      TextEditingController(); // Khai báo zipCodeController

  // Danh sách bệnh viện và danh sách gợi ý
  List<Map<String, dynamic>> allHospitals = [];

  final List<String> ambulanceTypes = [
    'Standard Ambulance',
    'Advanced Life Support Ambulance',
  ];

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

// Hàm chọn ngày và giờ
  Future<void> _selectPickupTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: primaryColor,
            hintColor: primaryColor,
            colorScheme: const ColorScheme.light(primary: primaryColor),
            buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
        builder: (BuildContext context, Widget? child) {
          return Theme(
            data: ThemeData.light().copyWith(
              primaryColor: primaryColor,
              hintColor: primaryColor,
              colorScheme: const ColorScheme.light(primary: primaryColor),
              buttonTheme: const ButtonThemeData(textTheme: ButtonTextTheme.primary),
            ),
            child: child!,
          );
        },
      );
      if (pickedTime != null) {
        setState(() {
          _selectedPickupTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

// Định dạng DateTime để gửi lên API
  String _formatDateTime(DateTime dateTime) {
    return dateTime.toIso8601String(); // Định dạng thành chuỗi ISO8601
  }

  @override
  void initState() {
    super.initState();
    _loadHospitals();
    _startTrackingLocation();
  }

  Future<void> _loadHospitals() async {
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
                    'zipCode': e['zipCode'] ?? '' // Thêm mã ZIP nếu có
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

  void _startTrackingLocation() {
    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high, distanceFilter: 10),
    ).listen((Position position) {
      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentLocation != null) {
          _mapController.move(_currentLocation!, _currentZoom);
        }
      });
    });
  }

  Future<void> _getCurrentLocation() async {
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
    });
    _mapController.move(_currentLocation!, _currentZoom);
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
                    // Cập nhật điểm đến
                    destinationController.text =
                        allHospitals[index]['hospitalName'];
                    _destinationLocation = LatLng(
                      allHospitals[index]['latitude'],
                      allHospitals[index]['longitude'],
                    );
                    _mapController.move(_destinationLocation!, _currentZoom);
                  } else {
                    // Khi chọn bệnh viện làm điểm đi
                    hospitalNameController.text =
                        allHospitals[index]['hospitalName'];

                    // Cập nhật vị trí bệnh viện nếu công tắc tắt
                    if (!useCurrentLocationForPickup) {
                      _hospitalLocation = LatLng(
                        allHospitals[index]['latitude'],
                        allHospitals[index]['longitude'],
                      );
                      _currentLocation =
                          _hospitalLocation; // Cập nhật vị trí hiện tại thành bệnh viện
                      zipCodeController.text =
                          allHospitals[index]['zipCode']; // Cập nhật mã ZIP
                      _mapController.move(_hospitalLocation!, _currentZoom);
                    }
                  }
                  _calculateCost(); // Tính toán lại chi phí dựa trên vị trí mới
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
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
    });
    if (_currentLocation != null && _destinationLocation != null) {
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
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
    });
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final checkEmailResponse = await http.post(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/patients/check'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (checkEmailResponse.statusCode == 200 ||
          checkEmailResponse.statusCode == 201) {
        print("ok1");
        final emailExists = json.decode(checkEmailResponse.body);

        if (emailExists) {
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

          if (updateUserResponse.statusCode == 200 ||
              updateUserResponse.statusCode == 201) {
            print("ok2");
            await _bookNonEmergencyAmbulance();
          } else {
            print('Error fetching patient data');
          }
        } else {
          print("register");
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

          if (registerUserResponse.statusCode == 201 ||
              registerUserResponse.statusCode == 200) {
            await _bookNonEmergencyAmbulance();
          } else {
            print('Error while registering new user');
          }
        }
      } else {
        print('Error checking email');
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _bookNonEmergencyAmbulance() async {
    LatLng? bookingLocation;
    String? pickupAddress;

    // Kiểm tra vị trí hiện tại
    if (_currentLocation != null) {
      bookingLocation = _currentLocation;
      pickupAddress = hospitalNameController.text.isNotEmpty
          ? hospitalNameController.text
          : 'Current Location';
    }

    // Kiểm tra xem đã có chi phí ước tính chưa
    if (bookingLocation != null && _estimatedCost != null) {
      // Kiểm tra xem người dùng đã chọn thời gian đón chưa
      if (_selectedPickupTime == null) {
        showTemporaryMessage(context, 'Please select date & time.');
        return; // Ngăn không cho gửi yêu cầu nếu chưa chọn thời gian
      }

      // Tạo dữ liệu đặt chỗ
      final bookingData = {
        'patient': {'email': email},
        'bookingType': 'Non-Emergency',
        'pickupAddress': pickupAddress,
        'latitude': bookingLocation.latitude,
        'longitude': bookingLocation.longitude,
        'pickupTime': _selectedPickupTime!.toIso8601String(),
        // Chắc chắn sử dụng thời gian đã chọn
        'destinationLatitude': _destinationLocation?.latitude,
        'destinationLongitude': _destinationLocation?.longitude,
        'cost': _estimatedCost,
      };

      print(
          json.encode(bookingData)); // In dữ liệu booking trước khi gửi request

      // Gửi request đặt xe không khẩn cấp
      final response = await http.post(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/bookings/non-emergency'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(bookingData),
      );
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      // Xử lý phản hồi từ server
      if (response.statusCode == 200 || response.statusCode == 201) {
        showTemporaryMessage(context, 'Ambulance booked successfully!');
        Navigator.pop(context);
      } else {
        showTemporaryMessage(context, 'Error in booking ambulance!');
      }
    } else {
      showTemporaryMessage(
          context, 'Estimated costs have not been calculated.');
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    hospitalNameController.dispose();
    destinationController.dispose();
    zipCodeController.dispose(); // Dispose mã ZIP
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
          body: Padding(
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
                      'Non-urgent Booking',
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
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
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
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
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
                        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
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
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
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
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
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
                    value: useCurrentLocationForPickup,
                    activeColor: whiteColor,
                    activeTrackColor: primaryColor,
                    inactiveThumbColor: whiteColor,
                    inactiveTrackColor: Colors.black54,
                    onChanged: (value) {
                      setState(() {
                        useCurrentLocationForPickup = value;
                        if (useCurrentLocationForPickup) {
                          hospitalNameController.clear();
                          zipCodeController
                              .clear(); // Xóa mã ZIP khi chọn vị trí hiện tại
                          _getCurrentLocation();
                        } else {
                          _hospitalLocation = null;
                          _currentLocation = null;
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
                  if (!useCurrentLocationForPickup)
                    const SizedBox(
                      height: 20,
                    ),
                  if (!useCurrentLocationForPickup)
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
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
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
                              borderSide:
                              BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                            ),
                            errorStyle: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold),
                          ),
                          validator: (value) {
                            if (!useCurrentLocationForPickup &&
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
                              padding: EdgeInsets.symmetric(horizontal: 8.0),
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
                              borderSide:
                              BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: Colors.black54, width: 1.0),
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(15)),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                color: Colors.red,
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.all(Radius.circular(15)),
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
                    child: TextFormField(
                      style: const TextStyle(
                          color: blackColor,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold),
                      controller: zipCodeController,
                      decoration: const InputDecoration(
                        hintText: 'Zip Code',
                        prefixIcon: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.numbers,
                            color: Colors.black54,
                          ),
                        ),
                        hintStyle: TextStyle(
                            color: Colors.black54,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorStyle: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
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
                              _calculateCost();
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
                                point: _currentLocation ??
                                    _hospitalLocation ??
                                    LatLng(20.99167, 105.845),
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
                            ],
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_estimatedCost != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        textAlign: TextAlign.center,
                        'Estimated Cost: ${_estimatedCost?.toStringAsFixed(2)} USD',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: blackColor,
                            fontSize: 16),),
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
                        _selectPickupTime(context);
                      },
                      child: Text(
                        _selectedPickupTime != null
                            ? _selectedPickupTime!.toLocal().toString()
                            : 'Select Date & Time',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: whiteColor,
                            fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  if (_selectedPickupTime != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _submitForm,
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: whiteColor,
                            fontSize: 16),
                      ),
                    ),
                  const SizedBox(
                    height: 20,
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
      ],
    );
  }
}
