import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CheckCard extends StatelessWidget {
  final String title;
  final String time;
  final String note;
  final Color borderColor;
  final VoidCallback onTap;

  const CheckCard({
    super.key,
    required this.title,
    required this.time,
    required this.note,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: borderColor),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(time, style: GoogleFonts.poppins(fontSize: 16)),
            Text(
              note,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: borderColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
