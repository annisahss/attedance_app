import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attedance_app/theme/app_colors.dart'; // Tambahkan AppColors

class ProfileHeader extends StatelessWidget {
  final String logoPath;
  final String name;
  final String jobTitle;
  final String avatarPath;
  final String time;
  final String date;

  const ProfileHeader({
    super.key,
    required this.logoPath,
    required this.name,
    required this.jobTitle,
    required this.avatarPath,
    required this.time,
    required this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary, // Ganti dari Colors.blue
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Image.asset(logoPath, height: 40)),
          const SizedBox(height: 20),
          Row(
            children: [
              CircleAvatar(backgroundImage: AssetImage(avatarPath), radius: 25),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    jobTitle,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.notifications_none, color: Colors.white),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            time,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(date, style: GoogleFonts.poppins(color: Colors.white)),
        ],
      ),
    );
  }
}
