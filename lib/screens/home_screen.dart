import 'package:flutter/material.dart';
import '/services/location_service.dart';
import '/services/checkin_service.dart';
import 'history_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

class Fair {
  final String fairName;
  final String location;
  final double lat;
  final double lng;
  final double radius;
  final int points;

  const Fair({
    required this.fairName,
    required this.location,
    required this.lat,
    required this.lng,
    required this.radius,
    required this.points,
  });
}

const List<Fair> fairs = [
  Fair(fairName: "Career Fair", location: "Southern University College",lat: 1.5336, lng: 103.6819, radius: 80, points: 10),
  Fair(fairName: "Fun Fair", location: "Taman Ehsan Jaya", lat: 1.546749, lng: 103.812008, radius: 80, points: 10),
  Fair(fairName: "Midnight Fair", location: "Sutera Mall", lat: 1.4920, lng: 103.7415, radius: 80, points: 10),
];

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.title});
  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double? userLat;
  double? userLng;
  String address = "Getting location...";
  Fair? nearbyFair;
  bool isAtFair = false;
  int totalPoints = 0;

  final MapController _mapController = MapController();
  bool isFollowingUser = true;

  // 🔥 Dev fake GPS
  LatLng? fakeLocation;

  @override
  void initState() {
    super.initState();
    _startLiveLocation();
  }

  void _startLiveLocation() {
    final locationService = LocationService();

    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((position) async {

      double lat = fakeLocation?.latitude ?? position.latitude;
      double lng = fakeLocation?.longitude ?? position.longitude;

      final addr = await locationService.getAddressFromCoordinates(position);

      Fair? foundFair;

      for (var fair in fairs) {
        final distance = locationService.calculateDistance(
          lat,
          lng,
          fair.lat,
          fair.lng,
        );

        if (distance <= fair.radius) {
          foundFair = fair;
          break;
        }
      }

      setState(() {
        userLat = lat;
        userLng = lng;
        address = addr;
        nearbyFair = foundFair;
        isAtFair = foundFair != null;
      });

      if (isFollowingUser) {
        _mapController.move(LatLng(lat, lng), 17);
      }
    });
  }

  void _goToMyLocation() {
    if (userLat != null && userLng != null) {
      _mapController.move(LatLng(userLat!, userLng!), 17);
      setState(() {
        isFollowingUser = true;
      });
    }
  }

  Future<void> joinFair() async {
    if (!isAtFair || nearbyFair == null) return;

   await CheckInService.addCheckIn(
  nearbyFair!.fairName,
  nearbyFair!.location,
  nearbyFair!.points,
);

    setState(() {
      totalPoints += nearbyFair!.points;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Joined Fair Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (userLat == null || userLng == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: _goToMyLocation,
        child: const Icon(Icons.my_location),
      ),

      body: Column(
        children: [

          // 🗺️ 地图（不会再爆）
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(userLat!, userLng!),
                initialZoom: 15,
                onPositionChanged: (position, hasGesture) {
                  if (hasGesture) {
                    isFollowingUser = false;
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(userLat!, userLng!),
                      child: const Icon(Icons.person, size: 50, color: Colors.red),
                    ),

                    // ✅ 保留 fair markers
                    ...fairs.map((fair) => Marker(
                          point: LatLng(fair.lat, fair.lng),
                          child: const Icon(Icons.location_on, size: 40, color: Colors.blue),
                        )),
                  ],
                ),
              ],
            ),
          ),

          // 📋 UI（可滚动，不会爆）
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [

                Card(
  margin: const EdgeInsets.all(16),
  elevation: 10,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
  ),
  child: Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Text(
          "Fair Information",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        // 📍 Address（GPS）
        Row(
          children: [
            const Icon(Icons.my_location, color: Colors.blue),
            const SizedBox(width: 8),
            Expanded(child: Text(address)),
          ],
        ),

        const SizedBox(height: 12),

        // 🎪 Fair Name
        Row(
          children: [
            const Icon(Icons.celebration, color: Colors.purple),
            const SizedBox(width: 8),
            Text(
              nearbyFair?.fairName ?? "No Fair Nearby",
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // 📌 Location（你新增的🔥）
        Row(
          children: [
            const Icon(Icons.location_city, color: Colors.teal),
            const SizedBox(width: 8),
            Text(
              nearbyFair?.location ?? "-",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // ⭐ Points
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.orange),
              const SizedBox(width: 8),
              Text(
                nearbyFair != null
                    ? "+${nearbyFair!.points} Points"
                    : "0 Points",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 🧾 Status
        Row(
          children: [
            Icon(
              isAtFair ? Icons.check_circle : Icons.cancel,
              color: isAtFair ? Colors.green : Colors.red,
            ),
            const SizedBox(width: 8),
            Text(
              isAtFair
                  ? "Eligible to Join"
                  : "Not Eligible",
              style: TextStyle(
                color: isAtFair ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 🔴 AT FAIR Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isAtFair
                  ? [Colors.green, Colors.lightGreen]
                  : [Colors.red, Colors.orange],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              isAtFair ? "AT FAIR" : "NOT AT FAIR",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    ),
  ),
),

  Padding(
  padding: const EdgeInsets.symmetric(horizontal: 20),
  child: SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: (isAtFair && nearbyFair != null)
          ? joinFair
          : null,
      style: ButtonStyle(
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(vertical: 16),
        ),

        backgroundColor:
            MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.pressed)) {
            return Colors.green.shade900;
          }
          if (!isAtFair) return Colors.grey;
          return Colors.green;
        }),

        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
      child: const Text(
        "Join Fair",
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  ),
),

const SizedBox(height: 20),

Text("Total Points: $totalPoints"),

const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}