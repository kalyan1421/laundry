import 'dart:math';

class IdUtils {
  static String generateClientId() {
    Random random = Random();
    // Generate a number between 100000 and 999999
    int randomNumber = 100000 + random.nextInt(900000);
    return randomNumber.toString();
  }

  // For truly unique IDs checked against Firestore (more complex, for future consideration):
  // static Future<String> generateUniqueClientId(FirebaseFirestore firestore) async {
  //   String clientId;
  //   bool isUnique = false;
  //   int maxRetries = 10;
  //   int retries = 0;
  //   do {
  //     clientId = generateClientId();
  //     final doc = await firestore.collection('users').where('clientId', isEqualTo: clientId).limit(1).get();
  //     if (doc.docs.isEmpty) {
  //       isUnique = true;
  //     } else {
  //       retries++;
  //     }
  //   } while (!isUnique && retries < maxRetries);

  //   if (!isUnique) {
  //     // Fallback or error handling if a unique ID can't be generated after several retries
  //     // This could involve a more complex generation or a sequential ID system as a last resort.
  //     throw Exception('Failed to generate a unique Client ID after $maxRetries retries.');
  //   }
  //   return clientId;
  // }
} 