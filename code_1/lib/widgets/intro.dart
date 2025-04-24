import 'package:flutter/material.dart';

class Intro extends StatelessWidget {
  const Intro({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double titleFontSize = isMobile ? 30 : 60;
    final double bodyFontSize = isMobile ? 16 : 21;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              Text(
                'Crowdsourced Disaster Relief System',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: titleFontSize,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'The purpose of our platform is to give users a chance to help out the community and to get help themselves. '
                'Our website offers key features like seeing the current resources in your area, making a request on any kind of '
                'situation like medical, shelter or food supplies. It also has a donation system where users can donate either money or '
                'resources that would help out many people in need. There is also an emergency alerts page where users can see what is '
                'happening and when they are happening so they stay alert and safe.',
                style: TextStyle(fontSize: bodyFontSize, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
