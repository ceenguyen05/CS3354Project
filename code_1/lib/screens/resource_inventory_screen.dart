import 'package:flutter/material.dart';
import '../models/resource.dart';
// Keep the prefix if you prefer, or remove it and use ResourceService directly
import '../services/resource_service.dart' as ResourceServicePrefix; // Renamed prefix for clarity

class ResourceInventoryScreen extends StatefulWidget {
  const ResourceInventoryScreen({super.key});

  @override
  _ResourceInventoryScreenState createState() => _ResourceInventoryScreenState();
}

class _ResourceInventoryScreenState extends State<ResourceInventoryScreen> {
  late Future<List<Resource>> resourcesFuture; // Rename to avoid conflict with variable name
  bool _showLowInventoryOnly = false;
  String? _sortOption;
  final TextEditingController _searchController = TextEditingController();
  String _searchTerm = '';

  // Instantiate the service
  final ResourceServicePrefix.ResourceService _resourceService = ResourceServicePrefix.ResourceService();

  final LinearGradient gradient = const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFE0F7FA),
      Color(0xFFB2EBF2),
    ],
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Call the load method using the service instance
    _loadResources();
  }

  // Helper function to load/reload resources using the service instance
  void _loadResources() {
     setState(() {
       // Use the instance and the correct method name
       resourcesFuture = _resourceService.fetchResources();
     });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text(
            'Resource Inventory',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        floatingActionButton: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(30),
          ),
          child: FloatingActionButton.extended(
            onPressed: _showAddResourceDialog,
            icon: const Icon(Icons.add),
            label: const Text("Add Resource"),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
        // Use the renamed future variable here
        body: FutureBuilder<List<Resource>>(
          future: resourcesFuture, // Use the Future variable
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return const Center(child: Text('Error loading data.'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text('No resources available.'));
            }

            List<Resource> filtered = [];
            if (snapshot.hasData) {
                 filtered = _showLowInventoryOnly
                    ? snapshot.data!.where((r) => r.quantity <= 50).toList()
                    : List.from(snapshot.data!);

                if (_sortOption == 'City') {
                  filtered.sort((a, b) => a.location.compareTo(b.location));
                } else if (_sortOption == 'Quantity') {
                  filtered.sort((a, b) => a.quantity.compareTo(b.quantity));
                }

                if (_searchTerm.isNotEmpty) {
                  filtered = filtered
                      .where((r) =>
                          r.name.toLowerCase().contains(_searchTerm) ||
                          r.location.toLowerCase().contains(_searchTerm))
                      .toList();
                }
            }
            // ... Rest of build method using 'filtered' list ...
             return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchTerm = val.toLowerCase()),
                        decoration: InputDecoration(
                          hintText: 'Search by name or location...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Wrap(
                            spacing: 8,
                            children: ['All', 'Low Only'].map((label) {
                              final selected = (_showLowInventoryOnly &&
                                      label == 'Low Only') ||
                                  (!_showLowInventoryOnly && label == 'All');
                              return _buildChoiceChip(
                                label,
                                selected,
                                () => setState(() {
                                  _showLowInventoryOnly =
                                      label == 'Low Only' ? !_showLowInventoryOnly : false;
                                }),
                              );
                            }).toList(),
                          ),
                          Row(
                            children: [
                              const Text(
                                'Sort by:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Wrap(
                                spacing: 8,
                                children: ['City', 'Quantity'].map((option) {
                                  final selected = _sortOption == option;
                                  return _buildChoiceChip(
                                    option,
                                    selected,
                                    () => setState(() {
                                      _sortOption =
                                          selected ? null : option;
                                    }),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final resource = filtered[index];
                      IconData icon;
                      Color iconColor;

                      switch (resource.name.toLowerCase()) {
                        case 'blankets':
                          icon = Icons.bed;
                          iconColor = Colors.deepPurple;
                          break;
                        case 'water bottles':
                          icon = Icons.local_drink;
                          iconColor = Colors.blueAccent;
                          break;
                        case 'first aid kits':
                          icon = Icons.medical_services;
                          iconColor = Colors.redAccent;
                          break;
                        case 'canned food':
                          icon = Icons.fastfood;
                          iconColor = Colors.orange;
                          break;
                        case 'med units':
                          icon = Icons.health_and_safety;
                          iconColor = Colors.green;
                          break;
                        case 'gas (gallons)':
                          icon = Icons.local_gas_station;
                          iconColor = Colors.grey;
                          break;
                        default:
                          icon = Icons.inventory_2;
                          iconColor = Colors.teal;
                      }

                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            // ignore: deprecated_member_use
                            backgroundColor: iconColor.withOpacity(0.1),
                            child: Icon(icon, color: iconColor),
                          ),
                          title: Text(
                            resource.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              "${resource.quantity} units available\n📍 ${resource.location}",
                              style: const TextStyle(fontSize: 14, height: 1.4),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildChoiceChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: selected ? gradient : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black26),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  void _showAddResourceDialog() {
    String name = '';
    // String location = ''; // Removed unused variable
    int quantity = 0;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Resource'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: 'Resource Name'),
                  onChanged: (val) => name = val,
                ),
                // TextField( // Remove location field as backend doesn't use it for POST
                //   decoration: const InputDecoration(labelText: 'Location (City, ST)'),
                //   onChanged: (val) => location = val,
                // ),
                TextField(
                  decoration: const InputDecoration(labelText: 'Quantity'),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => quantity = int.tryParse(val) ?? 0,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async { // Make async
                // Use the variables or controller.text
                if (name.isNotEmpty && quantity > 0 /* && location.isNotEmpty - removed location check */) {
                  // Show loading indicator if desired
                  // setState(() => _isLoading = true);
                  try {
                    // Call the service to add the resource
                    // We are not collecting description/category in the dialog currently
                    // Pass null or default values if needed by the service method signature
                    // Pass null for location as it's not collected and backend doesn't expect it on POST
                    await _resourceService.addResource(name, quantity, null, null /*, location - not sent */);

                    // If successful, close dialog and refresh list
                    Navigator.of(context).pop();
                    _loadResources(); // Refresh the resource list
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Resource added successfully!')),
                     );
                  } catch (e) {
                     // Show error message
                     Navigator.of(context).pop(); // Close dialog even on error
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Failed to add resource: ${e.toString().replaceFirst("Exception: ","")}')),
                     );
                  } finally {
                     // Hide loading indicator
                     // if (mounted) setState(() => _isLoading = false);
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    // Updated error message as location is not required by backend
                    const SnackBar(content: Text('Please enter a name and quantity.')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
