import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class User extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  const User({
    super.key,
    required this.isLoggedIn,
    required this.onLogout,
    this.patientId,
  });

  @override
  _UserState createState() => _UserState();
}

class _UserState extends State<User> {
  String name = '';
  String email = '';
  String phone = '';
  String address = '';
  String gender = '';
  String imagePath = '';
  bool imageValid = false;
  bool isLoading = false;
  bool isLoadingImage = false;
  final _formKey = GlobalKey<FormState>();

  TextEditingController patientNameController = TextEditingController();
  TextEditingController patientEmailController = TextEditingController();
  TextEditingController patientPhoneController = TextEditingController();
  TextEditingController patientAddressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchPatientData();
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
            email = patientData[0]['patient_email'] ?? '';
            phone = patientData[0]['patient_phone']?.toString() ?? '';
            address = patientData[0]['patient_address'] ?? '';
            gender = (patientData[0]['patient_gender'] == 'Male' ||
                    patientData[0]['patient_gender'] == 'Female' ||
                    patientData[0]['patient_gender'] == 'Other')
                ? patientData[0]['patient_gender']
                : 'Other';
            patientNameController.text = name;
            patientEmailController.text = email;
            patientPhoneController.text = phone;
            patientAddressController.text = address;
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

  Future<void> pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedImage =
        await picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/patients/upload-image'),
      );
      request.files.add(
          await http.MultipartFile.fromPath('patient_image', pickedImage.path));
      request.fields['patient_id'] = widget.patientId.toString();
      try {
        setState(() {
          imagePath = pickedImage.path;
        });
        final response = await request.send();
        if (response.statusCode == 200) {
          final resData = await response.stream.bytesToString();
          final result = json.decode(resData);
          setState(() {
            imagePath =
                'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/${result['filePath']}';
            imageValid = true;
          });
          showTemporaryMessage(context, 'Image updated successfully!');
        } else {
          showTemporaryMessage(context, 'Error uploading image!');
          print('Error uploading image! Status Code: ${response.statusCode}');
        }
      } catch (error) {
        print('Error uploading image: $error');
        showTemporaryMessage(context, 'Error uploading image!');
      }
    }
    setState(() {
      isLoadingImage = false;
    });
  }

  Future<void> updatePatient(Map<String, dynamic> patientData) async {
    final response = await http.put(
      Uri.parse(
          'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/patients/update'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "patient_id": widget.patientId,
        "patient_name": patientData['patient_name'],
        "patient_email": patientData['patient_email'],
        "patient_phone": patientData['patient_phone'],
        "patient_address": patientData['patient_address'],
        "patient_gender": patientData['patient_gender'],
      }),
    );

    if (response.statusCode == 200) {
      setState(() {
        fetchPatientData();
      });
      showTemporaryMessage(context, 'Information updated successfully!');
    } else {
      showTemporaryMessage(context, 'Update failed!');
      print("Update failed with status code: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoggedIn) {
      Future.delayed(Duration.zero, () {
        Navigator.pushReplacementNamed(context, '/login');
      });
    }
    return Scaffold(
        backgroundColor: whiteColor,
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Stack(
                    children: [
                      Container(
                        height: 220,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageValid
                                ? NetworkImage(imagePath)
                                : const NetworkImage(
                                    'https://images.pexels.com/photos/40568/medical-appointment-doctor-healthcare-40568.jpeg',
                                  ),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                          child: Container(
                            color: blackColor.withOpacity(0),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 200),
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: whiteColor,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 30,
                              ),
                              Center(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                      color: blackColor,
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
                                  controller: patientNameController,
                                  onChanged: (value) =>
                                      setState(() => name = value),
                                  cursorColor: Colors.black54,
                                  style: const TextStyle(
                                      color: blackColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    prefixIcon: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
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
                                      return 'Name cannot be empty';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: <Map<String, dynamic>>[
                                  {
                                    'value': 'Male',
                                    'icon': Icons.male,
                                    'label': 'Male'
                                  },
                                  {
                                    'value': 'Female',
                                    'icon': Icons.female,
                                    'label': 'Female'
                                  },
                                  {
                                    'value': 'Other',
                                    'icon': Icons.transgender,
                                    'label': 'Other'
                                  },
                                ].map((genderOption) {
                                  return Expanded(
                                    flex: 1,
                                    child: TextButton(
                                      style: TextButton.styleFrom(
                                        backgroundColor: whiteColor,
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5, horizontal: 16),
                                        foregroundColor:
                                            gender == genderOption['value']
                                                ? primaryColor
                                                : blackColor,
                                      ),
                                      onPressed: () => setState(() {
                                        gender = genderOption['value'];
                                      }),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            genderOption['icon'],
                                            color:
                                                gender == genderOption['value']
                                                    ? primaryColor
                                                    : blackColor,
                                          ),
                                          const SizedBox(width: 8.0),
                                          Text(
                                            genderOption['label'],
                                            style: TextStyle(
                                                color: gender ==
                                                        genderOption['value']
                                                    ? primaryColor
                                                    : blackColor,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              const SizedBox(
                                height: 10,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: patientEmailController,
                                  onChanged: (value) =>
                                      setState(() => email = value),
                                  keyboardType: TextInputType.emailAddress,
                                  cursorColor: Colors.black54,
                                  style: const TextStyle(
                                      color: blackColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    prefixIcon: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
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
                              const SizedBox(
                                height: 20,
                              ),
                              SizedBox(
                                width: double.infinity,
                                child: TextFormField(
                                  controller: patientPhoneController,
                                  onChanged: (value) =>
                                      setState(() => phone = value),
                                  keyboardType: TextInputType.number,
                                  cursorColor: Colors.black54,
                                  style: const TextStyle(
                                      color: blackColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    prefixIcon: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
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
                                child: TextFormField(
                                  controller: patientAddressController,
                                  onChanged: (value) =>
                                      setState(() => address = value),
                                  cursorColor: Colors.black54,
                                  style: const TextStyle(
                                      color: blackColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    prefixIcon: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 8.0),
                                      child: Icon(
                                        Icons.location_on,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    hintText: 'Address',
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
                                ),
                              ),
                              const SizedBox(
                                height: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 140,
                        right: 0,
                        left: 0,
                        child: Center(
                          child: Stack(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  isLoadingImage ? null : pickImage();
                                },
                                child: imageValid
                                    ? CircleAvatar(
                                        backgroundImage:
                                            NetworkImage(imagePath),
                                        radius: 50,
                                      )
                                    : CircleAvatar(
                                        backgroundColor: const Color.fromARGB(
                                            255, 255, 255, 255),
                                        radius: 50,
                                        child: isLoadingImage
                                            ? const CircularProgressIndicator(
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                        Color>(primaryColor),
                                              )
                                            : const Icon(
                                                Icons.account_circle,
                                                size: 100,
                                                color: Colors.black54,
                                              ),
                                      ),
                              ),
                              Positioned(
                                bottom: 6,
                                right: 3,
                                child: GestureDetector(
                                  onTap: () {
                                    pickImage();
                                  },
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.green,
                                    child: Icon(Icons.camera_alt,
                                        size: 17, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 30,
                        left: 10,
                        child: Center(
                          child: Stack(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: blackColor.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: whiteColor,
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context, imagePath);
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        bottomNavigationBar: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isLoading ? Colors.black54 : primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(0),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
            onPressed: isLoading
                ? null
                : () {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        isLoading = true;
                      });
                      Map<String, dynamic> updatedFields = {
                        'patient_name': name,
                        'patient_email': email,
                        'patient_phone': phone,
                        'patient_address': address,
                        'patient_gender': gender,
                      };
                      updatePatient(updatedFields);
                    }
                  },
            child: const Text(
              'Save Changes',
              style: TextStyle(
                  color: Color.fromARGB(255, 255, 255, 255),
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ));
  }
}
