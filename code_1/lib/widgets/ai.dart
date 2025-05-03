// written by: Casey 
// tested by: Casey 
// debugged by: Casey 


import 'package:flutter/material.dart';

class AIWidget extends StatelessWidget {
  const AIWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Matching AI: How It Works',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(24),
          margin: const EdgeInsets.symmetric(horizontal: 20),
          constraints: const BoxConstraints(maxWidth: 800),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Text(
            'Our AI system helps streamline disaster relief by automatically matching incoming aid requests with the best-fit volunteers—fast, fair, and smart.\n\n'
            'What We Do:\n'
            'We use AI to understand each request and find the right people to help. When someone asks for help, the system looks at key details like:\n'
            '- Type of aid needed (medical, supplies, food, etc.)\n'
            '- Location\n'
            '- Volunteer skills and availability\n\n'
            'How the AI Thinks:\n'
            'We turn real-world info into numbers using:\n'
            '- One-hot encoding for request types and skills\n'
            '- GPS coordinates from addresses\n'
            '- Numeric scores for availability\n\n'
            'Then, our AI uses a method called K-Nearest Neighbors—think of it like finding the closest match in a crowd based on shared traits. It doesn’t require past examples to learn; it just compares and picks the best fit in real-time.\n\n'
            'Behind the Machine:\n'
            '- Every match gets normalized to ensure fairness\n'
            '- A special Debug Mode lets us peek at how decisions are made\n'
            '- It’s flexible—future versions could use smarter algorithms, like neural networks\n\n'
            'Why It Matters:\n'
            'This system makes sure that when someone needs help, the right volunteer is notified as quickly and accurately as possible—turning crowdsourced power into real-time relief.',
            style: const TextStyle(fontSize: 17, height: 1.6),
            textAlign: TextAlign.justify,
          ),
        ),
        const SizedBox(height: 60),
      ],
    );
  }
}
