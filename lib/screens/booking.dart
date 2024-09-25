import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class Booking extends StatefulWidget {
  const Booking({super.key});

  @override
  _BookingState createState() => _BookingState();
}

class _BookingState extends State<Booking> {
  // Khai báo các biến cho form
  final _formKey = GlobalKey<FormState>();
  String hospitalName = '';
  String patientName = '';
  String email = '';
  String ambulanceType = 'Standard Ambulance';
  String phoneNumber = '';
  String address = '';
  String zipCode = '';
  String bookingType = 'Khẩn cấp';
  bool isEmergencyBooking = true;

  // Vị trí hiện tại của điện thoại
  LatLng? _currentLocation;
  double _currentZoom = 15.0;
  final MapController _mapController = MapController();
  final List<String> ambulanceTypes = [
    'Standard Ambulance',
    'Advanced Life Support Ambulance',
    'Neonatal Ambulance',
    'Air Ambulance'
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
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

  // Lấy vị trí hiện tại của điện thoại
  Future<void> _getCurrentLocation() async {
    try {
      // Kiểm tra quyền truy cập vị trí
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Lấy vị trí hiện tại
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
        });
      } else {
        showTemporaryMessage(context, 'Location access denied. Please please grant permission to continue.');
        print('Location access denied');
      }
    } catch (e) {
      print('Error get location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: const Center(
          child: Text(
            'Ambulance Booking',
            style: TextStyle(
                color: whiteColor, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isEmergencyBooking
                              ? primaryColor
                              : Colors.black54,
                          borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(15),
                              bottomLeft: Radius.circular(15)),
                        ),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              isEmergencyBooking = true;
                              bookingType = 'Urgent';
                            });
                          },
                          child: const Text('Urgent',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: whiteColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: !isEmergencyBooking
                              ? primaryColor
                              : Colors.black54,
                          borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(15),
                              bottomRight: Radius.circular(15)),
                        ),
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              isEmergencyBooking = false;
                              bookingType = 'Reserve';
                            });
                          },
                          child: const Text('Reserve',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: whiteColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (!isEmergencyBooking) ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Tên bệnh viện'),
                  onSaved: (value) {
                    hospitalName = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên bệnh viện';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
              ],
              SizedBox(
                width: double.infinity,
                child: TextFormField(
                  onSaved: (value) {
                    patientName = value!;
                  },
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
                  onSaved: (value) {
                    email = value!;
                  },
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
                  onSaved: (value) {
                    phoneNumber = value!;
                  },
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
                  onChanged: (newValue) {
                    setState(() {
                      ambulanceType = newValue!;
                    });
                  },
                ),
              ),
              if (!isEmergencyBooking) ...[
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                  onSaved: (value) {
                    address = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Mã ZIP'),
                  onSaved: (value) {
                    zipCode = value!;
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập mã ZIP';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Stack(
                  children: [
                    _currentLocation != null
                        ? FlutterMap(
                            mapController: _mapController,
                            options: MapOptions(
                              center: _currentLocation,
                              zoom: _currentZoom,
                              minZoom: 5.0,
                              // Zoom tối thiểu
                              maxZoom: 18.0,
                              // Zoom tối đa
                              interactiveFlags: InteractiveFlag.all,
                            ),
                            children: [
                              TileLayer(
                                urlTemplate:
                                    'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                                subdomains: const ['a', 'b', 'c'],
                              ),
                              MarkerLayer(
                                markers: [
                                  Marker(
                                    width: 80.0,
                                    height: 80.0,
                                    point: _currentLocation!,
                                    builder: (ctx) => Container(
                                      child: const Icon(
                                        Icons.location_pin,
                                        color: primaryColor,
                                        size: 40.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        : const Center(
                            child: CircularProgressIndicator(
                            color: primaryColor,
                          )),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Column(
                        children: [
                          FloatingActionButton(
                            backgroundColor: primaryColor,
                            mini: true,
                            onPressed: () {
                              setState(() {
                                if (_currentZoom < 18.0) {
                                  _currentZoom += 1;
                                  _mapController.move(
                                      _mapController.center, _currentZoom);
                                }
                              });
                            },
                            child: const Icon(
                              Icons.zoom_in,
                              color: whiteColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          FloatingActionButton(
                            backgroundColor: primaryColor,
                            mini: true,
                            onPressed: () {
                              setState(() {
                                if (_currentZoom > 5.0) {
                                  _currentZoom -= 1;
                                  _mapController.move(
                                      _mapController.center, _currentZoom);
                                }
                              });
                            },
                            child: const Icon(
                              Icons.zoom_out,
                              color: whiteColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: whiteColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          side: const BorderSide(
                            color: primaryColor,
                            width: 1,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: () {
                          launch('tel:$phoneNumber');
                        },
                        child: const Text(
                          'Call Driver',
                          style: TextStyle(
                              color: primaryColor,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.45,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: _submitForm,
                        child: const Text(
                          'Book Now',
                          style: TextStyle(
                              color: whiteColor,
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30)
            ],
          ),
        ),
      ),
    );
  }

  String generatePassword(int length) {
    if (length < 8) {
      throw Exception("Mật khẩu phải có ít nhất 8 ký tự.");
    }

    const lowercase = 'abcdefghijklmnopqrstuvwxyz';
    const uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    const digits = '0123456789';
    const specialCharacters = '!@#\$%^&*()_+';

    final Random random = Random();
    String password = '';

    password += lowercase[random.nextInt(lowercase.length)];
    password += uppercase[random.nextInt(uppercase.length)];
    password += digits[random.nextInt(digits.length)];
    password += specialCharacters[random.nextInt(specialCharacters.length)];

    String allCharacters = lowercase + uppercase + digits + specialCharacters;
    for (int i = 0; i < length - 4; i++) {
      password += allCharacters[random.nextInt(allCharacters.length)];
    }

    List<String> passwordChars = password.split('');
    passwordChars.shuffle(random);

    return passwordChars.join('');
  }

  // Xử lý sự kiện khi form được submit
  void _submitForm() async {
    String randomPassword = generatePassword(8);
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Bước 1: Kiểm tra xem email đã tồn tại chưa
      final checkEmailResponse = await http.post(
        Uri.parse(
            'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/patients/check'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      if (checkEmailResponse.statusCode == 200) {
        final emailExists =
            json.decode(checkEmailResponse.body); // Kết quả là true hoặc false
        print('Check email response body: $emailExists'); // Debugging

        if (emailExists) {
          // Email đã tồn tại, cập nhật thông tin người dùng
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
            print('Cập nhật thông tin người dùng thành công');
            _bookEmergencyAmbulance();
          } else {
            print(
                'Lỗi khi cập nhật thông tin người dùng: ${updateUserResponse.body}');
          }
        } else {
          // Email chưa tồn tại, đăng ký người dùng mới
          final registerUserResponse = await http.post(
            Uri.parse(
                'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/patients/register'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'email': email,
              'phoneNumber': phoneNumber,
              'patientName': patientName,
              'password': randomPassword,
            }),
          );

          if (registerUserResponse.statusCode == 201) {
            print('Đăng ký người dùng mới thành công');
            _bookEmergencyAmbulance();
          } else {
            print(
                'Lỗi khi đăng ký người dùng mới: ${registerUserResponse.body}');
          }
        }
      } else {
        print('Lỗi khi kiểm tra email: ${checkEmailResponse.body}');
      }
    }
  }

  //dat xe
  void _bookEmergencyAmbulance() async {
    // Lấy địa chỉ từ tọa độ GPS
    String pickupAddress =
        'Unknown location'; // Giá trị mặc định nếu không thể xác định địa chỉ

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        pickupAddress = '${place.street}, ${place.locality}, ${place.country}';
      }
    } catch (e) {
      print('Lỗi khi chuyển tọa độ thành địa chỉ: $e');
    }

    // Đóng gói dữ liệu cần gửi cho đặt chỗ khẩn cấp
    final bookingData = {
      'patient': {
        'email': email,
      },
      'bookingType': 'Urgent',
      'pickupAddress': pickupAddress, // Địa chỉ dạng văn bản
      'latitude': _currentLocation?.latitude, // Tọa độ GPS
      'longitude': _currentLocation?.longitude, // Tọa độ GPS
      'pickupTime': DateTime.now().toIso8601String(),
    };

    // Gửi yêu cầu POST đến backend
    final response = await http.post(
      Uri.parse(
          'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/bookings/emergency'),
      // Đảm bảo endpoint là /api/bookings/emergency
      headers: {'Content-Type': 'application/json'},
      body: json.encode(bookingData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Đặt xe cứu thương khẩn cấp thành công');
      showTemporaryMessage(context, 'Emergency ambulance booking successfully!');
    } else {
      print('Lỗi khi đặt xe cứu thương khẩn cấp');
      showTemporaryMessage(context, 'Error in booking emergency ambulance!');
    }
  }
}
