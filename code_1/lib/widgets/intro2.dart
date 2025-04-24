import 'package:flutter/material.dart';

class Intro2 extends StatelessWidget {
  const Intro2({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final double titleFontSize = isMobile ? 28 : 60;
    final double bodyFontSize = isMobile ? 15 : 21;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Align(
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 600,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 70),
              Text(
                'Why Does It Matter?',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: titleFontSize,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                'Disasters strike unpredictably, and not everyone has the means or access to proper aid. '
                'Our platform bridges that gap by empowering everyday individuals to contribute directly to disaster relief efforts. '
                'By crowdsourcing help and resources, we increase the reach and speed of aid, ensuring more people are cared for when they need it most.',
                style: TextStyle(fontSize: bodyFontSize, height: 1.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
