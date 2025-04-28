// UI for user request screen
// Creates a basics screen and imports the model and service darts for this specific function
// Asks the user for the name, aidtype, and description
// Also has a geo locator to see the users current and direct location

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/request.dart';
// Remove the unused import warning by using the service
import '../services/request_posting_service.dart'; // Import the service
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
// Import your ScalableMarker if it's defined elsewhere or keep its definition here
// import '../widgets/scalable_marker.dart';

// Keep ScalableMarker definition if it's here
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

class RequestPostingScreen extends StatefulWidget {
  const RequestPostingScreen({super.key});

  @override
  State<RequestPostingScreen> createState() => _RequestPostingScreenState();
}

class _RequestPostingScreenState extends State<RequestPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  // Instantiate the service
  final RequestPostingService _requestService = RequestPostingService();
  final MapController _mapController = MapController();

  // Form fields state (keep existing)
  String _name = ''; // Used for 'Your Name' field in the original UI
  String _aidType = 'Medical';
  String _description = '';
  Position? _location;
  bool _locationMissingError = false;
  bool _isLoading = false; // Add loading state

  // State for displaying requests on map
  late Future<List<Request>> _requestsFuture; // Use FutureBuilder

  Future<void> _getLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _location = position;
      _locationMissingError = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRequestsForMap(); // Load initial requests for the map
    _getLocation(); // Attempt to get location on init
  }

  // Load requests to display on the map
  void _loadRequestsForMap() {
    setState(() {
      // Call the service method
      _requestsFuture = _requestService.fetchCurrentRequests();
    });
  }

  // Submit request via service
  Future<void> _submitRequest() async { // Make async
    setState(() {
      _locationMissingError = _location == null;
    });

    // Keep validation logic
    if (!_formKey.currentState!.validate() || _location == null) {
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true); // Show loading indicator

    // Create Request object - Use _name for the 'name' field as per model/UI
    final newRequest = Request(
      name: _name, // Use the variable linked to 'Your Name' field
      type: _aidType,
      description: _description,
      latitude: _location!.latitude,
      longitude: _location!.longitude,
    );

    try {
      // Call the service method
      await _requestService.submitRequest(newRequest);

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted successfully!')));

      // Reset form and reload map markers
      setState(() {
        _formKey.currentState!.reset();
        _location = null;
        _aidType = 'Medical';
        _description = '';
        _name = ''; // Reset name field variable
        _locationMissingError = false;
        _loadRequestsForMap(); // Refresh map markers
      });
    } catch (e) {
      print("Error submitting request: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request: ${e.toString().replaceFirst("Exception: ","")}')));
    } finally {
      if (mounted) setState(() => _isLoading = false); // Hide loading indicator
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
    // Keep existing Scaffold and background gradient
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
        child: Column( // Keep Column structure
          children: [
            Card( // Form Card
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
                      TextFormField( // Your Name field
                        decoration: _inputDecoration('Your Name'), // Keep existing decoration
                        onSaved: (value) => _name = value ?? '', // Save to _name variable
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
                      TextFormField( // Description field
                        decoration: _inputDecoration('Description'), // Keep existing decoration
                        onSaved: (value) => _description = value ?? '', // Save to _description
                        validator: (value) =>
                            (value == null || value.isEmpty)
                                ? 'Please enter a description'
                                : null,
                        maxLines: 3,
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
                      // Show loading indicator or button
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _submitRequest, // Call the updated method
                              style: _buttonStyle(isWhite: true), // Keep existing style
                              child: const Text('Submit Request'),
                            ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Align( // "Current Requests" title
              alignment: Alignment.centerLeft,
              child: Text(
                "\uD83D\uDCCB Current Requests for Help",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 0),
            Expanded( // Map or List View
              // Wrap the existing ListView.builder with a FutureBuilder
              child: FutureBuilder<List<Request>>(
                future: _requestsFuture, // Use the future from the service
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    print("Error loading map markers: ${snapshot.error}");
                    return Center(child: Text('Error loading requests: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No current requests found.'));
                  }

                  // Use snapshot.data! which is the List<Request> from the backend
                  final requestsToShow = snapshot.data!;

                  // Keep the existing Map View logic, but use requestsToShow
                  return FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(31.9686, -99.9018), // Center of Texas approx.
                      initialZoom: 5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app', // Replace if needed
                      ),
                      MarkerLayer(
                        // Map the requests from the future snapshot
                        markers: requestsToShow.map((req) {
                          return Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(req.latitude, req.longitude),
                            child: ScalableMarker( // Keep using ScalableMarker
                              onTap: () {
                                // Keep existing showDialog logic
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: Text('${req.name} - ${req.type}'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(req.description),
                                        const SizedBox(height: 8),
                                        Text('📍 Lat: ${req.latitude.toStringAsFixed(4)}'),
                                        Text('📍 Long: ${req.longitude.toStringAsFixed(4)}'),
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(),
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
      builder: (context) => Dialog( // Changed builder context variable name
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          width: MediaQuery.of(context).size.width * 0.9,
          // Use FutureBuilder inside the dialog to load requests
          child: FutureBuilder<List<Request>>(
            future: _requestsFuture, // Reuse the same future
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading map: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('No requests to display.'));
              }

              final requestsToShowInDialog = snapshot.data!;

              return Stack(
                children: [
                  FlutterMap(
                    options: MapOptions(
                      initialCenter: requestsToShowInDialog.isNotEmpty
                          ? LatLng(
                              requestsToShowInDialog[0].latitude,
                              requestsToShowInDialog[0].longitude,
                            )
                          : LatLng(31.9686, -99.9018), // Default center
                      initialZoom: 5,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.app',
                      ),
                      MarkerLayer(
                        markers: requestsToShowInDialog.map((req) { // Use requestsToShowInDialog
                          return Marker(
                            width: 40,
                            height: 40,
                            point: LatLng(req.latitude, req.longitude),
                            child: ScalableMarker(
                              onTap: () {
                                // Close the map dialog first before showing details
                                // Navigator.of(context).pop(); // Optional: close map dialog
                                showDialog(
                                  context: context, // Use the builder context
                                  builder: (_) => AlertDialog( // Use different context variable
                                    title: Text('${req.name} - ${req.type}'),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(req.description),
                                        const SizedBox(height: 8),
                                        Text('📍 Lat: ${req.latitude.toStringAsFixed(4)}'), // Use toStringAsFixed
                                        Text('📍 Long: ${req.longitude.toStringAsFixed(4)}'), // Use toStringAsFixed
                                      ],
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(), // Use the builder context to pop
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
                  // Add a close button to the map dialog
                  Positioned(
                    top: 10,
                    right: 10,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: () => Navigator.of(context).pop(), // Close the dialog
                      child: const Icon(Icons.close),
                    ),
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
