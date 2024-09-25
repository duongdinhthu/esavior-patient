import 'dart:async';
import 'package:flutter/material.dart';
import 'car-detail-page1.dart';
import 'car-detail-page2.dart';
const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class Library extends StatefulWidget {
  final bool isLoggedIn;
  final Function onLogout;
  final int? patientId;

  const Library({super.key, required this.isLoggedIn, required this.onLogout, this.patientId});

  @override
  _LibraryState createState() => _LibraryState();
}

class _LibraryState extends State<Library> {
  late PageController _pageController;
  late Timer _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: 0,
      viewportFraction: 0.5, // Hiển thị 3 hình ảnh cùng lúc
    );

    _timer = Timer.periodic(const Duration(seconds: 2), (Timer timer) {
      if (_currentPage < 5) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      _pageController.animateToPage(
        _currentPage,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
      );
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Car Library'),
        backgroundColor: primaryColor,
      ),
      body: Column(
        children: [
          // Hình ảnh Banner
          Container(

            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://d1csarkz8obe9u.cloudfront.net/posterpreviews/ambulance-design-template-8be4adcb2056b245d56de89f4b048651_screen.jpg?ts=1626691752',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 70),

          // Hai Hình Ảnh Chính theo hàng dọc
          Expanded(
            child: ListView(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
                  child: Text(
                    'Car Models',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarDetailPage1(
                              carName: 'Standard Car',
                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Image.network(
                            'https://5.imimg.com/data5/NX/WT/ZM/SELLER-23155962/force-traveller-ambulance-c-type-fully-factory-build-ambulance-bs-6-500x500.jpg',
                            height: 150,
                            width: 150,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Standard Car',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CarDetailPage2(
                              carName: 'Advanced Car',

                            ),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Image.network(
                            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQB_SARQC7hNCLkR6VJBlpIA0zqAdrkWTg_2rRjNNSKsQANBRv5SISGix84feWrVFh0XC8&usqp=CAU',
                            height: 150,
                            width: 150,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(height: 0),
                          const Text(
                            'Advanced Car',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Slide hiển thị 6 ô tô
                Container(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    itemCount: 6,
                    itemBuilder: (context, index) {
                      return _buildCarSlide([
                        'https://img.icons8.com/?size=64&id=TnjRejE27WgH&format=png',
                        'https://img.icons8.com/?size=64&id=1Qevb0eIteXH&format=png',
                        'https://img.icons8.com/?size=64&id=dxAzyOWEmbjn&format=png',
                        'https://img.icons8.com/?size=64&id=K8FaLWoSTedo&format=png',
                        'https://img.icons8.com/?size=64&id=zXJJ6FNgWQZe&format=png',
                        'https://img.icons8.com/?size=64&id=qgEuQeTzbSBI&format=png'
                      ][index]);
                    },
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }

  Widget _buildCarSlide(String imageUrl) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.network(
          imageUrl,
          height: 150,
          width: 150,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
