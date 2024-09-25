import 'package:flutter/material.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class CarDetailPage2 extends StatelessWidget {
  final String carName;

  const CarDetailPage2({
    super.key,
    required this.carName, // Nhận tên xe từ Library
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor, // Nền trắng
      appBar: AppBar(
        title: Text(carName), // Hiển thị tên xe
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            const CarImageSection(
              imageUrl:
              'https://www.medcurehealthcare.in/wp-content/uploads/2023/04/icu-ambulance-berhampur.png',
              description:
              'This ambulance is equipped with advanced life support systems, enabling paramedics to provide critical care during transport.',
            ),
            const SizedBox(height: 40),
            const CarImageSection(
              imageUrl:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcREfoI10NPr1XmfB9kUtWz-gw-J2iFSG_wYb7imI7ZdiDXDcq1XzAhWPodhYqTxShEZgr0&usqp=CAU',
              description:
              'The spacious interior is designed for easy access to medical equipment and a comfortable space for patients.',
            ),
            const SizedBox(height: 40),
            const CarImageSection(
              imageUrl:
              'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRyVSG8DMMSu12dnPtdrxaOjooQ8S578sa6qlQeU6_Hpz5qJy5lVokKM6VXDrPMxcxSA7U&usqp=CAU',
              description:
              'With sirens and flashing lights, this ambulance ensures quick navigation through traffic to reach emergency situations promptly.',
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Rating',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const StarRating(rating: 5),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class CarImageSection extends StatelessWidget {
  final String imageUrl;
  final String description;

  const CarImageSection({
    Key? key,
    required this.imageUrl,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Image.network(imageUrl, height: 200, fit: BoxFit.cover),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            description,
            style: const TextStyle(fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ),
        const Divider(),
      ],
    );
  }
}

class StarRating extends StatelessWidget {
  final int rating;

  const StarRating({Key? key, required this.rating}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return Icon(
          index < rating ? Icons.star : Icons.star_border,
          color: Colors.amber,
        );
      }),
    );
  }
}
