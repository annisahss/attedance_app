// lib/pages/home/home_page.dart
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import './widgets/check_card.dart';
import './widgets/custom_map.dart';
import './widgets/profile_header.dart';
import '../check_in_page.dart';
import '../check_out_page.dart';
import '../report_page.dart';
import './profile/profile_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Position? _currentPosition;
  String _currentAddress = 'Loading address...';
  late GoogleMapController _mapController;
  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() => _currentPosition = position);

    final placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    final placemark = placemarks.first;
    setState(() {
      _currentAddress =
          "${placemark.street}, ${placemark.locality}, ${placemark.country}";
    });
  }

  void _onTabTapped(int index) {
    setState(() {
      currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ReportPage()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfilePage()),
      );
    }
    // index 0 is Home, stay on page
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Top Profile Section
            ProfileHeader(
              logoPath: 'assets/images/logo_company.png',
              name: 'Hi, John',
              jobTitle: 'Product Manager',
              avatarPath: 'assets/images/avatar.jpeg',
              time:
                  '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} AM',
              date: '${now.month}/${now.day}/${now.year}',
            ),
            const SizedBox(height: 15),

            // Google Map Section
            if (_currentPosition != null)
              CustomMap(
                position: _currentPosition!,
                address: _currentAddress,
                onMapCreated: (controller) => _mapController = controller,
              ),

            // Check In/Out Grid
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 10,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CheckCard(
                    title: "Check In",
                    time: "09:00 am",
                    note: "on time",
                    borderColor: Colors.blue,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckInPage(),
                          ),
                        ),
                  ),
                  CheckCard(
                    title: "Check Out",
                    time: "05:00 pm",
                    note: "go home",
                    borderColor: Colors.green,
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckOutPage(),
                          ),
                        ),
                  ),
                ],
              ),
            ),

            // Activity Section
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [Text("Your Activity"), Text("View All")],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    icon: const Icon(Icons.ads_click),
                    label: const Text("Check In"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment),
            label: "Report",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
