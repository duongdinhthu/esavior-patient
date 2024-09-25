import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class BookedList extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  const BookedList(
      {super.key,
      required this.isLoggedIn,
      required this.onLogout,
      this.patientId});

  @override
  _BookedListState createState() => _BookedListState();
}

class _BookedListState extends State<BookedList> {
  List<dynamic> bookings = [];
  int currentPage = 0;
  int bookingsPerPage = 5;
  bool isLoading = false;
  List<dynamic> drivers = [];

  @override
  void initState() {
    super.initState();
    fetchDriverData().then((_) {
      fetchPatientData();
    });
  }

  Future<void> fetchPatientData() async {
    final url = Uri.parse(
        'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/bookings/patientId/${widget.patientId}');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var patientData = json.decode(response.body);
        if (patientData.isNotEmpty) {
          setState(() {
            bookings = patientData ?? [];
            bookings.sort((a, b) {
              DateTime dateA = DateTime.parse(a['pickupTime']);
              DateTime dateB = DateTime.parse(b['pickupTime']);
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

  Future<void> fetchDriverData() async {
    setState(() {
      isLoading = true;
    });
    final url = Uri.parse(
        'https://techwiz-b3fsfvavawb9fpg8.japanwest-01.azurewebsites.net/api/drivers/all');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        var driverData = json.decode(response.body);
        if (driverData.isNotEmpty) {
          setState(() {
            drivers = driverData ?? [];
          });
        }
      } else {
        print(
            'Error fetching patient data! Status Code: ${response.statusCode}');
      }
    } catch (error) {
      print('Error: $error');
    }
  }

  String? findDriverName(String driverId) {
    print(drivers);
    if (drivers.isNotEmpty) {
      int? idAsInt = int.tryParse(driverId);
      if (idAsInt != null) {
        for (var driver in drivers) {
          if (driver['driverId'] == idAsInt) {
            return driver['driverName'];
          }
        }
      }
    }
    return null;
  }

  List<dynamic> getPaginatedBookings() {
    int startIndex = currentPage * bookingsPerPage;
    int endIndex =
    (startIndex + bookingsPerPage).clamp(0, bookings.length);
    return bookings.sublist(startIndex, endIndex);
  }

  Widget buildBookings() {
    var paginatedBookings = getPaginatedBookings();

    return ListView.builder(
      itemCount: paginatedBookings.length,
      itemBuilder: (context, index) {
        var booking = paginatedBookings[index];
        DateTime pickupTime = DateTime.parse(booking['pickupTime']);
        String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(pickupTime);
        String driverId = booking['driverId'].toString();
        String driverName = findDriverName(driverId) ?? 'N/A';
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
                        formattedTime,
                        style: const TextStyle(
                            fontSize: 18,
                            color: primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Booking Type: ${booking['bookingType'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Ambulance Type: ${booking['ambulanceType'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Driver: $driverName",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Status: ${booking['bookingStatus'] ?? 'N/A'}",
                        style: const TextStyle(
                            fontSize: 16,
                            color: blackColor,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Price: \$${(booking['cost'] ?? 0.0).toStringAsFixed(2)}",
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
    int totalPages = (bookings.length / bookingsPerPage).ceil();
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
                      'Booked Ambulance',
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
                bookings.isEmpty
                    ? const Expanded(
                    child: Center(
                      child: Text(
                        'No booking history',
                        style: TextStyle(
                            color: blackColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18),
                      ),
                    ))
                    : Expanded(
                  child: buildBookings(),
                ),
                buildPaginationControls(),
              ],
            ),
    );
  }
}
