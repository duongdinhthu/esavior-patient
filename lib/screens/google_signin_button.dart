import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class GoogleSignInButton extends StatelessWidget {
  final Function(String, String) onLoginSuccess;

  const GoogleSignInButton({required this.onLoginSuccess, Key? key}) : super(key: key);

  Future<void> _handleSignIn(BuildContext context) async {
    final GoogleSignIn _googleSignIn = GoogleSignIn(
      scopes: ['email'],
    );

    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser != null) {
        // Khi đăng nhập Google thành công, gửi request đến API back-end
        String randomPassword = _generateRandomPassword();
        final response = await http.post(
          Uri.parse('https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/patients/google-login'),  // URL API của bạn
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'patient_name': googleUser.displayName ?? 'No name',
            'patient_email': googleUser.email,
            'patient_password': randomPassword,
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);

          // Lấy `patient_id` và `patient_name` từ phản hồi API
          String? patientId = data['patient_id']?.toString();
          String? patientName = data['patient_name'];

          if (patientId != null && patientName != null) {
            print("Patient ID: $patientId, Patient Name: $patientName");
            // Gọi onLoginSuccess và truyền `patientId` và `patientName`
            onLoginSuccess(patientName, patientId);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Logged in successfully via Google\nAccount: ${googleUser.email}'
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Invalid response from server')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Login failed, try again.')),
          );
        }

      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $error')),
      );
    }
  }

  String _generateRandomPassword() {
    // Hàm này sẽ tạo một mật khẩu ngẫu nhiên
    return 'RandomPassword123'; // Thay bằng logic tạo mật khẩu ngẫu nhiên của bạn
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        _handleSignIn(context);
      },
      icon: Image.asset(
        'assets/images/google_logo.png',
        height: 24.0,
      ),
      label: const Text('Sign in with Google'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
