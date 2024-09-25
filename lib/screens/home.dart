import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

import 'doctor_details.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class Home extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;
  final VoidCallback onNavigateToDiagnosis;

  const Home(
      {super.key,
      required this.isLoggedIn,
      required this.onLogout,
      this.patientId,
      required this.onNavigateToDiagnosis});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List<dynamic> doctors = [];
  bool isLoading = false;
  String name = '';
  final random = Random();
  bool isSuccessBooked = false;

  @override
  void initState() {
    super.initState();
    _loadBookingStatus();
    fetchDoctors();
  }

  void _loadBookingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isSuccessBooked = prefs.getBool('isSuccessBooked') ?? false;
    });
  }

  @override
  void didUpdateWidget(Home oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn != oldWidget.isLoggedIn) {
      fetchPatientData();
    }
    if (isSuccessBooked !=
        (SharedPreferences.getInstance()
            .then((prefs) => prefs.getBool('isSuccessBooked') ?? false))) {
      _loadBookingStatus();
    }
  }

  Future<void> fetchPatientData() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(
        'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/patients/search?patient_id=${widget.patientId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var patientData = json.decode(response.body);
        if (patientData.isNotEmpty) {
          setState(() {
            name = patientData[0]['patient_name'] ?? '';
          });
        }
      } else {
        print(
            'Error fetching patient data! Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchDoctors() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(
        'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/doctors/list');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          doctors = json.decode(response.body);
        });
        doctors.shuffle(random);
      } else {
        print('Lỗi khi lấy danh sách bác sĩ!');
      }
    } catch (error) {
      print('Lỗi: $error');
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: whiteColor,
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/3824251.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          widget.isLoggedIn
                              ? SizedBox(
                                  width: double.infinity,
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Hello, $name',
                                        style: const TextStyle(
                                          color: blackColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                backgroundColor: whiteColor,
                                                title: const Text(
                                                  'Confirm Logout',
                                                  style: TextStyle(
                                                      fontSize: 22,
                                                      fontWeight: FontWeight.bold,
                                                      color: blackColor),
                                                ),
                                                content: const Text(
                                                    'Are you sure you want to logout?',
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
                                                      Navigator.of(context).pop();
                                                      widget.onLogout();
                                                    },
                                                    child: const Text(
                                                      'Logout',
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
                                        icon: const Icon(
                                          Icons.logout,
                                          color: blackColor,
                                          size: 20,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : const SizedBox(
                                  height: 1,
                                ),
                          if (isSuccessBooked)
                            const Text(
                              "Emergency ambulance is on the way!",
                              style: TextStyle(
                                  color: const Color.fromARGB(255, 255, 0, 0),
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 80,
                                  width:
                                      MediaQuery.of(context).size.width * 0.45,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromARGB(255, 255, 0, 0),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, '/emergency_booking');
                                    },
                                    child: const Text(
                                      textAlign: TextAlign.center,
                                      'Emergency Booking',
                                      style: TextStyle(
                                        color: whiteColor,
                                        fontSize: 16.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 80,
                                  width:
                                      MediaQuery.of(context).size.width * 0.45,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: whiteColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(15),
                                      ),
                                      side: const BorderSide(
                                        color: Color.fromARGB(255, 255, 0, 0),
                                        width: 1,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 15),
                                    ),
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, '/nonEmergency_booking');
                                    },
                                    child: const Text(
                                      textAlign: TextAlign.center,
                                      'Non-urgent Booking',
                                      style: TextStyle(
                                          color: Color.fromARGB(255, 255, 0, 0),
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(vertical: 16.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black54.withOpacity(0.2),
                                width: 1.0,
                              ),
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/booked_list');
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://img.icons8.com/bubbles/100/ambulance.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                            const Text(
                                              'Booked Ambulance',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/appointment_list');
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://img.icons8.com/bubbles/100/calendar--v1.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                            const Text(
                                              'Booked Appointment',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/medical_records');
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://img.icons8.com/bubbles/100/doctors-bag.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                            const Text(
                                              'Medical Records',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: widget.onNavigateToDiagnosis,
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://img.icons8.com/bubbles/100/search.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                            const Text(
                                              'Diagnostic Imaging',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: 20,
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(context, '/user');
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://img.icons8.com/bubbles/100/user.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                            const Text(
                                              'Account Information',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/library');
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://img.icons8.com/bubbles/100/book-shelf.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                            const Text(
                                              'Ambulance Library',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/feedback');
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://img.icons8.com/bubbles/100/comments.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                            const Text(
                                              'Services Feedback',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 1,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.pushNamed(
                                              context, '/change_password');
                                        },
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Image.network(
                                              'https://img.icons8.com/bubbles/100/lock.png',
                                              width: 70,
                                              height: 70,
                                            ),
                                            const Text(
                                              'Change Password',
                                              textAlign: TextAlign.center,
                                              overflow: TextOverflow.visible,
                                              maxLines: 2,
                                              style: TextStyle(
                                                  color: Colors.black87,
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: primaryColor.withOpacity(0.05),
                      width: double.infinity,
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: Colors.yellow,
                                  ),
                                  SizedBox(
                                    width: 5,
                                  ),
                                  Text(
                                    'Featured Doctors',
                                    style: TextStyle(
                                        color: blackColor,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                  )
                                ],
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                width: double.infinity,
                                height: 220,
                                child: PageView.builder(
                                  itemCount: (doctors.length / 2).ceil(),
                                  itemBuilder: (context, index) {
                                    int firstDoctorIndex = index * 2;
                                    int secondDoctorIndex =
                                        firstDoctorIndex + 1;

                                    return Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        Expanded(
                                            child: _buildDoctorCard(
                                                firstDoctorIndex)),
                                        if (secondDoctorIndex < doctors.length)
                                          Expanded(
                                              child: _buildDoctorCard(
                                                  secondDoctorIndex)),
                                      ],
                                    );
                                  },
                                ),
                              ),
                            ],
                          )),
                    ),
                    Container(
                      height: 30,
                      color: primaryColor.withOpacity(0.05),
                    )
                  ],
                ),
              ));
  }

  final Map<String, String> departments = {
    '12': 'Pediatrics',
    '13': 'Dentistry',
    '14': 'Neurology',
    '15': 'Ophthalmology',
    '16': 'Cardiology',
    '17': 'Digestive',
  };

  String getDepartmentName(int departmentId) {
    return departments[departmentId.toString()] ?? 'Unknown Department';
  }

  Widget _buildDoctorCard(int index) {
    if (index >= doctors.length) return Container();

    final doctor = doctors[index];
    final departmentName = getDepartmentName(doctor['department_id']);

    return Card(
      color: whiteColor,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                CircleAvatar(
                  backgroundImage: NetworkImage(doctor['doctor_image']),
                  radius: 35,
                ),
                const SizedBox(
                  height: 5,
                ),
                Text(doctor['doctor_name'].toUpperCase(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: blackColor)),
                const SizedBox(
                  height: 5,
                ),
                Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    color: blueColor.withOpacity(0.1),
                  ),
                  child: Text(
                    departmentName,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(
              width: double.infinity,
              height: 30,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorDetailsScreen(doctor: doctor),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: whiteColor,
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                ),
                child: const Text(
                  'See details',
                  style: TextStyle(
                      color: whiteColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
