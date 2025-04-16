import 'package:attedance_app/services/check_in_service.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CheckInPage extends StatefulWidget {
  const CheckInPage({super.key});

  @override
  State<CheckInPage> createState() => _CheckInPageState();
}

class _CheckInPageState extends State<CheckInPage> {
  Position? _currentPosition;
  String _currentAddress = 'Loading address...';
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isCheckingIn = false;
  String _checkInTime = '';
  String _userName = 'User';
  String _userAvatar = 'assets/images/avatar.jpeg';
  String? _selectedAttendanceType;
  final TextEditingController _reasonController = TextEditingController();

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
        'Layanan Lokasi Nonaktif',
        'Harap aktifkan layanan lokasi untuk menggunakan fitur ini.',
        openSettings: true,
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _showErrorDialog(
          'Izin Lokasi Ditolak',
          'Izin lokasi diperlukan untuk menggunakan fitur ini.',
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _showErrorDialog(
        'Izin Ditolak Selamanya',
        'Harap aktifkan izin lokasi di pengaturan aplikasi.',
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
            "${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.administrativeArea}, ${placemark.country}";
      });

      _markers.clear();
      _markers.add(
        Marker(
          markerId: const MarkerId('userLocation'),
          position: LatLng(position.latitude, position.longitude),
          infoWindow: InfoWindow(
            title: 'Lokasi Anda',
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
        'Kesalahan Lokasi',
        'Gagal mendapatkan lokasi Anda. Error: $e',
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
                  child: const Text('Pengaturan'),
                ),
              if (openAppSettings)
                TextButton(
                  onPressed: () {
                    Geolocator.openAppSettings();
                    Navigator.pop(context);
                  },
                  child: const Text('Pengaturan Aplikasi'),
                ),
            ],
          ),
    );
  }

  Future<void> _handleCheckIn() async {
    if (_isCheckingIn || _currentPosition == null) return;

    setState(() => _isCheckingIn = true);

    try {
      final response = await CheckInService().checkIn(
        lat: _currentPosition!.latitude,
        lng: _currentPosition!.longitude,
        address: _currentAddress,
      );

      setState(() => _isCheckingIn = false);

      if (response.data != null && response.data!.checkIn != null) {
        final formattedTime = DateFormat(
          'hh:mm a',
        ).format(response.data!.checkIn!);
        setState(() => _checkInTime = formattedTime);

        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Check-In Berhasil'),
                content: Text('Waktu: $formattedTime'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('OK'),
                  ),
                ],
              ),
        );
      } else {
        _showErrorDialog(
          'Sudah Check-In',
          response.message ?? 'Anda sudah check-in hari ini.',
        );
      }
    } catch (e) {
      setState(() => _isCheckingIn = false);
      _showErrorDialog('Gagal Check-In', 'Error: $e');
    }
  }

  void _handleSavePermission() {
    if (_reasonController.text.isEmpty) {
      _showErrorDialog('Alasan Izin Kosong', 'Harap isi alasan izin Anda.');
      return;
    }

    print('Alasan Izin: ${_reasonController.text}');
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Izin Disimpan'),
            content: const Text('Alasan izin Anda telah disimpan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
    );
    _reasonController.clear();
    setState(() => _selectedAttendanceType = null);
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
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.white,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundImage: AssetImage(_userAvatar),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                      DropdownButtonFormField<String>(
                        value: _selectedAttendanceType,
                        onChanged: (String? newValue) {
                          setState(() => _selectedAttendanceType = newValue);
                        },
                        items:
                            ['Masuk', 'Izin'].map<DropdownMenuItem<String>>((
                              String value,
                            ) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kehadiran',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_selectedAttendanceType == 'Izin') ...[
                        TextField(
                          controller: _reasonController,
                          decoration: const InputDecoration(
                            labelText: 'Alasan Izin',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 15),
                        ElevatedButton(
                          onPressed: _handleSavePermission,
                          child: const Text('Simpan Izin'),
                        ),
                      ] else if (_selectedAttendanceType == 'Masuk') ...[
                        GestureDetector(
                          onTap: _isCheckingIn ? null : _handleCheckIn,
                          child: Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isCheckingIn ? Colors.grey : Colors.green,
                            ),
                            child: Center(
                              child:
                                  _isCheckingIn
                                      ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                      : const Text(
                                        'Clock In',
                                        style: TextStyle(
                                          fontSize: 24,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          _checkInTime.isNotEmpty
                              ? 'Checked in at $_checkInTime'
                              : 'Click to Check-In',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
