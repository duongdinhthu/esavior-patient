import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class AppointmentList extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  AppointmentList({
    required this.isLoggedIn,
    required this.onLogout,
    this.patientId,
  });

  @override
  _AppointmentListState createState() => _AppointmentListState();
}

class _AppointmentListState extends State<AppointmentList> {
  List<dynamic> appointments = [];
  int currentPage = 0;
  int appointmentsPerPage = 5;
  bool isLoading = false;

  String getSlotTime(int slot) {
    switch (slot) {
      case 1:
        return "08:00 AM - 09:00 AM";
      case 2:
        return "09:00 AM - 10:00 AM";
      case 3:
        return "10:00 AM - 11:00 AM";
      case 4:
        return "11:00 AM - 12:00 AM";
      case 5:
        return "01:00 PM - 02:00 PM";
      case 6:
        return "02:00 PM - 03:00 PM";
      case 7:
        return "03:00 PM - 04:00 PM";
      case 8:
        return "04:00 PM - 05:00 PM";
      default:
        return "Unknown Slot";
    }
  }

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
            appointments = patientData[0]['appointmentsList'] ?? [];
            appointments.sort((a, b) {
              DateTime dateA = DateTime.parse(a['appointment_date']);
              DateTime dateB = DateTime.parse(b['appointment_date']);
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

  List<dynamic> getPaginatedAppointments() {
    int startIndex = currentPage * appointmentsPerPage;
    int endIndex =
        (startIndex + appointmentsPerPage).clamp(0, appointments.length);
    return appointments.sublist(startIndex, endIndex);
  }

  Widget buildAppointments() {
    var paginatedAppointments = getPaginatedAppointments();

    return ListView.builder(
      itemCount: paginatedAppointments.length,
      itemBuilder: (context, index) {
        var appointment = paginatedAppointments[index];
        var doctorInfo =
            (appointment['doctor'] is List && appointment['doctor'].isNotEmpty)
                ? appointment['doctor'][0]
                : null;

        int slot = appointment['slot'] ?? 0;
        String slotTime = getSlotTime(slot);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
            side: const BorderSide(
              color: Colors.black54,
              width: 1,
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: whiteColor,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${appointment['appointment_date']}",
                        style: const TextStyle(
                            fontSize: 18,
                            color: primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Doctor: ${doctorInfo != null ? doctorInfo['doctor_name'] : 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Appointment Date: ${appointment['medical_day'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Appointment Time: $slotTime",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Status: ${appointment['status'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: primaryColor),
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
    int totalPages = (appointments.length / appointmentsPerPage).ceil();
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
              color: primaryColor, fontSize: 14, fontWeight: FontWeight.bold),
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
                      'Booked Appointment',
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
                appointments.isEmpty
                    ? const Expanded(
                        child: Center(
                        child: Text(
                          'No appointment available',
                          style: TextStyle(
                              color: blackColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ))
                    : Expanded(
                        child: buildAppointments(),
                      ),
                buildPaginationControls(),
              ],
            ),
    );
  }
}
