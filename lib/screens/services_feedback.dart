import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class ServicesFeedback extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  ServicesFeedback({
    required this.isLoggedIn,
    required this.onLogout,
    this.patientId,
  });

  @override
  _ServicesFeedbackState createState() => _ServicesFeedbackState();
}

class _ServicesFeedbackState extends State<ServicesFeedback> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();

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

  Future<void> handleSubmit() async {
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
    });
    final feedbackData = {
      'name': _nameController.text,
      'phone': _phoneController.text,
      'email': _emailController.text,
      'subject': _subjectController.text,
      'message': _messageController.text,
    };

    final url = Uri.parse(
        'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/feedback/submit');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(feedbackData),
      );

      if (response.statusCode == 200) {
        setState(() {
          _nameController.clear();
          _phoneController.clear();
          _emailController.clear();
          _subjectController.clear();
          _messageController.clear();
          showTemporaryMessage(context, "Feedback sent successfully!");
        });
      } else {
        setState(() {
          showTemporaryMessage(context, "Failed to send feedback!");
        });
      }
    } catch (error) {
      setState(() {
        showTemporaryMessage(context, "Failed to send feedback!");
      });
      print(error);
    }
    setState(() {
      isLoading = false;
    });
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
        appBar: AppBar(
          backgroundColor: primaryColor,
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
        ),
        body: isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                ),
              )
            : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            const SizedBox(
                              height: 30,
                            ),
                            const Text(
                              'Send Feedback',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              'Please fill out the form below and send your comments and questions to FPT Health.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 16, color: Colors.black54, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _nameController,
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
                              height: 20,
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: TextFormField(
                                controller: _phoneController,
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
                                controller: _emailController,
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
                                controller: _subjectController,
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
                                      Icons.subject,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  hintText: 'Subject',
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
                                    return 'Subject cannot be empty';
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
                                maxLines: 5,
                                controller: _messageController,
                                cursorColor: Colors.black54,
                                style: const TextStyle(
                                    color: blackColor,
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold),
                                decoration: const InputDecoration(
                                  hintText: 'Message',
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
                                    return 'Message cannot be empty';
                                  }
                                  return null;
                                },
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
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 15),
                                ),
                                onPressed: isLoading
                                    ? null
                                    : () {
                                        if (_formKey.currentState?.validate() ??
                                            false) {
                                          handleSubmit();
                                        }
                                      },
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24.0,
                                        height: 24.0,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Send',
                                        style: TextStyle(
                                            color: Color.fromARGB(
                                                255, 255, 255, 255),
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ));
  }
}
