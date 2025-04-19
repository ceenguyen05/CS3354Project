// UI for user request screen 
// Creates a basics screen and imports the model and service darts for this specific function
// Asks the user for the name, aidtype, and description
// Also has a geo locator to see the users current and direct location 

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../models/request.dart';
import '../services/request_posting_service.dart';

class RequestPostingScreen extends StatefulWidget {
  const RequestPostingScreen({super.key});

  @override
  State<RequestPostingScreen> createState() => _RequestPostingScreenState();
}

class _RequestPostingScreenState extends State<RequestPostingScreen> {
  final _formKey = GlobalKey<FormState>();
  String _aidType = 'Medical';
  String _description = '';
  String _name = '';
  Position? _location;
  bool _locationMissingError = false;
  final List<Request> _submittedRequests = [];

  Future<void> _getLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      await Geolocator.requestPermission();
    }
    final position = await Geolocator.getCurrentPosition();
    setState(() {
      _location = position;
      _locationMissingError = false; // Clear error if location is retrieved
    });
  }

  void _submitRequest() {
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
      );

      submitRequest(request);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request submitted.')),
      );

      setState(() {
        _submittedRequests.add(request);
        _formKey.currentState!.reset();
        _location = null;
        _aidType = 'Medical';
        _description = '';
        _name = '';
        _locationMissingError = false;
      });
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

  @override
  void initState() {
    super.initState();
    fetchCurrentRequests().then((requests) {
      setState(() {
        _submittedRequests.addAll(requests);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Submit Aid Request',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Form Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Your Name'),
                    onSaved: (value) => _name = value ?? '',
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please enter your name' : null,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _aidType,
                    items: ['Medical', 'Food', 'Shelter']
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    onChanged: (value) => setState(() => _aidType = value!),
                    decoration: const InputDecoration(labelText: 'Aid Type'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Description'),
                    onSaved: (value) => _description = value ?? '',
                    validator: (value) =>
                        (value == null || value.isEmpty) ? 'Please enter a description' : null,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _getLocation,
                    child: const Text('Get My Location'),
                  ),
                  if (_location != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Lat: ${_location!.latitude}, Long: ${_location!.longitude}',
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
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _submitRequest,
                    child: const Text('Submit Request'),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Current Requests for Help:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // List of Requests
          Expanded(
            child: _submittedRequests.isEmpty
                ? const Center(child: Text('No current requests for help.'))
                : ListView.builder(
                    itemCount: _submittedRequests.length,
                    itemBuilder: (context, index) {
                      final request = _submittedRequests[index];
                      return ListTile(
                        leading: _getAidIcon(request.type),
                        title: Text('${request.name} - ${request.type}'),
                        subtitle: Text(
                          '${request.description}\nLat: ${request.latitude}, Long: ${request.longitude}',
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
