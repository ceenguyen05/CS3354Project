import 'package:flutter/material.dart';

class TeamWidget extends StatelessWidget {
  const TeamWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SizedBox(
        width: 300,
        height: 410,
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start, 
              crossAxisAlignment: CrossAxisAlignment.center,
              children: const [
                Text(
                  'Group 2',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 25),
                ContactItem(
                  label: 'Casey Nguyen',
                  value: 'Frontend / Backend / Management',
                ),
                SizedBox(height: 25),
                ContactItem(
                  label: 'Kevin Pulikkottil',
                  value: 'Backend / AI / Planner',
                ),
                SizedBox(height: 25),
                ContactItem(
                  label: 'Andy Jih',
                  value: 'Frontend',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactItem extends StatelessWidget {
  final String label;
  final String value;

  const ContactItem({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}


