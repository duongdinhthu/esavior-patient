import 'package:flutter/material.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class About extends StatelessWidget {
  final bool isLoggedIn;
  final VoidCallback onLogout;
  final int? patientId; // Thêm patientId

  const About(
      {super.key,
      required this.isLoggedIn,
      required this.onLogout,
      this.patientId});

  @override
  Widget build(BuildContext context) {
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
      body: SingleChildScrollView(
          child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const SizedBox(
              height: 20,
            ),
            const Center(
              child: Text(
                'Terms & Conditions',
                style: TextStyle(
                    color: primaryColor,
                    fontSize: 22,
                    fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Text(
              'Welcome to eSavior. By accessing or using our website, you agree to comply with the following Terms and Conditions. Please read them carefully before using our services. If you do not agree with any part of these Terms, you should not use our website or services.',
              style: TextStyle(
                  color: blackColor, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20,),
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: const Text(
                '1. General Terms',
                style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                textAlign: TextAlign.left,
              ),
            ),
            const Text(
              'These Terms & Conditions govern your use of our website and services, including ambulance booking and medical appointment scheduling. By using our services, you represent that you are at least 18 years old or have the consent of a legal guardian.',
              style: TextStyle(
                  color: blackColor, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20,),
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: const Text(
                '2. Service Availability',
                style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                textAlign: TextAlign.left,
              ),
            ),
            const Text(
              'We strive to ensure that all services, including ambulance bookings and appointment scheduling, are available 24/7. However, we do not guarantee uninterrupted access and availability of services. We reserve the right to modify or discontinue any services temporarily or permanently without prior notice.',
              style: TextStyle(
                  color: blackColor, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20,),
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: const Text(
                '3. Ambulance Booking',
                style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                textAlign: TextAlign.left,
              ),
            ),
            const Text(
              'Ambulance bookings are subject to availability and location. We do our best to respond promptly to your request, but we cannot guarantee the arrival time of an ambulance due to factors beyond our control, such as traffic or weather conditions. You are responsible for providing accurate information during the booking process. Any false or incomplete information may result in delays or cancellations of the service.',
              style: TextStyle(
                  color: blackColor, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20,),
            Container(
              width: double.infinity,
              alignment: Alignment.centerLeft,
              child: const Text(
                '4. Medical Appointments',
                style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18),
                textAlign: TextAlign.left,
              ),
            ),
            const Text(
              'Our platform allows you to book medical appointments with registered healthcare professionals. However, we are not responsible for the quality of care or services provided by the healthcare professionals you book through our platform.  It is your responsibility to arrive on time for the scheduled appointment. Failure to do so may result in cancellation or rescheduling fees.',
              style: TextStyle(
                  color: blackColor, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.left,
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text('-- End --',
              style: TextStyle(
                color: Colors.black54,
                fontSize: 14,
                fontWeight: FontWeight.bold
              ),),
            ),
            const SizedBox(height: 20)
          ],
        ),
      )),
    );
  }
}
