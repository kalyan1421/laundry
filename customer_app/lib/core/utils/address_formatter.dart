import 'package:cloud_firestore/cloud_firestore.dart';

class AddressFormatter {
  /// Formats address data in the requested layout:
  /// Door: ...
  /// Floor: ...
  /// Full Address: ...
  static String formatAddressLayout(Map<String, dynamic> data) {
    List<String> addressLines = [];
    
    // Door section
    if (data['doorNumber'] != null && data['doorNumber'].toString().trim().isNotEmpty) {
      addressLines.add('Door: ${data['doorNumber'].toString().trim()}');
    } else if (data['flatNo'] != null && data['flatNo'].toString().trim().isNotEmpty) {
      addressLines.add('Door: ${data['flatNo'].toString().trim()}');
    } else if (data['door'] != null && data['door'].toString().trim().isNotEmpty) {
      addressLines.add('Door: ${data['door'].toString().trim()}');
    }
    
    // Floor section
    if (data['floorNumber'] != null && data['floorNumber'].toString().trim().isNotEmpty) {
      addressLines.add('Floor: ${data['floorNumber'].toString().trim()}');
    } else if (data['floor'] != null && data['floor'].toString().trim().isNotEmpty) {
      addressLines.add('Floor: ${data['floor'].toString().trim()}');
    }
    
    // Full Address section
    List<String> fullAddressParts = [];
    
    // Building/Apartment name
    if (data['apartmentName'] != null && data['apartmentName'].toString().trim().isNotEmpty) {
      fullAddressParts.add(data['apartmentName'].toString().trim());
    } else if (data['buildingName'] != null && data['buildingName'].toString().trim().isNotEmpty) {
      fullAddressParts.add(data['buildingName'].toString().trim());
    }
    
    // Street/Area
    if (data['addressLine1'] != null && data['addressLine1'].toString().trim().isNotEmpty) {
      String line1 = data['addressLine1'].toString().trim();
      // Remove door/floor info if it's already extracted above
      if (!line1.toLowerCase().contains('door:') && !line1.toLowerCase().contains('floor:')) {
        fullAddressParts.add(line1);
      }
    }
    
    if (data['addressLine2'] != null && data['addressLine2'].toString().trim().isNotEmpty) {
      String line2 = data['addressLine2'].toString().trim();
      // Remove door/floor info if it's already extracted above
      if (!line2.toLowerCase().contains('door:') && !line2.toLowerCase().contains('floor:')) {
        fullAddressParts.add(line2);
      }
    }
    
    // Street
    if (data['street'] != null && data['street'].toString().trim().isNotEmpty) {
      fullAddressParts.add(data['street'].toString().trim());
    }
    
    // Landmark
    if (data['landmark'] != null && data['landmark'].toString().trim().isNotEmpty) {
      fullAddressParts.add('Near ${data['landmark'].toString().trim()}');
    }
    
    // City, State, Pincode
    String location = '';
    if (data['city'] != null && data['city'].toString().trim().isNotEmpty) {
      location += data['city'].toString().trim();
    }
    if (data['state'] != null && data['state'].toString().trim().isNotEmpty) {
      if (location.isNotEmpty) location += ', ';
      location += data['state'].toString().trim();
    }
    if (data['pincode'] != null && data['pincode'].toString().trim().isNotEmpty) {
      if (location.isNotEmpty) location += ' - ';
      location += data['pincode'].toString().trim();
    }
    if (location.isNotEmpty) {
      fullAddressParts.add(location);
    }
    
    // Add full address section if we have any parts
    if (fullAddressParts.isNotEmpty) {
      addressLines.add('Full Address: ${fullAddressParts.join(', ')}');
    }
    
    return addressLines.join('\n');
  }
  
  /// Formats address from Firestore document snapshot
  static String formatFromFirestore(DocumentSnapshot doc) {
    if (!doc.exists) return 'Address not found';
    
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return 'Invalid address data';
    
    return formatAddressLayout(data);
  }
  
  /// Legacy format for backward compatibility (simple comma-separated)
  static String formatSimple(Map<String, dynamic> data) {
    List<String> addressParts = [];
    
    // Door and floor
    String doorFloor = '';
    if (data['doorNumber'] != null && data['doorNumber'].toString().trim().isNotEmpty) {
      doorFloor += data['doorNumber'].toString().trim();
    }
    if (data['floorNumber'] != null && data['floorNumber'].toString().trim().isNotEmpty) {
      if (doorFloor.isNotEmpty) doorFloor += ', ';
      doorFloor += '${data['floorNumber'].toString().trim()} Floor';
    }
    if (doorFloor.isNotEmpty) {
      addressParts.add(doorFloor);
    }
    
    // Building/Apartment
    if (data['apartmentName'] != null && data['apartmentName'].toString().trim().isNotEmpty) {
      addressParts.add(data['apartmentName'].toString().trim());
    }
    
    // Address lines
    if (data['addressLine1'] != null && data['addressLine1'].toString().trim().isNotEmpty) {
      addressParts.add(data['addressLine1'].toString().trim());
    }
    if (data['addressLine2'] != null && data['addressLine2'].toString().trim().isNotEmpty) {
      addressParts.add(data['addressLine2'].toString().trim());
    }
    
    // Landmark
    if (data['landmark'] != null && data['landmark'].toString().trim().isNotEmpty) {
      addressParts.add('Near ${data['landmark'].toString().trim()}');
    }
    
    // City, State, Pincode
    String location = '';
    if (data['city'] != null && data['city'].toString().trim().isNotEmpty) {
      location += data['city'].toString().trim();
    }
    if (data['state'] != null && data['state'].toString().trim().isNotEmpty) {
      if (location.isNotEmpty) location += ', ';
      location += data['state'].toString().trim();
    }
    if (data['pincode'] != null && data['pincode'].toString().trim().isNotEmpty) {
      if (location.isNotEmpty) location += ' - ';
      location += data['pincode'].toString().trim();
    }
    if (location.isNotEmpty) {
      addressParts.add(location);
    }
    
    return addressParts.join(', ');
  }
} 