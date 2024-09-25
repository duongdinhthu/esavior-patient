import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class MedicalRecords extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  MedicalRecords({
    required this.isLoggedIn,
    required this.onLogout,
    this.patientId,
  });

  @override
  _MedicalRecordsState createState() => _MedicalRecordsState();
}

class _MedicalRecordsState extends State<MedicalRecords> {
  List<dynamic> medicalRecords = [];
  int currentPage = 0;
  int medicalRecordsPerPage = 5;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchPatientData();
  }

  // Fetch patient data
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
            medicalRecords = patientData[0]['medicalrecordsList'] ?? [];
            medicalRecords.sort((a, b) {
              DateTime dateA = DateTime.parse(a['follow_up_date']);
              DateTime dateB = DateTime.parse(b['follow_up_date']);
              return dateB.compareTo(dateA);
            });
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

  List<dynamic> getPaginatedMedicalRecords() {
    int startIndex = currentPage * medicalRecordsPerPage;
    int endIndex =
        (startIndex + medicalRecordsPerPage).clamp(0, medicalRecords.length);
    return medicalRecords.sublist(startIndex, endIndex);
  }

  Widget buildMedicalRecords() {
    var paginatedMedicalRecords = getPaginatedMedicalRecords();

    return ListView.builder(
      itemCount: paginatedMedicalRecords.length,
      itemBuilder: (context, index) {
        var record = paginatedMedicalRecords[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0), // Bo góc cho thẻ
            side: const BorderSide(
              color: Colors.black54,
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${record['follow_up_date']}",
                        style: const TextStyle(
                            fontSize: 18,
                            color: primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Symptoms: ${record['symptoms'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Diagnosis: ${record['diagnosis'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                // Nút edit nằm ở góc dưới cùng bên phải
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.search, color: primaryColor),
                    onPressed: () {
                      // Xử lý khi nhấn nút edit
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget buildPaginationControls() {
    int totalPages = (medicalRecords.length / medicalRecordsPerPage).ceil();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: Colors.black54,
          ),
          onPressed: currentPage > 0
              ? () {
                  setState(() {
                    currentPage--;
                  });
                }
              : null,
        ),
        Text(
          'Page ${currentPage + 1} of $totalPages',
          style: const TextStyle(
              color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14),
        ),
        IconButton(
          icon: const Icon(
            Icons.arrow_forward,
            color: Colors.black54,
          ),
          onPressed: currentPage < totalPages - 1
              ? () {
                  setState(() {
                    currentPage++;
                  });
                }
              : null,
        ),
      ],
    );
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
          : Column(
              children: [
                const SizedBox(height: 30),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: whiteColor,
                  ),
                  child: const Center(
                    child: Text(
                      'Medical Records',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: primaryColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Container(
                  height: 10,
                  color: primaryColor.withOpacity(0.05),
                ),
                const SizedBox(height: 10),
                medicalRecords.isEmpty
                    ? const Expanded(
                        child: Center(
                        child: Text(
                          'No medical record available',
                          style: TextStyle(
                              color: blackColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ))
                    : Expanded(
                        child: buildMedicalRecords(),
                      ),
                buildPaginationControls(),
              ],
            ),
    );
  }
}
