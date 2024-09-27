import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';

import 'google_signin_button.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class Login extends StatefulWidget {
  final Function(int) onLogin;

  const Login({super.key, required this.onLogin});

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );
  String name = '';
  String email = '';
  String phone = '';
  String password = '';

  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();
  final _forgotPassKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _passConfirmController = TextEditingController();
  final TextEditingController _resetCodeController = TextEditingController();


  bool _isRegisterVisible = false;
  bool _isResetPassVisible = false;
  bool isLoading = false;
  bool isGetCodeLoading = false;
  bool _hidePass = true;
  bool _hideConfirmPass = true;
  bool isCountingDown = false;
  int countdown = 60;

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    email = _emailController.text;
    password = _passController.text;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/patients/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'patient_email': email, 'patient_password': password}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final int patientId = data['patient_id'];
        widget.onLogin(patientId);
        showTemporaryMessage(context, "Log in successfully!");
        Navigator.pop(context);
      } else {
        showTemporaryMessage(context, "Invalid email address or password.");
      }
    } catch (error) {
      showTemporaryMessage(context, "Error during login. Please try again.");
      print(error);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    email = _emailController.text;
    name = _nameController.text;
    password = _passController.text;
    phone = _phoneController.text;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/patients/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_name': name,
          'patient_email': email,
          'patient_phone': phone,
          'patient_password': password
        }),
      );
      if (response.statusCode == 201) {
        showTemporaryMessage(context, "Registration successfully!");
        _toggleRegister();
      } else if (response.statusCode == 409) {
        showTemporaryMessage(context, "Email address already registered!");
      } else {
        showTemporaryMessage(context, "Registration failed. Please try again.");
      }
    } catch (error) {
      showTemporaryMessage(
          context, "Error during registration. Please try again.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handlePasswordReset() async {
    FocusScope.of(context).unfocus();
    final String email = _emailController.text;
    final String code = _resetCodeController.text;
    final String password = _passController.text;

    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.put(
        Uri.parse('https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/forgotpass/reset'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_email': email,
          'patient_code': code,
          'new_password': password,
        }),
      );
      if (response.statusCode == 200) {
        setState(() {
          showTemporaryMessage(context, "Password reset successfully!");
          _toggleResetPassword();
        });
      } else {
        showTemporaryMessage(context, "Invalid verification code.");
      }
    } catch (error) {
      showTemporaryMessage(
          context, "Error during password reset. Please try again.");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _handleGetCode() async {
    FocusScope.of(context).unfocus();
    final String email = _emailController.text;
    setState(() {
      isGetCodeLoading = true;
    });
    try {
      final response = await http.put(
        Uri.parse('https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/forgotpass/forgot'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patient_email': email,
          'patient_code': _generateRandomCode(),
        }),
      );

      if (response.statusCode == 200) {
        showTemporaryMessage(
            context, "Verification code has been sent to your email.");
        setState(() {
          isCountingDown = true;
        });
      } else {
        showTemporaryMessage(context,
            "Unable to send verification code. Please check email address and try again.");
      }
    } catch (error) {
      showTemporaryMessage(
          context, "Error during sending verification code. Please try again.");
    } finally {
      setState(() {
        isGetCodeLoading = false;
        _startCountdown();
      });
    }
  }

  String _generateRandomCode() {
    return (100000 +
            (1000000 - 100000) *
                (DateTime.now().millisecondsSinceEpoch % 1))
        .toString();
  }

  void _startCountdown() {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        timer.cancel();
        setState(() {
          isCountingDown = false;
          countdown = 60;
        });
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }

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

  void _toggleRegister() {
    setState(() {
      _isRegisterVisible = !_isRegisterVisible;
      _emailController.clear();
      _passController.clear();
      _passConfirmController.clear();
      _resetCodeController.clear();
      _nameController.clear();
    });
  }

  void _toggleResetPassword() {
    setState(() {
      _isResetPassVisible = !_isResetPassVisible;
      _emailController.clear();
      _passController.clear();
      _passConfirmController.clear();
      _resetCodeController.clear();
      _nameController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
        backgroundColor: whiteColor,
        leading: IconButton(
          icon: const Icon(
            Icons.clear,
            color: blackColor,
            size: 25,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isRegisterVisible
              ? _buildRegisterForm()
              : _isResetPassVisible
                  ? _buildForgotPassForm()
                  : _buildLoginForm(),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
        key: _loginKey,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/images/esavior-high-resolution-logo-transparent.png'),
                    fit: BoxFit.contain, // Ensures the entire logo is visible
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20,),
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
            const SizedBox(
              height: 20,
            ),

            SizedBox(
              width: double.infinity,
              child: TextFormField(
                obscureText: _hidePass,
                controller: _passController,
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
                  hintText: 'Password',
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
              height: 10,
            ),
            Container(
              margin: const EdgeInsets.only(left: 5),
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: _toggleResetPassword,
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
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
                        if (_loginKey.currentState?.validate() ?? false) {
                          _handleLogin();
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      )
                    : const Text(
                        'Log in',
                        style: TextStyle(
                            color: whiteColor,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Don't have an account?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // Nút đăng nhập Google
                GoogleSignInButton(
                  onLoginSuccess: (patientName, patientId) {
                    print('Logged in with Google: $patientName');

                    // Gọi hàm xử lý đăng nhập với ID bệnh nhân từ Google Login
                    widget.onLogin(int.parse(patientId));
                    // Hiển thị thông báo đăng nhập thành công
                    // Điều hướng về trang trước hoặc Home
                    Navigator.pop(context);
                  },
                ),

                Container(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _toggleRegister,
                    child: const Text(
                      'Register',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ));
  }

  Widget _buildRegisterForm() {
    return Form(
        key: _registerKey,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/images/esavior-high-resolution-logo-transparent.png'),
                    fit: BoxFit.contain, // Ensures the entire logo is visible
                  ),
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
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
              child: TextFormField(
                obscureText: _hidePass,
                controller: _passController,
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
                  hintText: 'Password',
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
                obscureText: _hideConfirmPass,
                controller: _passConfirmController,
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
                      _hideConfirmPass
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _hideConfirmPass = !_hideConfirmPass;
                      });
                    },
                  ),
                  hintText: 'Confirm Password',
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
                        if (_registerKey.currentState?.validate() ?? false) {
                          _handleRegister();
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      )
                    : const Text(
                        'Register',
                        style: TextStyle(
                            color: whiteColor,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Already have an account?",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: blackColor,
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _toggleRegister,
                    child: const Text(
                      'Log in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ));
  }

  Widget _buildForgotPassForm() {
    return Form(
        key: _forgotPassKey,
        child: Column(
          children: [
            Center(
              child: Container(
                width: 150,
                height: 150,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/images/esavior-high-resolution-logo-transparent.png'),
                    fit: BoxFit.contain, // Ensures the entire logo is visible
                  ),
                ),
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
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              width: double.infinity,
              child: TextFormField(
                keyboardType: TextInputType.number,
                controller: _resetCodeController,
                cursorColor: Colors.black54,
                style: const TextStyle(
                    color: blackColor,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.verified_user,
                      color: Colors.black54,
                    ),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: isGetCodeLoading
                        ? null
                        : isCountingDown
                            ? null
                            : () {
                                _handleGetCode();
                              },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.black54,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: isGetCodeLoading
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 8),
                                  child: SizedBox(
                                    width: 16.0,
                                    height: 16.0,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          primaryColor),
                                    ),
                                  ),
                                )
                              : isCountingDown
                                  ? Text(
                                      'Sent ($countdown)',
                                      style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                          // Đổi màu để thể hiện nút không bấm được
                                          fontWeight: FontWeight.bold),
                                    )
                                  : GestureDetector(
                                      onTap: _handleGetCode,
                                      child: const Text(
                                        'Send',
                                        style: TextStyle(
                                            fontSize: 14,
                                            color: blueColor,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                        ),
                      ],
                    ),
                  ),
                  hintText: 'Verification Code',
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Verification code cannot be empty';
                  }
                  if (!RegExp(r'^\d+$').hasMatch(value)) {
                    return 'Invalid verification code';
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
                obscureText: _hidePass,
                controller: _passController,
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
                  hintText: 'Password',
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
                obscureText: _hideConfirmPass,
                controller: _passConfirmController,
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
                      _hideConfirmPass
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.black54,
                    ),
                    onPressed: () {
                      setState(() {
                        _hideConfirmPass = !_hideConfirmPass;
                      });
                    },
                  ),
                  hintText: 'Confirm Password',
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
                        if (_forgotPassKey.currentState?.validate() ?? false) {
                          _handlePasswordReset();
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 24.0,
                        height: 24.0,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(primaryColor),
                        ),
                      )
                    : const Text(
                        'Reset Password',
                        style: TextStyle(
                            color: whiteColor,
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _toggleResetPassword,
                    child: const Text(
                      'Back to log in',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ],
            )
          ],
        ));
  }
}
