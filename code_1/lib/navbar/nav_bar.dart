import 'package:flutter/material.dart';
import '../screens/profile_screen.dart'; // Ensure the correct path

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          // Logo aligned to the left
          SizedBox(
            height: 80,
            width: 150,
            child: Image.asset('assets/logo.png'),
          ),

          // Spacer to push sign-in to the right
          const Spacer(),

          // Sign In aligned to the right
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 16,
            children: [
              _NavBarItem(
                title: 'Sign Up/Sign In',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SignUpScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;

  // ignore: unused_element_parameter
  const _NavBarItem({required this.title, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}


