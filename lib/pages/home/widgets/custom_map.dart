import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class CustomMap extends StatelessWidget {
  final Position position;
  final String address;
  final Function(GoogleMapController) onMapCreated;

  const CustomMap({
    super.key,
    required this.position,
    required this.address,
    required this.onMapCreated,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: GoogleMap(
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 16,
            ),
            markers: {
              Marker(
                markerId: const MarkerId('currentLocation'),
                position: LatLng(position.latitude, position.longitude),
              ),
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(address, overflow: TextOverflow.ellipsis)),
              IconButton(
                icon: const Icon(Icons.star_border),
                onPressed: () {
                  // save favorite location logic
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
