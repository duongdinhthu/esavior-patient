import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class Profile extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;
  final VoidCallback onNavigateToDiagnosis;

  const Profile(
      {super.key,
      required this.isLoggedIn,
      required this.onLogout,
      this.patientId,
      required this.onNavigateToDiagnosis});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String name = '';
  String imagePath = '';
  bool imageValid = false;
  bool isLoading = false;

  @override
  void didUpdateWidget(Profile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoggedIn != oldWidget.isLoggedIn) {
      fetchPatientData();
    }
  }

  void updateImagePath(String newPath) {
    setState(() {
      imagePath = newPath;
      fetchPatientData();
    });
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
            if (patientData[0]['patient_img'] != null &&
                patientData[0]['patient_img'] != '') {
              imagePath =
                  'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/${patientData[0]['patient_img']}';
              imageValid = true;
            } else {
              imageValid = false;
            }
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
              child: !widget.isLoggedIn
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: double.infinity,
                          height: 300,
                          decoration: const BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage('assets/images/3824251.jpg'),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 60,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Expanded(
                                child: Text(
                                  'Sign in now to use all services and have the best experience',
                                  textAlign: TextAlign.left,
                                  style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: blackColor),
                                ),
                              ),
                              const SizedBox(width: 30),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/login');
                                },
                                style: ElevatedButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  padding: const EdgeInsets.all(20),
                                  backgroundColor: primaryColor,
                                  elevation: 5,
                                ),
                                child: const Icon(
                                  Icons.arrow_forward,
                                  color: whiteColor,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                          height: 150,
                        ),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  color: blackColor,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Hotline:',
                                  style: TextStyle(
                                      color: blackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  '1900 1234',
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                            Center(
                              child: Text(
                                'Version: 1.0.0',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            SizedBox(height: 50),
                          ],
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 50),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              imageValid
                                  ? CircleAvatar(
                                      backgroundImage: NetworkImage(imagePath),
                                      radius: 40,
                                    )
                                  : const Icon(
                                      Icons.account_circle,
                                      size: 80,
                                      color: Colors.grey,
                                    ),
                              imageValid
                                  ? const SizedBox(height: 5)
                                  : const SizedBox(height: 0),
                              Text(
                                name.toUpperCase(),
                                style: const TextStyle(
                                  color: blackColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 35,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    padding: const EdgeInsets.only(
                                        left: 15, right: 15),
                                  ),
                                  onPressed: () async {
                                    final newPath = await Navigator.pushNamed(
                                        context, '/user');
                                    if (newPath != null) {
                                      updateImagePath(newPath as String);
                                    }
                                  },
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.network(
                                        'https://img.icons8.com/windows/32/FFFFFF/edit-user.png',
                                        width: 20,
                                        height: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Update',
                                        style: TextStyle(
                                            color: whiteColor,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          height: 10,
                          color: primaryColor.withOpacity(0.05),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Services',
                                  style: TextStyle(
                                      color: blackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    flex: 1,
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.pushNamed(context, '/booked_list');
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
                                                fontSize: 13,
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
                                                fontSize: 13,
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
                                                fontSize: 13,
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
                                                fontSize: 13,
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
                        Container(
                          width: double.infinity,
                          height: 10,
                          color: primaryColor.withOpacity(0.05),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: double.infinity,
                                alignment: Alignment.centerLeft,
                                child: const Text(
                                  'Utilities',
                                  style: TextStyle(
                                      color: blackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(height: 20),
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
                                                fontSize: 13,
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
                                                fontSize: 13,
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
                                            'Service Feedback',
                                            textAlign: TextAlign.center,
                                            overflow: TextOverflow.visible,
                                            maxLines: 2,
                                            style: TextStyle(
                                                color: Colors.black87,
                                                fontSize: 13,
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
                                                fontSize: 13,
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
                        Container(
                          width: double.infinity,
                          height: 10,
                          color: primaryColor.withOpacity(0.05),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 10, bottom: 10, left: 12, right: 12),
                          child: Column(
                            children: [
                              GestureDetector(
                                  onTap: () {
                                    Navigator.pushNamed(context, '/about');
                                  },
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: Colors.grey,
                                          width: 0.5,
                                        ),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: const Icon(
                                                Icons.verified_user,
                                                color: Colors.black54,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            const Text(
                                              "Terms & Conditions",
                                              style: TextStyle(
                                                  color: blackColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            )
                                          ],
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.grey,
                                          size: 25,
                                        ),
                                      ],
                                    ),
                                  )),
                              GestureDetector(
                                  onTap: () {
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
                                  child: Container(
                                    decoration: const BoxDecoration(),
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            Container(
                                              decoration: BoxDecoration(
                                                color: primaryColor
                                                    .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              padding:
                                                  const EdgeInsets.all(8.0),
                                              child: const Icon(
                                                Icons.logout,
                                                color: Colors.black54,
                                                size: 20,
                                              ),
                                            ),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            const Text(
                                              "Log out",
                                              style: TextStyle(
                                                  color: blackColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16),
                                            )
                                          ],
                                        ),
                                        const Icon(
                                          Icons.chevron_right_rounded,
                                          color: Colors.grey,
                                          size: 25,
                                        ),
                                      ],
                                    ),
                                  )),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          height: 10,
                          color: primaryColor.withOpacity(0.05),
                        ),
                        const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.phone_outlined,
                                  color: blackColor,
                                  size: 20,
                                ),
                                SizedBox(
                                  width: 10,
                                ),
                                Text(
                                  'Hotline:',
                                  style: TextStyle(
                                      color: blackColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                ),
                                SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  '1900 1234',
                                  style: TextStyle(
                                      color: primaryColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                )
                              ],
                            ),
                            Center(
                              child: Text(
                                'Version: 1.0.0',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                            SizedBox(height: 20),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
            ),
    );
  }
}
