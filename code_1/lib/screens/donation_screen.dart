// UI for donation screen
// Creates a basics screen and imports the model and service darts for this specific function
// Asks the user for its name, type of donation, and description of the donation

// donation_screen.dart
import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/donation_service.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<Donation> _donations = []; // Keep this one
  final TextEditingController _detailController = TextEditingController(); // Keep this one

  String _name = '';
  String _type = 'Money'; // Default type
  String _detail = '';
  bool _isLoading = false; // Add loading state variable
  final DonationService _donationService = DonationService(); // Add service instance

  final List<Color> gradientColors = const [
    Color(0xFFFFFFFF),
    Color(0xFFE0F7FA),
    Color(0xFFB2EBF2),
  ];

  @override
  void initState() {
    super.initState();
    _loadDonations(); // Load existing donations on init
    _detailController.text = '\$'; // Initialize for 'Money' type
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  // Load donations using the service
  void _loadDonations() async {
    setState(() { // Start loading
      _isLoading = true;
    });
    try {
      final donations = await _donationService.fetchDonations();
      if (mounted) { // Check if widget is still mounted before calling setState
        setState(() {
          _donations.clear(); // Clear existing before adding new
          _donations.addAll(donations);
          _isLoading = false; // Stop loading
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() { // Stop loading on error
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load donations: $e')));
      }
    }
  }

  void _submitDonation() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isSubmitting = true); // Use separate state
      try {
        final newDonation = Donation(
          name: _name,
          type: _type,
          detail: _detail,
        );
        await _donationService.createDonation(newDonation);
        _formKey.currentState!.reset(); // Reset form after successful submission
        _detailController.clear(); // Clear detail controller
        _loadDonations(); // This already handles setting isLoading = false

        if (mounted) { // Check if widget is still in the tree
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Donation added successfully!')));
        }
      } catch (e) {
         setState(() { // Stop loading on error
           _isSubmitting = false;
         });
         if (mounted) { // Check if widget is still in the tree
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Failed to add donation: $e')));
         }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  void _handleTypeChange(String newType) {
    setState(() {
      _type = newType;
      if (_type == 'Money') {
        if (!_detailController.text.startsWith('\$')) {
          _detailController.text = '\$';
        }
      } else {
        _detailController.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: const Text(
          'Make a Donation',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading // Show loading indicator covering the whole body if loading donations
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView( // Keep the scroll view for the whole screen
        padding: const EdgeInsets.all(16.0),
        child: Column( // Main column for the screen content
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16),
                // Use the SINGLE form key here
                child: Form(
                  key: _formKey,
                  // REMOVE the inner Form widget if it exists here
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: "Your Name",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? "Enter your name"
                                    : null,
                        onSaved: (value) => _name = value!,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        "Donation Type",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            ['Money', 'Resource'].map((type) {
                              final isSelected = _type == type;
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                  ),
                                  child: ChoiceChip(
                                    label: Center(child: Text(type)),
                                    selected: isSelected,
                                    onSelected:
                                        (_) => _handleTypeChange(type),
                                    selectedColor: const Color(0xFFB2EBF2),
                                    backgroundColor: Colors.grey.shade200,
                                    labelStyle: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.black
                                              : Colors.black,
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
                        controller: _detailController,
                        decoration: InputDecoration(
                          labelText: "Amount / Description",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Enter a description";
                          }
                          if (_type == 'Money') {
                            final numPart = value.replaceAll(
                              RegExp(r'[^\d.]'),
                              '',
                            );
                            if (numPart.isEmpty) {
                              return "Please enter a valid amount";
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          // Use a different loading indicator state if needed for submission vs initial load
                          onPressed: _isSubmitting ? null : _submitDonation, // Use a separate state like _isSubmitting
                          child: _isSubmitting // Use separate state
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Submit Donation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 28,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
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
                "Previous Donations:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            _donations.isEmpty
                ? const Center(child: Padding( // Add padding for visual spacing
                    padding: EdgeInsets.symmetric(vertical: 20.0),
                    child: Text("No donations yet."),
                  ))
                : ListView.builder(
                    // Add shrinkWrap and physics for ListView inside SingleChildScrollView
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 10),
                    itemCount: _donations.length,
                    itemBuilder: (context, index) {
                      final d = _donations[index];
                      Icon icon;
                      if (d.type == 'Money') {
                        icon = const Icon(
                          Icons.attach_money,
                          color: Colors.green,
                        );
                      } else {
                        icon = const Icon(
                          Icons.inventory,
                          color: Colors.amber,
                        );
                      }
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: icon,
                          title: Text(
                            "${d.name} donated ${d.detail}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(d.type),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  // Add a state variable for submission loading indicator
  bool _isSubmitting = false;
}