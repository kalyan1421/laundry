// Test file to verify address parsing
import 'lib/models/address_model.dart';

void main() {
  // Test with your Firebase data structure
  final testData = {
    'addressLine1': 'Door: 411-1, Floor: 3rd floor, Madhapur, 308',
    'addressLine2': '',
    'city': 'Hyderabad',
    'fullAddress': 'Door: 411-1, Floor: 3rd floor, Madhapur, 308, Hyderabad, Telangana, 500081',
    'isPrimary': true,
    'landmark': '',
    'latitude': 17.4463967,
    'longitude': 78.38655,
    'pincode': '500081',
    'searchableText': 'door: 411-1, floor: 3rd floor, madhapur, 308 hyderabad telangana 500081',
    'state': 'Telangana',
    'type': 'home',
  };

  // Parse the address
  final address = AddressModel.fromFirestore(testData, 'test_id');

  print('Parsed Address:');
  print('Door Number: "${address.doorNumber}"');
  print('Floor Number: "${address.floorNumber}"');
  print('Address Line 1: "${address.addressLine1}"');
  print('City: "${address.city}"');
  print('State: "${address.state}"');
  print('Pincode: "${address.pincode}"');
  print('Type: "${address.type}"');
  print('Is Primary: ${address.isPrimary}');
  print('Full Address: "${address.fullAddress}"');
  
  // Test toMap() to ensure it saves correctly
  final mapData = address.toMap();
  print('\nSaved to Firebase:');
  print('addressLine1: "${mapData['addressLine1']}"');
}
