import 'package:flutter/material.dart';

class AddAddressScreen extends StatelessWidget {
  const AddAddressScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Address'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TODO: Implement address input fields (Address Line 1, Line 2, City, State, Pincode, Landmark, Type)
            const Text('Address Line 1'),
            TextFormField(),
            const SizedBox(height: 16),
            const Text('Address Line 2 (Optional)'),
            TextFormField(),
            const SizedBox(height: 16),
            const Text('City'),
            TextFormField(),
            const SizedBox(height: 16),
            const Text('State'),
            TextFormField(),
            const SizedBox(height: 16),
            const Text('Pincode'),
            TextFormField(),
            const SizedBox(height: 16),
            const Text('Landmark (Optional)'),
            TextFormField(),
            const SizedBox(height: 16),
            // TODO: Implement address type selection (Home, Work, Other)
            const Text('Address Type'),
            // Example: DropdownButton or Radio buttons
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement save address logic
                // Validate fields
                // Save to Firestore under the current user's 'addresses' subcollection
                // Example: FirebaseFirestore.instance.collection('users').doc(userId).collection('addresses').add({...});
                // After successful save, pop with true
                // Navigator.pop(context, true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Save address functionality not yet implemented.')),
                );
              },
              child: const Text('Save Address'),
            ),
          ],
        ),
      ),
    );
  }
}
