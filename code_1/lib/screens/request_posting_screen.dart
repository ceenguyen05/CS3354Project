// written by: Casey & Andy & Kevin 
// tested by: Casey & Andy & Kevin 
// debugged by: Casey & Kevin 

// UI for user request screen
// Creates a basics screen and imports the model and service darts for this specific function
// Asks the user for the name, aidtype, and description
// Also has a geo locator to see the users current and direct location

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/request.dart';
import '../services/request_posting_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class RequestPostingScreen extends StatefulWidget {
  const RequestPostingScreen({super.key});

  @override
  State<RequestPostingScreen> createState() => _RequestPostingScreenState();
}

class ScalableMarker extends StatefulWidget {
  final VoidCallback onTap;
  const ScalableMarker({super.key, required this.onTap});

  @override
  State<ScalableMarker> createState() => _ScalableMarkerState();
}

class _ScalableMarkerState extends State<ScalableMarker> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _isHovered ? 1.6 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: const Icon(Icons.location_pin, color: Colors.red, size: 30),
        ),
      ),
    );
  }
}

class _RequestPostingScreenState extends State<RequestPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _aidType = 'Medical';
  String _description = '';
  String _name = '';
  Position? _location;
  bool _locationMissingError = false;
  final RequestPostingService _requestService = RequestPostingService();

  Future<void> _getLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    final updatedPermission = await Geolocator.checkPermission();
    if (updatedPermission == LocationPermission.denied || updatedPermission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied.')));
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _location = position;
        _locationMissingError = false;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to get location: $e')));
    }
  }

  void _submitRequest() async {
    setState(() {
      _locationMissingError = _location == null;
    });

    if (_formKey.currentState!.validate() && _location != null) {
      _formKey.currentState!.save();

      final request = Request(
        name: _name,
        type: _aidType,
        description: _description,
        latitude: _location!.latitude,
        longitude: _location!.longitude,
        timestamp: DateTime.now(),
      );

      try {
        await _requestService.submitRequest(request);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Request submitted.')),
          );
        }

        setState(() {
          _formKey.currentState!.reset();
          _location = null;
          _aidType = 'Medical';
          _description = '';
          _name = '';
          _locationMissingError = false;
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to submit request: $e')),
          );
        }
      }
    }
  }

  Icon _getAidIcon(String type) {
    switch (type) {
      case 'Medical':
        return const Icon(Icons.local_hospital, color: Colors.red);
      case 'Food':
        return const Icon(Icons.restaurant, color: Colors.orange);
      case 'Shelter':
        return const Icon(Icons.home, color: Colors.green);
      default:
        return const Icon(Icons.help_outline);
    }
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  ButtonStyle _buttonStyle({bool isWhite = false}) {
    return ElevatedButton.styleFrom(
      backgroundColor: isWhite ? Colors.white : Colors.teal,
      foregroundColor: isWhite ? Colors.black : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Submit Aid Request',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFFFFF),
                Color(0xFFE0F7FA),
                Color(0xFFB2EBF2),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        padding: const EdgeInsets.fromLTRB(16, 75, 16, 16),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFFFF),
              Color(0xFFE0F7FA),
              Color(0xFFB2EBF2),
            ],
          ),
        ),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        decoration: _inputDecoration('Your Name'),
                        onSaved: (value) => _name = value ?? '',
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? 'Please enter your name'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Aid Type",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: ['Medical', 'Food', 'Shelter'].map((type) {
                          final isSelected = _aidType == type;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: ChoiceChip(
                                label: Center(child: Text(type)),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _aidType = type),
                                selectedColor: const Color(0xFFB2EBF2),
                                backgroundColor: Colors.grey.shade200,
                                labelStyle: TextStyle(
                                  color: isSelected ? Colors.black : Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: _inputDecoration('Description'),
                        onSaved: (value) => _description = value ?? '',
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? 'Please enter a description'
                                : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _getLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Get My Location'),
                            style: _buttonStyle(isWhite: true),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: _showMapDialog,
                            icon: const Icon(Icons.map),
                            label: const Text('View Map'),
                            style: _buttonStyle(isWhite: true),
                          ),
                        ],
                      ),
                      if (_location != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Lat: ${_location!.latitude}, Long: ${_location!.longitude}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      if (_locationMissingError)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'Please get your location',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _submitRequest,
                        style: _buttonStyle(isWhite: true),
                        child: const Text('Submit Request'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "\uD83D\uDCCB Current Requests for Help",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 0),
            Expanded(
              child: StreamBuilder<List<Request>>(
                stream: _requestService.watchRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error loading requests: ${snapshot.error}'));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No current requests for help.'));
                  }

                  final submittedRequests = snapshot.data!;

                  return ListView.builder(
                    itemCount: submittedRequests.length,
                    itemBuilder: (context, index) {
                      final request = submittedRequests[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: _getAidIcon(request.type),
                          title: Text(
                            '${request.name} - ${request.type}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${request.description}\nLat: ${request.latitude}, Long: ${request.longitude}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMapDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          width: MediaQuery.of(context).size.width * 0.9,
          child: StreamBuilder<List<Request>>(
            stream: _requestService.watchRequests(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return const Center(child: Text('Could not load map data.'));
              }
              final mapRequests = snapshot.data!;

              return Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: mapRequests.isNotEmpty
                          ? LatLng(
                              mapRequests[0].latitude,
                              mapRequests[0].longitude,
                            )
                          : const LatLng(37.7749, -122.4194),
                      initialZoom: 5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: mapRequests.map((req) {
                          return Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(req.latitude, req.longitude),
                            child: ScalableMarker(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text(
                                      '${req.name} - ${req.type}',
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(req.description),
                                        const SizedBox(height: 8),
                                        Text('📍 Lat: ${req.latitude}'),
                                        Text(
                                          '📍 Long: ${req.longitude}',
                                        ),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text("Close"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
