import 'package:esavior_project/screens/services_feedback.dart';
import 'package:esavior_project/screens/appointment_list.dart';
import 'package:esavior_project/screens/booked_list.dart';
import 'package:esavior_project/screens/change_password.dart';
import 'package:esavior_project/screens/diagnosis.dart';
import 'package:esavior_project/screens/emergency_booking.dart';
import 'package:esavior_project/screens/medical_records.dart';
import 'package:esavior_project/screens/non-urgent_booking.dart';
import 'package:flutter/material.dart';
import 'package:esavior_project/screens/about.dart';
import 'package:esavior_project/screens/appointment.dart';
import 'package:esavior_project/screens/booking.dart';
import 'package:esavior_project/screens/home.dart';
import 'package:esavior_project/screens/library.dart';
import 'package:esavior_project/screens/login.dart';
import 'package:esavior_project/screens/profile.dart';
import 'package:esavior_project/screens/user.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isLoggedIn = false;
  int? patientId;
  int _selectedIndex = 0;
  bool _showExtraButtons = false;

  void handleLogin(BuildContext context, int patientId) {
    setState(() {
      isLoggedIn = true;
      this.patientId = patientId;
    });
  }

  void handleLogout(BuildContext context) {
    setState(() {
      isLoggedIn = false;
      patientId = null;
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index != 2) {
        _selectedIndex = index;
      } else {
        setState(() {
          _showExtraButtons = !_showExtraButtons;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      routes: {
        '/login': (context) => Login(
              onLogin: (int patientId) => handleLogin(context, patientId),
            ),
        '/user': (context) => User(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
            ),
        '/about': (context) => About(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
            ),
        '/feedback': (context) => ServicesFeedback(
          isLoggedIn: isLoggedIn,
          onLogout: () => handleLogout(context),
          patientId: patientId,
        ),
        '/library': (context) => Library(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
            ),
        '/appointment_list': (context) => AppointmentList(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
            ),
        '/medical_records': (context) => MedicalRecords(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
            ),
        '/booked_list': (context) => BookedList(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
            ),
        '/change_password': (context) => ChangePassword(
              isLoggedIn: isLoggedIn,
              onLogout: () => handleLogout(context),
              patientId: patientId,
            ),
        '/emergency_booking': (context) => EmergencyBooking(),
        '/nonEmergency_booking': (context) => NonEmergencyBooking(),
      },
      title: 'eSavior',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Nunito',
      ),
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: whiteColor,
        body: IndexedStack(
          index: _selectedIndex,
          children: [
            Builder(
              builder: (context) => Home(
                isLoggedIn: isLoggedIn,
                onLogout: () => handleLogout(context),
                patientId: patientId,
                onNavigateToDiagnosis: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ),
            Builder(
              builder: (context) => Diagnosis(
                isLoggedIn: isLoggedIn,
                onLogout: () => handleLogout(context),
                patientId: patientId,
              ),
            ),
            Builder(
              builder: (context) => const Booking(),
            ),
            Builder(
              builder: (context) => Appointment(
                isLoggedIn: isLoggedIn,
                onLogout: () => handleLogout(context),
                patientId: patientId,
                onNavigateToHomePage: () {
                  setState(() {
                    _selectedIndex = 0;
                  });
                },
              ),
            ),
            Builder(
              builder: (context) => Profile(
                isLoggedIn: isLoggedIn,
                onLogout: () => handleLogout(context),
                patientId: patientId,
                onNavigateToDiagnosis: () {
                  setState(() {
                    _selectedIndex = 1;
                  });
                },
              ),
            ),
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: whiteColor,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.medical_services),
              label: 'Diagnosis',
            ),
            BottomNavigationBarItem(
              icon: Icon(
                Icons.car_crash,
                color: whiteColor,
              ),
              label: 'Booking',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month),
              label: 'Medical',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: primaryColor,
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          unselectedItemColor: Colors.black54,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showExtraButtons)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Builder(
                  builder: (BuildContext newContext) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(newContext, '/emergency_booking');
                        setState(() {
                          _showExtraButtons = !_showExtraButtons;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 255, 0, 0),
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 32.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15.0),
                        ),
                      ),
                      child: const Text('Emergency Booking',
                          style: TextStyle(
                              fontSize: 16.0,
                              color: whiteColor,
                              fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            if (_showExtraButtons)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Builder(
                  builder: (BuildContext newContext) {
                    return ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                            newContext, '/nonEmergency_booking');
                        setState(() {
                          _showExtraButtons = !_showExtraButtons;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: whiteColor,
                        padding: const EdgeInsets.symmetric(
                            vertical: 16.0, horizontal: 32.0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            side: const BorderSide(
                                color: const Color.fromARGB(255, 255, 0, 0),
                                width: 0.5)),
                      ),
                      child: const Text('Non-Urgent Booking',
                          style: TextStyle(
                              fontSize: 16.0,
                              color: const Color.fromARGB(255, 255, 0, 0),
                              fontWeight: FontWeight.bold)),
                    );
                  },
                ),
              ),
            FloatingActionButton(
              onPressed: () {
                setState(() {
                  _showExtraButtons = !_showExtraButtons;
                });
              },
              backgroundColor: primaryColor,
              child: Image.network(
                'https://img.icons8.com/ios-filled/50/FFFFFF/ambulance--v1.png',
                width: 35,
                height: 35,
              ),
            ),
            if (_showExtraButtons) const SizedBox(height: 30)
          ],
        ),
      ),
    );
  }
}
