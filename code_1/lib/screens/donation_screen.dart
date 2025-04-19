// UI for donation screen
// Creates a basics screen and imports the model and service darts for this specific function
// Asks the user for its name, type of donation, and description of the donation 

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
  final List<Donation> _donations = [];
  final TextEditingController _detailController = TextEditingController();

  String _name = '';
  String _type = 'Money';
  String _detail = '';

  @override
  void initState() {
    super.initState();
    _loadDonations();
    _detailController.text = '\$';
  }

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _loadDonations() async {
    final donations = await fetchDonations();
    setState(() {
      _donations.addAll(donations);
    });
  }

  void _submitDonation() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      _detail = _detailController.text;

      final newDonation = Donation(name: _name, type: _type, detail: _detail);

      setState(() {
        _donations.add(newDonation);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Thanks $_name for donating $_detail ($_type)'),
        ),
      );

      _formKey.currentState!.reset();
      _type = 'Money';
      _detailController.text = '\$';
    }
  }

  void _handleTypeChange(String? newType) {
    if (newType == null) return;
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

  Icon _getDonationIcon(String type) {
    return Icon(
      type == 'Money' ? Icons.attach_money : Icons.inventory,
      color: type == 'Money' ? Colors.green : Colors.orangeAccent,
    );
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

  ButtonStyle _buttonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
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
          'Make a Donation',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: _inputDecoration('Your Name'),
                      onSaved: (value) => _name = value ?? '',
                      validator: (value) => (value == null || value.isEmpty)
                          ? 'Please enter your name'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _type,
                      items: ['Money', 'Resources']
                          .map(
                            (type) => DropdownMenuItem(
                              value: type,
                              child: Text(type),
                            ),
                          )
                          .toList(),
                      onChanged: _handleTypeChange,
                      decoration: _inputDecoration('Donation Type'),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _detailController,
                      decoration: _inputDecoration('Donation Detail'),
                      onSaved: (value) => _detail = value ?? '',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please provide detail for your donation';
                        }

                        // If type is Money, validate that it starts with "$" and has a number after it.
                        if (_type == 'Money') {
                          final regex = RegExp(r'^\$\d+(\.\d{1,2})?$'); // Match "$123" or "$123.45"
                          if (!regex.hasMatch(value)) {
                            return 'Please enter a valid amount';
                          }
                        }

                        return null; // No errors
                      },
                    ),
                    const SizedBox(height: 35),
                    ElevatedButton(
                      onPressed: _submitDonation,
                      style: _buttonStyle(),
                      child: const Text('Submit Donation'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Divider(),
              const Padding(
                padding: EdgeInsets.only(top: 8.0, bottom: 4),
                child: Text(
                  "Previous Donations:",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _donations.isEmpty
                    ? const Center(child: Text('No donations yet.'))
                    : ListView.builder(
                        itemCount: _donations.length,
                        itemBuilder: (context, index) {
                          final donation = _donations[index];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 3,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            child: ListTile(
                              leading: _getDonationIcon(donation.type),
                              title: Text(
                                '${donation.name} - ${donation.type}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(donation.detail),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
