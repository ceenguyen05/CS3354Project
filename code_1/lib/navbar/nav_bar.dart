import 'package:flutter/material.dart';
import '../screens/profile_screen.dart';

class CustomNavigationBar extends StatelessWidget {
  const CustomNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          final horizontalPadding = isMobile ? 8.0 : 24.0;
          final buttonLabel =
              isMobile ? 'Sign In' : 'Sign Up / Sign In'; // ✅ correct placement

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: 16,
            ),
            child: Row(
              children: [
                // 1) Logo flush left:
                SizedBox(
                  height: isMobile ? 48 : 80,
                  width: isMobile ? 100 : 150,
                  child: Image.asset('assets/logo.png'),
                ),

                // 2) Spacer to push button right
                const Spacer(),

                // 3) Sign-in button
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: _HoverableSignInButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SignUpScreen()),
                      );
                    },
                    label: buttonLabel,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HoverableSignInButton extends StatefulWidget {
  final VoidCallback onTap;
  final String label;

  const _HoverableSignInButton({
    required this.onTap,
    required this.label,
    super.key,
  });

  @override
  State<_HoverableSignInButton> createState() => _HoverableSignInButtonState();
}

class _HoverableSignInButtonState extends State<_HoverableSignInButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = Colors.white;
    final hoverColor = Colors.white;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _isHovered ? hoverColor : baseColor,
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                if (_isHovered)
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
              ],
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person, color: Colors.black),
                const SizedBox(width: 8),
                Text(
                  widget.label, // ✅ must not be const
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    letterSpacing: 1.0,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
