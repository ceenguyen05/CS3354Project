// UI to update resource inventory
// Creates a basics screen and imports the model and service darts for this specific function
// Displays the current resources in your area 
// Will be soon updated for deliverable 2 to display all resources, even resources with 0 in your area 
// Will be able to integrate with updating data after a donation has been made for deliverable 2

import 'package:flutter/material.dart';
import '../models/resource.dart';
// ignore: library_prefixes
import '../services/resource_service.dart' as ResourceService;

class ResourceInventoryScreen extends StatefulWidget {
  const ResourceInventoryScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ResourceInventoryScreenState createState() => _ResourceInventoryScreenState();
}

class _ResourceInventoryScreenState extends State<ResourceInventoryScreen> {
  late Future<List<Resource>> resources;

  @override
  void initState() {
    super.initState();
    resources = ResourceService.fetchResources(); // Fetching resources from local JSON
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Resource Inventory',
          style: TextStyle(
            fontSize: 26, // Larger text size
            fontWeight: FontWeight.bold, // Make the text bold
            color: Colors.black, // Set text color to black
          ),
        ),
      ),
      body: FutureBuilder<List<Resource>>(
        future: resources,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading data.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No resources available.'));
          }

          final resourcesList = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: List.generate(
                  resourcesList.length,
                  (index) {
                    final resource = resourcesList[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFE0F7FA),
                            Color(0xFFB2EBF2),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withValues(),
                            blurRadius: 5,
                            offset: Offset(0, 3),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(12),
                        title: Text(
                          resource.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "${resource.quantity} units",
                              style: const TextStyle(fontSize: 14), // Adjust subtitle text size
                            ),
                            Text(
                              "Location: ${resource.location}",
                              style: const TextStyle(fontSize: 14), // Adjust subtitle text size
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

