import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:attedance_app/pages/profile/profile_page.dart';
import 'package:attedance_app/pages/home/widgets/check_card.dart';
import 'package:attedance_app/pages/home/widgets/custom_map.dart';
// import 'package:attedance_app/services/profile_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attedance_app/theme/app_colors.dart';
import 'package:attedance_app/pages/history_page.dart';
import 'package:attedance_app/pages/check_in_page.dart';
import 'package:attedance_app/pages/check_out_page.dart';
import 'dart:async';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _userName = 'User';
  final String _userJob = 'Product Manager';
  String _greeting = 'Hello';
  String _currentTime = '';
  String _currentDay = '';
  String _fullAddress = 'Loading...';
  Position? _currentPosition;
  int _selectedIndex = 0;
  late Stream<String> _clockStream;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _getCurrentPosition();
    _startClock();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('userName') ?? 'User';
    setState(() {
      _userName = name;
      _updateGreeting();
    });
  }

  void _updateGreeting() {
    int hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _greeting = 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      _greeting = 'Good Afternoon';
    } else {
      _greeting = 'Good Evening';
    }
  }

  Future<void> _getCurrentPosition() async {
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() => _currentPosition = position);

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final placemark = placemarks.first;

    setState(() {
      _fullAddress =
          "${placemark.name}, ${placemark.street}, ${placemark.subLocality}, ${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}, ${placemark.country}";
    });
  }

  void _startClock() {
    _clockStream = Stream.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      _currentTime = DateFormat('hh:mm:ss a').format(now);
      _currentDay = DateFormat('EEEE, dd MMMM yyyy').format(now);
      return _currentTime;
    });
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Widget page;
    if (index == 1) {
      page = const HistoryPage();
    } else if (index == 2) {
      page = const ProfilePage();
    } else {
      return;
    }

    Navigator.push(context, _createRoute(page));
  }

  Route _createRoute(Widget page) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var begin = 0.0;
        var end = 1.0;
        var tween = Tween(begin: begin, end: end);
        var fadeAnimation = animation.drive(tween);
        return FadeTransition(opacity: fadeAnimation, child: child);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: AppColors.border, blurRadius: 5),
                  ],
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundImage: AssetImage('assets/images/avatar.jpg'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _userName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _userJob,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting 👋',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Hope you have a great day!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              StreamBuilder<String>(
                stream: _clockStream,
                builder: (context, snapshot) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: AppColors.border, blurRadius: 5),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          snapshot.data ?? _currentTime,
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _currentDay,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: CheckCard(
                                title: 'Clock In',
                                time: '',
                                note: 'Start Work',
                                borderColor: AppColors.success,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CheckInPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: CheckCard(
                                title: 'Clock Out',
                                time: '',
                                note: 'End Work',
                                borderColor: AppColors.warning,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const CheckOutPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              _currentPosition == null
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary, width: 2),
                    ),
                    child: CustomMap(
                      position: _currentPosition!,
                      address: _fullAddress,
                      onMapCreated: (controller) {},
                    ),
                  ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
