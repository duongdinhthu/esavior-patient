import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class ChangePassword extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  ChangePassword({
    required this.isLoggedIn,
    required this.onLogout,
    this.patientId,
  });

  @override
  _ChangePasswordState createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  String currentPassword = '';
  String newPassword = '';
  String confirmNewPassword = '';
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool _hidePass = true;

  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmNewPasswordController =
      TextEditingController();

  String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password cannot be empty';
    }

    // Kiểm tra độ dài mật khẩu
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    // Kiểm tra có ít nhất 1 chữ thường
    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'Password must contain at least 1 lowercase letter';
    }
    // Kiểm tra có ít nhất 1 chữ hoa
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least 1 uppercase letter';
    }
    // Kiểm tra có ít nhất 1 chữ số
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least 1 number';
    }
    // Kiểm tra có ít nhất 1 ký tự đặc biệt
    if (!value.contains(RegExp(r'[!@#$%^&*()_+]'))) {
      return 'Password must contain at least 1 special character';
    }

    return null; // Nếu hợp lệ
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

  Future<void> changePassword() async {
    FocusScope.of(context).unfocus();
    setState(() {
      isLoading = true;
    });
    if (newPassword != confirmNewPassword) {
      showTemporaryMessage(
          context, "Passwords do not match. Please try again.");
      return;
    }

    final url = Uri.parse(
        'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/patients/change-password');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "patient_id": widget.patientId.toString(),
          "currentPassword": currentPassword,
          "newPassword": newPassword,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          currentPassword = '';
          newPassword = '';
          confirmNewPassword = '';
          currentPasswordController.clear();
          newPasswordController.clear();
          confirmNewPasswordController.clear();
          showTemporaryMessage(context, "Password changed successfully!");
        });
      } else {
        print(response.statusCode);
        showTemporaryMessage(
            context, "Invalid current password. Please try again.");
      }
    } catch (error) {
      print('Error changing password: $error');
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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 30,
                  ),
                  const Text(
                    'Change Password',
                    style: TextStyle(
                        color: primaryColor,
                        fontSize: 22,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(
                    height: 30,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      obscureText: _hidePass,
                      controller: currentPasswordController,
                      onChanged: (value) {
                        setState(() => currentPassword = value);
                        validatePassword(value);
                      },
                      cursorColor: Colors.black54,
                      style: const TextStyle(
                          color: blackColor,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.lock,
                            color: Colors.black54,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePass ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _hidePass = !_hidePass;
                            });
                          },
                        ),
                        hintText: 'Current Password',
                        hintStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      validator: validatePassword,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      obscureText: _hidePass,
                      controller: newPasswordController,
                      onChanged: (value) {
                        setState(() => newPassword = value);
                        validatePassword(value);
                      },
                      cursorColor: Colors.black54,
                      style: const TextStyle(
                          color: blackColor,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.lock,
                            color: Colors.black54,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePass ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _hidePass = !_hidePass;
                            });
                          },
                        ),
                        hintText: 'New Password',
                        hintStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      validator: validatePassword,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: TextFormField(
                      obscureText: _hidePass,
                      controller: confirmNewPasswordController,
                      onChanged: (value) {
                        setState(() => confirmNewPassword = value);
                        validatePassword(value);
                      },
                      cursorColor: Colors.black54,
                      style: const TextStyle(
                          color: blackColor,
                          fontSize: 16.0,
                          fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(
                            Icons.lock,
                            color: Colors.black54,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _hidePass ? Icons.visibility_off : Icons.visibility,
                            color: Colors.black54,
                          ),
                          onPressed: () {
                            setState(() {
                              _hidePass = !_hidePass;
                            });
                          },
                        ),
                        hintText: 'Confirm New Password',
                        hintStyle: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                        focusedBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        enabledBorder: const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.black54, width: 1.0),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        focusedErrorBorder: const OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.red,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(15)),
                        ),
                        errorStyle: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      validator: validatePassword,
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
                      onPressed: isLoading
                          ? null
                          : () {
                              if (_formKey.currentState?.validate() ?? false) {
                                changePassword();
                              }
                            },
                      child: isLoading
                          ? const SizedBox(
                              width: 24.0,
                              height: 24.0,
                              child: CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Submit',
                              style: TextStyle(
                                color: whiteColor,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold
                              ),
                            ),
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
