// written by: Casey & Andy & Kevin 
// tested by: Casey & Andy & Kevin 
// debugged by: Casey & Kevin 


// UI for donation screen
// Creates a basics screen and imports the model and service darts for this specific function
// Asks the user for its name, type of donation, and description of the donation

// ignore_for_file: use_build_context_synchronously

// donation_screen.dart
import 'package:flutter/material.dart';
import '../models/donation.dart';
import '../services/donation_service.dart'; // Use the service
import 'package:url_launcher/url_launcher.dart';

class DonationScreen extends StatefulWidget {
  const DonationScreen({super.key});

  @override
  State<DonationScreen> createState() => _DonationScreenState();
}

class _DonationScreenState extends State<DonationScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _detailController = TextEditingController();
  final DonationService _donationService = DonationService(); // Instantiate service

  String _name = '';
  String _type = 'Money';
  String _detail = '';

  final List<Color> gradientColors = const [
    Color(0xFFFFFFFF),
    Color(0xFFE0F7FA),
    Color(0xFFB2EBF2),
  ];

  @override
  void initState() {
    super.initState();
    _detailController.text = '\$';
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
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
                            onPressed: () async { // Make async
                              if (_formKey.currentState!.validate()) {
                                _formKey.currentState!.save();
                                _detail = _detailController.text;

                                if (_type == 'Money') {
                                  final stripeUrl = Uri.parse(
                                    'https://buy.stripe.com/test_6oE6p01Rvedi8rmaEE',
                                  );
                                  try {
                                     await launchUrl(
                                       stripeUrl,
                                       mode: LaunchMode.externalApplication,
                                     );
                                  } catch(e) {
                                     if (mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(content: Text('Could not launch Stripe: $e')),
                                     );
                                     }
                                  }
                                } else {
                                  final newDonation = Donation(
                                    name: _name,
                                    type: _type,
                                    detail: _detail,
                                    timestamp: DateTime.now(), // Add timestamp
                                  );

                                  try {
                                    await _donationService.addDonation(newDonation);

                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Thanks $_name for donating $_detail ($_type)',
                                          ),
                                        ),
                                      );
                                      _formKey.currentState!.reset();
                                      _handleTypeChange('Money'); // Reset type and detail field
                                    }
                                  } catch (e) {
                                     if (mounted) {
                                       ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Failed to submit donation: $e')),
                                      );
                                    }
                                  }
                                }
                              }
                            },
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
                            child: const Text("Donate"),
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
              Expanded(
                child: StreamBuilder<List<Donation>>(
                  stream: _donationService.watchDonations(), // Watch service stream
                  builder: (context, snapshot) {
                     if (snapshot.connectionState == ConnectionState.waiting) {
                       return const Center(child: CircularProgressIndicator());
                     }
                     if (snapshot.hasError) {
                       return Center(child: Text('Error loading donations: ${snapshot.error}'));
                     }
                     if (!snapshot.hasData || snapshot.data!.isEmpty) {
                       return const Center(child: Text("No donations yet."));
                     }

                     final donations = snapshot.data!; // Use data from stream

                     return ListView.builder(
                       padding: const EdgeInsets.only(top: 10),
                       itemCount: donations.length,
                       itemBuilder: (context, index) {
                         final d = donations[index];
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
                     );
                  }
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}