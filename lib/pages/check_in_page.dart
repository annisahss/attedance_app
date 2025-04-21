import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:attedance_app/services/check_in_service.dart';
import 'package:attedance_app/theme/app_colors.dart';
import 'package:attedance_app/pages/home/home_page.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  Position? _currentPosition;
  String _currentAddress = 'Loading address...';
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isCheckingIn = false;
  String _checkInTime = '';
  String _userName = 'User';
  String _userAvatar = 'assets/images/avatar.jpeg';
  String? _selectedAttendanceType;
  final TextEditingController _reasonController = TextEditingController();

  final double _allowedDistance = 40;
  final double _officeLat = -6.210881;
  final double _officeLng = 106.812942;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _getCurrentLocation();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'User';
      _userAvatar = prefs.getString('userAvatar') ?? 'assets/images/avatar.jpg';
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog(
        'Location Service Disabled',
        'Please enable location service.',
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog(
          'Permission Denied',
          'Location permission is required.',
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog(
        'Permission Permanently Denied',
        'Please enable it from settings.',
      );
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      if (!mounted) return;

      setState(() => _currentPosition = position);

      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      final placemark = placemarks.first;

      setState(() {
        _currentAddress =
            "${placemark.street}, ${placemark.subLocality}, "
            "${placemark.locality}, ${placemark.administrativeArea} ${placemark.postalCode}, "
            "${placemark.country}";
      });

      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('userLocation'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(
            title: 'Your Location',
            snippet: _currentAddress,
          ),
        ),
      );

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          15,
        ),
      );
    } catch (e) {
      _showErrorDialog('Location Error', e.toString());
    }
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckingIn || _currentPosition == null) return;

    double distance = Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      _officeLat,
      _officeLng,
    );

    if (distance > _allowedDistance) {
      _showErrorDialog(
        'Too Far',
        'You are more than 40 meters away from the allowed location.',
      );
      return;
    }

    setState(() => _isCheckingIn = true);

    try {
      final response = await CheckInService().checkIn(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        address: _currentAddress,
        status: _selectedAttendanceType == 'Leave' ? 'izin' : 'masuk',
        alasanIzin:
            _reasonController.text.isNotEmpty ? _reasonController.text : null,
      );

      setState(() => _isCheckingIn = false);

      final now = DateTime.now();
      final formattedTime = DateFormat('hh:mm:ss a').format(now);
      setState(() => _checkInTime = formattedTime);

      if (!mounted) return;
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('Check-In Successful'),
              content: Text('Time: $formattedTime'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
      );
    } catch (e) {
      setState(() => _isCheckingIn = false);
      _showErrorDialog('Check-In Failed', e.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child:
                    _currentPosition != null
                        ? GoogleMap(
                          onMapCreated:
                              (controller) => _mapController = controller,
                          initialCameraPosition: CameraPosition(
                            target: LatLng(
                              _currentPosition!.latitude,
                              _currentPosition!.longitude,
                            ),
                            zoom: 15,
                          ),
                          markers: _markers,
                        )
                        : const Center(child: CircularProgressIndicator()),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundImage: AssetImage(_userAvatar),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _userName,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  _currentAddress,
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value:
                            [
                                  'Attendance',
                                  'Leave',
                                ].contains(_selectedAttendanceType)
                                ? _selectedAttendanceType
                                : null,
                        hint: const Text('Select Attendance Type'),
                        onChanged: (String? newValue) {
                          setState(() => _selectedAttendanceType = newValue);
                        },
                        items:
                            ['Attendance', 'Leave']
                                .map(
                                  (value) => DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  ),
                                )
                                .toList(),
                        decoration: const InputDecoration(
                          labelText: 'Attendance Type',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_selectedAttendanceType == 'Leave')
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Reason for Permission',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                      const SizedBox(height: 20),
                      Center(
                        child: GestureDetector(
                          onTap: _isCheckingIn ? null : _handleCheckIn,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _isCheckingIn
                                      ? Colors.grey
                                      : AppColors.success,
                            ),
                            child: Center(
                              child:
                                  _isCheckingIn
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        _selectedAttendanceType == 'Leave'
                                            ? 'Submit Leave'
                                            : 'Clock In',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_checkInTime.isNotEmpty)
                        Center(
                          child: Text(
                            'Clocked in at $_checkInTime',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 40,
            left: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppColors.primary,
                ),
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomePage()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
