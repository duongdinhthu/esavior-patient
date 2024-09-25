import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class Diagnosis extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId; // patientId là số nguyên

  Diagnosis({required this.isLoggedIn, required this.onLogout, this.patientId});

  @override
  _DiagnosisState createState() => _DiagnosisState();
}

class _DiagnosisState extends State<Diagnosis> {
  final GlobalKey<ScaffoldState> _scaffoldKey =
      GlobalKey<ScaffoldState>(); // Thêm GlobalKey

  List<XFile>? selectedFiles = []; // Danh sách file đã chọn
  bool loading = false;
  bool isLoading = false;
  String fullText = '';
  String comparisonMessage = '';
  double severity = 0.0; // Giá trị mức độ nghiêm trọng
  List medicalHistory = []; // Lưu lịch sử bệnh án của bệnh nhân

  @override
  void initState() {
    super.initState();
    loadMedicalHistory(); // Gọi API để lấy lịch sử bệnh án nếu đã đăng nhập
  }

  // Lấy lịch sử bệnh án
  Future<void> loadMedicalHistory() async {
    setState(() {
      loading = true;
    });

    try {
      // Thay đổi URL để sử dụng patientId kiểu int
      final response = await http.get(
        Uri.parse(
            'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/medicalrecords/search?patient_id=${widget.patientId}'),
      );

      if (response.statusCode == 200) {
        final List history = json.decode(response.body);
        setState(() {
          medicalHistory = history;
        });
      }
    } catch (error) {
      print('Error loading medical history: $error');
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  // So sánh tình trạng bệnh với lần khám trước
  Future<Map<String, dynamic>?> findPreviousDiagnosis(String conclusion) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/medicalrecords/search?patient_id=${widget.patientId}'),
      );

      if (response.statusCode == 200) {
        final List records = json.decode(response.body);
        return records.lastWhere((record) => record['diagnosis'] == conclusion,
            orElse: () => null);
      }
    } catch (error) {
      print('Error finding previous diagnosis: $error');
    }
    return null;
  }

  // Chọn ảnh từ thư viện
  Future<void> pickImageFromGallery() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile>? pickedFiles = await picker.pickMultiImage();

    if (pickedFiles != null && pickedFiles.isNotEmpty) {
      setState(() {
        selectedFiles = pickedFiles;
      });
    }
  }

  // Chụp ảnh từ camera
  Future<void> pickImageFromCamera() async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      print("Picked image: ${photo.path}"); // In ra đường dẫn file
      setState(() {
        selectedFiles = [photo];
      });
    }
  }
  Future<void> handleSubmit() async {
    if (selectedFiles == null || selectedFiles!.isEmpty) return;

    // Thay đổi URL sang Flask server
    final uri = Uri.parse('http://10.0.2.2:8000/predict');
    final request = http.MultipartRequest('POST', uri);

    // Thêm các file vào request
    for (var file in selectedFiles!) {
      request.files.add(await http.MultipartFile.fromPath('files', file.path));
    }

    setState(() {
      isLoading = true;
      fullText = ''; // Reset văn bản đầy đủ
    });

    try {
      // Gửi yêu cầu với tệp đến Flask
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final result = json.decode(responseData);

        final String conclusion = result['conclusion'].toString();  // Đảm bảo là String
        final String advice = result['advice'].toString();  // Đảm bảo là String
        final String prescription = result['prescription'].toString();  // Đảm bảo là String

        // Nhận giá trị 'severity' và đảm bảo kiểu double
        final double severity = result['severity'] is double
            ? result['severity']  // Nếu là double, dùng trực tiếp
            : (result['severity'] is int  // Nếu là int, chuyển thành double
            ? result['severity'].toDouble()
            : (result['severity'] is String
            ? double.tryParse(result['severity']) ?? 0.0  // Nếu là String, chuyển thành double
            : 0.0));  // Giá trị mặc định nếu không hợp lệ

        // So sánh tình trạng hiện tại với lần khám trước
        final previousDiagnosis = await findPreviousDiagnosis(conclusion);
        if (previousDiagnosis != null) {
          if (severity >
              double.parse(previousDiagnosis['severity'].toString())) {
            comparisonMessage =
                'The current medical condition is more severe than the last visit.';
          } else {
            comparisonMessage =
                'Current medical condition is better than last visit.';
          }
        } else {
          comparisonMessage = 'This is the first examination for this disease.';
        }

        setState(() {
          fullText =
              'Conclusion: $conclusion\nAdvice: $advice\nPrescription: $prescription';
        });

        await saveMedicalRecordToDatabase(
            conclusion, advice, prescription, severity.toStringAsFixed(2));
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during prediction: $error');
    } finally {
      setState(() {
        isLoading = false;
        showDiagnosisDialog(context);
      });
    }
  }

  // Future<void> handleSubmit() async {
  //   if (selectedFiles == null || selectedFiles!.isEmpty) return;
  //
  //   // Thay đổi URL sang Flask server
  //   final uri = Uri.parse('http://10.0.2.2:8000/predict');
  //   final request = http.MultipartRequest('POST', uri);
  //
  //   // Thêm các file vào request
  //   for (var file in selectedFiles!) {
  //     request.files.add(await http.MultipartFile.fromPath('files', file.path));
  //   }
  //
  //   setState(() {
  //     loading = true;
  //     fullText = ''; // Reset văn bản đầy đủ
  //   });
  //
  //   try {
  //     // Gửi yêu cầu với tệp đến Flask
  //     final response = await request.send();
  //
  //     if (response.statusCode == 200) {
  //       final responseData = await response.stream.bytesToString();
  //       final result = json.decode(responseData);
  //
  //       final String conclusion = result['conclusion'].toString();  // Đảm bảo là String
  //       final String advice = result['advice'].toString();  // Đảm bảo là String
  //       final String prescription = result['prescription'].toString();  // Đảm bảo là String
  //
  //       // Nhận giá trị 'severity' và đảm bảo kiểu double
  //       final double severity = result['severity'] is double
  //           ? result['severity']  // Nếu là double, dùng trực tiếp
  //           : (result['severity'] is int  // Nếu là int, chuyển thành double
  //               ? result['severity'].toDouble()
  //               : (result['severity'] is String
  //                   ? double.tryParse(result['severity']) ?? 0.0  // Nếu là String, chuyển thành double
  //                   : 0.0));  // Giá trị mặc định nếu không hợp lệ
  //
  //       // So sánh tình trạng hiện tại với lần khám trước
  //       final previousDiagnosis = await findPreviousDiagnosis(conclusion);
  //       if (previousDiagnosis != null) {
  //         if (severity > double.parse(previousDiagnosis['severity'].toString())) {
  //           comparisonMessage = 'Tình trạng bệnh hiện tại nặng hơn lần khám trước.';
  //         } else {
  //           comparisonMessage = 'Tình trạng bệnh hiện tại đỡ hơn lần khám trước.';
  //         }
  //       } else {
  //         comparisonMessage = 'Đây là lần khám đầu tiên cho bệnh này.';
  //       }
  //
  //       setState(() {
  //         fullText = 'Conclusion: $conclusion\nAdvice: $advice\nPrescription: $prescription';
  //       });
  //
  //       // *** LƯU CHẨN ĐOÁN VÀO CƠ SỞ DỮ LIỆU ***
  //       await saveMedicalRecordToDatabase(conclusion, advice, prescription, severity.toStringAsFixed(2));
  //     } else {
  //       print('Error: ${response.statusCode}');
  //     }
  //   } catch (error) {
  //     print('Error during prediction: $error');
  //   } finally {
  //     setState(() {
  //       loading = false;
  //     });
  //   }
  // }Future<void> handleSubmit() async {
  //   if (selectedFiles == null || selectedFiles!.isEmpty) return;
  //
  //   // Thay đổi URL sang Flask server
  //   final uri = Uri.parse('http://10.0.2.2:8000/predict');
  //   final request = http.MultipartRequest('POST', uri);
  //
  //   // Thêm các file vào request
  //   for (var file in selectedFiles!) {
  //     request.files.add(await http.MultipartFile.fromPath('files', file.path));
  //   }
  //
  //   setState(() {
  //     loading = true;
  //     fullText = ''; // Reset văn bản đầy đủ
  //   });
  //
  //   try {
  //     // Gửi yêu cầu với tệp đến Flask
  //     final response = await request.send();
  //
  //     if (response.statusCode == 200) {
  //       final responseData = await response.stream.bytesToString();
  //       final result = json.decode(responseData);
  //
  //       final String conclusion = result['conclusion'].toString();  // Đảm bảo là String
  //       final String advice = result['advice'].toString();  // Đảm bảo là String
  //       final String prescription = result['prescription'].toString();  // Đảm bảo là String
  //
  //       // Nhận giá trị 'severity' và đảm bảo kiểu double
  //       final double severity = result['severity'] is double
  //           ? result['severity']  // Nếu là double, dùng trực tiếp
  //           : (result['severity'] is int  // Nếu là int, chuyển thành double
  //               ? result['severity'].toDouble()
  //               : (result['severity'] is String
  //                   ? double.tryParse(result['severity']) ?? 0.0  // Nếu là String, chuyển thành double
  //                   : 0.0));  // Giá trị mặc định nếu không hợp lệ
  //
  //       // So sánh tình trạng hiện tại với lần khám trước
  //       final previousDiagnosis = await findPreviousDiagnosis(conclusion);
  //       if (previousDiagnosis != null) {
  //         if (severity > double.parse(previousDiagnosis['severity'].toString())) {
  //           comparisonMessage = 'Tình trạng bệnh hiện tại nặng hơn lần khám trước.';
  //         } else {
  //           comparisonMessage = 'Tình trạng bệnh hiện tại đỡ hơn lần khám trước.';
  //         }
  //       } else {
  //         comparisonMessage = 'Đây là lần khám đầu tiên cho bệnh này.';
  //       }
  //
  //       setState(() {
  //         fullText = 'Conclusion: $conclusion\nAdvice: $advice\nPrescription: $prescription';
  //       });
  //
  //       // *** LƯU CHẨN ĐOÁN VÀO CƠ SỞ DỮ LIỆU ***
  //       await saveMedicalRecordToDatabase(conclusion, advice, prescription, severity.toStringAsFixed(2));
  //     } else {
  //       print('Error: ${response.statusCode}');
  //     }
  //   } catch (error) {
  //     print('Error during prediction: $error');
  //   } finally {
  //     setState(() {
  //       loading = false;
  //     });
  //   }
  // }
  //
  // Hàm lưu bệnh án vào cơ sở dữ liệu qua Spring Boot API
  Future<void> saveMedicalRecordToDatabase(String conclusion, String advice,
      String prescription, String severity) async {
    try {
      final uri = Uri.parse(
          'https://javamvc-f6fme9d4h6beehe3.japaneast-01.azurewebsites.net/api/v1/medicalrecords/insert');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'patient_id': widget.patientId,
          'diagnosis': conclusion,
          'treatment': advice,
          'prescription': prescription,
          'severity': severity, // Đảm bảo 2 chữ số thập phân
          'follow_up_date': DateTime.now().toIso8601String(), // Thêm ngày khám
          'imagePaths': selectedFiles!.map((file) => file.path).toList(),
        }),
      );

      if (response.statusCode == 200) {
        print('Medical record saved successfully');
      } else {
        print('Error saving medical record: ${response.statusCode}');
      }
    } catch (error) {
      print('Error during saving medical record: $error');
    }
  }

  // Hiển thị hướng dẫn chụp ảnh
  void showInstructionsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          title: const Text(
            "How to take a photo?",
            style: TextStyle(
              color: blackColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "1. Take the photo about 4 inches away from the problem area.",
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "2. Center your symptom in the photo.",
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "3. Ensure your photo isn't blurry.",
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "4. Make sure there is good lighting.",
                  style: TextStyle(
                    color: blackColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "I Understand!",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void showDiagnosisDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(15.0)),
          ),
          title: const Text(
            "Diagnosis Result",
            style: TextStyle(
              color: blackColor,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fullText.isNotEmpty)
                  Text(
                    fullText,
                    style: const TextStyle(
                        fontSize: 16,
                        color: primaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                if (comparisonMessage.isNotEmpty)
                  Text(
                    comparisonMessage,
                    style: const TextStyle(
                        fontSize: 16,
                        color: blackColor,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                "I Got It!",
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading
        ? const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          )
        : Scaffold(
            appBar: AppBar(
              backgroundColor: primaryColor,
              title: const Center(
                child: Text(
                  'Diagnostic Imaging',
                  style: TextStyle(
                      color: whiteColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 20),
                ),
              ),
            ),
            backgroundColor: whiteColor,
            key: _scaffoldKey,
            body: SingleChildScrollView(
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
                  : Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 30),
                          const Center(
                            child: Text(
                              'Upload Your Photo',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: whiteColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                side: const BorderSide(
                                    color: blackColor, width: 1),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: pickImageFromCamera,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt,
                                    color: blackColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Take Photo',
                                    style: TextStyle(
                                      color: blackColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.symmetric(vertical: 10),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: whiteColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                side: const BorderSide(
                                    color: blackColor, width: 1),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: pickImageFromGallery,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: blackColor,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pick From Gallery',
                                    style: TextStyle(
                                      color: blackColor,
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          TextButton(
                              onPressed: () => showInstructionsDialog(context),
                              child: const Text(
                                'How to take a photo?',
                                style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold),
                              )),
                          if (selectedFiles != null &&
                              selectedFiles!.isNotEmpty)
                            const SizedBox(height: 20),
                          if (selectedFiles != null &&
                              selectedFiles!.isNotEmpty)
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              alignment: WrapAlignment.center,
                              children: selectedFiles!.map((file) {
                                return Card(
                                  elevation: 4,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(file.path),
                                      width: 150,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(top: 20),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 15),
                              ),
                              onPressed: (selectedFiles != null &&
                                      selectedFiles!.isNotEmpty || isLoading)
                                  ? handleSubmit
                                  : null,
                              child: isLoading
                                  ? const SizedBox(
                                      width: 24.0,
                                      height: 24.0,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                                primaryColor),
                                      ),
                                    )
                                  : const Text(
                                      'Diagnosis',
                                      style: TextStyle(
                                          color: whiteColor,
                                          fontSize: 16.0,
                                          fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                          const SizedBox(
                            height: 30,
                          )
                        ],
                      ),
                    ),
            ),
          );
  }
}
