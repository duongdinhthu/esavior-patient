import 'package:flutter/material.dart';

const primaryColor = Color.fromARGB(255, 200, 50, 0);
const whiteColor = Color.fromARGB(255, 255, 255, 255);
const blackColor = Color.fromARGB(255, 0, 0, 0);
const blueColor = Color.fromARGB(255, 33, 150, 233);

class CarDetailPage1 extends StatelessWidget {
  final String carName;

  const CarDetailPage1({super.key, required this.carName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: whiteColor, // Đặt nền của toàn bộ trang là màu trắng
      appBar: AppBar(
        title: Text(carName),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),
            CarImageSection(
              imageUrl: 'https://s.alicdn.com/@sc04/kf/HTB1oIQAbBCw3KVjSZFlq6AJkFXaM.jpg_300x300.jpg',
              description:
              'This ambulance is equipped with advanced life support systems, enabling paramedics to provide critical care during transport.',
            ),
            const SizedBox(height: 40),
            CarImageSection(
              imageUrl: 'https://img.medicalexpo.com/images_me/photo-m2/74996-17439830.jpg',
              description:
              'The spacious interior is designed for easy access to medical equipment and a comfortable space for patients.',
            ),
            const SizedBox(height: 40),
            CarImageSection(
              imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTXA1GM-27jGGrqZAlZkZX-h8eFXERzmLRTUMjhn1pMlvXKV2MkYT8uNTlPCYPbamCHjOI&usqp=CAU',
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold,color:primaryColor,),
                  ),
                  const SizedBox(height: 10),
                  StarRating(rating: 5),
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
            style: TextStyle(fontSize: 16),
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
