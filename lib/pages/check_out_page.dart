import 'package:attedance_app/services/check_out_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckOutPage extends StatefulWidget {
  const CheckOutPage({Key? key}) : super(key: key);

  @override
  _CheckOutPageState createState() => _CheckOutPageState();
}

class _CheckOutPageState extends State<CheckOutPage> {
  Position? _currentPosition;
  String _currentAddress = 'Loading address...';
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isCheckingOut = false;
  bool _hasCheckedOut = false;
  String _checkOutTime = '';
  String _userName = 'User';
  String _userAvatar = 'assets/images/avatar.jpeg';

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
      _userAvatar =
          prefs.getString('userAvatar') ?? 'assets/images/avatar.jpeg';
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorDialog(
        'Location Services Disabled',
        'Please enable location services to use this feature.',
        openSettings: true,
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog(
          'Location Permission Denied',
          'Location permission is required to use this feature.',
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog(
        'Permission Denied Forever',
        'Please enable location permission in app settings.',
        openAppSettings: true,
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
            "${placemark.street}, ${placemark.locality}, ${placemark.country}";
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
          15.0,
        ),
      );
    } catch (e) {
      _showErrorDialog(
        'Location Error',
        'Failed to get your location. Error: $e',
      );
    }
  }

  void _showErrorDialog(
    String title,
    String message, {
    bool openSettings = false,
    bool openAppSettings = false,
  }) {
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
              if (openSettings)
                TextButton(
                  onPressed: () {
                    Geolocator.openLocationSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Settings'),
                ),
              if (openAppSettings)
                TextButton(
                  onPressed: () {
                    Geolocator.openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('App Settings'),
                ),
            ],
          ),
    );
  }

  Future<void> _handleCheckOut() async {
    if (_isCheckingOut || _currentPosition == null || _hasCheckedOut) return;

    setState(() => _isCheckingOut = true);

    try {
      final service = CheckOutService();
      final response = await service.checkOut(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        location: 'Current Location',
        address: _currentAddress,
      );

      setState(() => _isCheckingOut = false);

      if (response != null && response.message != null) {
        if (response.message!.toLowerCase().contains("sudah checkout")) {
          _showErrorDialog(
            'Check-Out Gagal',
            'Kamu sudah melakukan check-out sebelumnya.',
          );
          setState(() => _hasCheckedOut = true);
          return;
        }

        final checkOutTime = response.data?.checkOut;
        if (checkOutTime != null) {
          final formattedTime = DateFormat('hh:mm a').format(checkOutTime);
          setState(() {
            _checkOutTime = formattedTime;
            _hasCheckedOut = true;
          });

          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: const Text('Check-Out Berhasil'),
                  content: Text('Kamu check-out pada pukul $formattedTime'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
          );
        }
      } else {
        _showErrorDialog('Gagal', 'Respon tidak valid.');
      }
    } catch (e) {
      setState(() => _isCheckingOut = false);
      _showErrorDialog('Error', 'Terjadi kesalahan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.6,
                child:
                    _currentPosition != null
                        ? GoogleMap(
                          onMapCreated: (controller) {
                            _mapController = controller;
                          },
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
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 35,
                                backgroundImage: AssetImage(_userAvatar),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.2),
                                        spreadRadius: 2,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        _currentAddress,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),

                        GestureDetector(
                          onTap:
                              (_isCheckingOut || _hasCheckedOut)
                                  ? null
                                  : _handleCheckOut,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color:
                                  _isCheckingOut || _hasCheckedOut
                                      ? Colors.grey
                                      : Colors.blue,
                            ),
                            child: Center(
                              child:
                                  _isCheckingOut
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : Text(
                                        _hasCheckedOut
                                            ? 'Checked Out'
                                            : 'Check Out',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _hasCheckedOut
                              ? 'Checked out at $_checkOutTime'
                              : 'Tekan tombol untuk Check Out',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
