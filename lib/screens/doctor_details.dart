import 'package:flutter/material.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class DoctorDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> doctor;

  DoctorDetailsScreen({Key? key, required this.doctor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String departmentName = getDepartmentName(doctor['department_id']);
    return Scaffold(
      backgroundColor: whiteColor,
      appBar: AppBar(
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
        title: const Text(
          'Doctor Details',
          style: TextStyle(color: whiteColor),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDoctorProfile(),
              const SizedBox(height: 20),
              _buildInfoRow(Icons.local_hospital, 'Department', departmentName),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.school, 'Experience', doctor['doctor_description']),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.medical_information, 'Expertise', doctor['summary']),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorProfile() {
    bool isDean = doctor['doctor_name'].toLowerCase().contains('dean');

    return Row(
      children: [
        CircleAvatar(
          backgroundImage: NetworkImage(doctor['doctor_image']),
          radius: 50,
        ),
        const SizedBox(width: 20),
        Expanded( // Sử dụng Expanded để giới hạn chiều rộng của cột
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctor['doctor_name'].toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: blackColor,
                ),
                softWrap: true,
                maxLines: null,
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: blueColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'Doctor',
                      style: TextStyle(
                        fontSize: 16,
                        color: blackColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isDean) ...[
                    const SizedBox(width: 10), // Thêm khoảng cách giữa 2 Container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Text(
                        'Dean',
                        style: TextStyle(
                          fontSize: 16,
                          color: blackColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }




  // Widget to build an information row with icons
  Widget _buildInfoRow(IconData icon, String title, String info) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Giúp phần text không bị đẩy lên trên
      children: [
        Icon(icon, color: primaryColor, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: blackColor,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                info,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.bold,
                ),
                softWrap: true,
                maxLines: null,
              ),
            ],
          ),
        ),
      ],
    );
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
}
