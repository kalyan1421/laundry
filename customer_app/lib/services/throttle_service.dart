import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:customer_app/core/constants/app_constants.dart';

class ThrottleService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'otp_throttle';

  /// Check if a phone number is rate-limited on the server side
  static Future<ThrottleResult> checkThrottle(String phoneNumber) async {
    try {
      print('🔒 Checking server-side throttle for: $phoneNumber');
      
      final docRef = _firestore.collection(_collection).doc(phoneNumber);
      final doc = await docRef.get();

      if (!doc.exists) {
        print('🔒 No throttle record found. Phone number is allowed.');
        return ThrottleResult(isAllowed: true);
      }

      final data = doc.data()!;
      final lastRequestTime = (data['lastRequestTime'] as Timestamp).toDate();
      final attemptCount = data['attemptCount'] as int? ?? 0;
      final isBlocked = data['isBlocked'] as bool? ?? false;
      final blockUntil = data['blockUntil'] != null 
          ? (data['blockUntil'] as Timestamp).toDate()
          : null;

      final now = DateTime.now();

      // Check if currently blocked
      if (isBlocked && blockUntil != null && now.isBefore(blockUntil)) {
        final remainingTime = blockUntil.difference(now);
        print('🔒 ❌ Phone number is blocked until: $blockUntil');
        return ThrottleResult(
          isAllowed: false,
          reason: 'Blocked due to excessive requests',
          remainingSeconds: remainingTime.inSeconds,
          isBlocked: true,
        );
      }

      // Check normal cooldown
      final timeSinceLastRequest = now.difference(lastRequestTime);
      if (timeSinceLastRequest < AppConstants.otpCooldownDuration) {
        final remainingTime = AppConstants.otpCooldownDuration - timeSinceLastRequest;
        print('🔒 ⏱️ Phone number in cooldown. Remaining: ${remainingTime.inSeconds}s');
        return ThrottleResult(
          isAllowed: false,
          reason: 'Please wait before requesting another OTP',
          remainingSeconds: remainingTime.inSeconds,
        );
      }

      // Check if too many attempts in a short period
      if (attemptCount >= AppConstants.maxOtpRetries) {
        final hoursSinceLastRequest = timeSinceLastRequest.inHours;
        if (hoursSinceLastRequest < 1) { // Block for excessive attempts within an hour
          final blockUntil = now.add(const Duration(hours: 2));
          await _blockPhoneNumber(phoneNumber, blockUntil, 'Excessive attempts');
          print('🔒 🚫 Blocking phone number due to excessive attempts: $phoneNumber');
          return ThrottleResult(
            isAllowed: false,
            reason: 'Too many attempts. Blocked for 2 hours.',
            remainingSeconds: 7200, // 2 hours
            isBlocked: true,
          );
        }
      }

      print('🔒 ✅ Phone number is allowed to request OTP');
      return ThrottleResult(isAllowed: true);

    } catch (e) {
      print('🔒 ❌ Error checking throttle: $e');
      // In case of error, allow the request (fail-open)
      return ThrottleResult(isAllowed: true);
    }
  }

  /// Record an OTP request attempt
  static Future<void> recordAttempt(String phoneNumber, {bool isSuccessful = false}) async {
    try {
      print('🔒 Recording OTP attempt for: $phoneNumber (successful: $isSuccessful)');
      
      final docRef = _firestore.collection(_collection).doc(phoneNumber);
      final now = DateTime.now();

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(docRef);
        
        if (!doc.exists) {
          // First attempt
          transaction.set(docRef, {
            'phoneNumber': phoneNumber,
            'lastRequestTime': Timestamp.fromDate(now),
            'attemptCount': 1,
            'successfulAttempts': isSuccessful ? 1 : 0,
            'isBlocked': false,
            'createdAt': Timestamp.fromDate(now),
            'updatedAt': Timestamp.fromDate(now),
          });
        } else {
          // Update existing record
          final data = doc.data()!;
          final lastRequestTime = (data['lastRequestTime'] as Timestamp).toDate();
          final attemptCount = data['attemptCount'] as int? ?? 0;
          final successfulAttempts = data['successfulAttempts'] as int? ?? 0;

          // Reset count if last request was more than 1 hour ago
          final timeSinceLastRequest = now.difference(lastRequestTime);
          final newAttemptCount = timeSinceLastRequest.inHours >= 1 ? 1 : attemptCount + 1;

          transaction.update(docRef, {
            'lastRequestTime': Timestamp.fromDate(now),
            'attemptCount': newAttemptCount,
            'successfulAttempts': isSuccessful ? successfulAttempts + 1 : successfulAttempts,
            'updatedAt': Timestamp.fromDate(now),
          });
        }
      });

      print('🔒 ✅ OTP attempt recorded successfully');

    } catch (e) {
      print('🔒 ❌ Error recording attempt: $e');
      // Don't throw error to avoid breaking the OTP flow
    }
  }

  /// Block a phone number for a specific duration
  static Future<void> _blockPhoneNumber(String phoneNumber, DateTime blockUntil, String reason) async {
    try {
      final docRef = _firestore.collection(_collection).doc(phoneNumber);
      
      await docRef.update({
        'isBlocked': true,
        'blockUntil': Timestamp.fromDate(blockUntil),
        'blockReason': reason,
        'blockedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('🔒 🚫 Phone number blocked: $phoneNumber until $blockUntil');

    } catch (e) {
      print('🔒 ❌ Error blocking phone number: $e');
    }
  }

  /// Manually unblock a phone number (for admin use)
  static Future<void> unblockPhoneNumber(String phoneNumber) async {
    try {
      final docRef = _firestore.collection(_collection).doc(phoneNumber);
      
      await docRef.update({
        'isBlocked': false,
        'blockUntil': FieldValue.delete(),
        'blockReason': FieldValue.delete(),
        'unblockedAt': Timestamp.fromDate(DateTime.now()),
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });

      print('🔒 ✅ Phone number unblocked: $phoneNumber');

    } catch (e) {
      print('🔒 ❌ Error unblocking phone number: $e');
      rethrow;
    }
  }

  /// Get throttle status for a phone number
  static Future<Map<String, dynamic>?> getThrottleStatus(String phoneNumber) async {
    try {
      final doc = await _firestore.collection(_collection).doc(phoneNumber).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      print('🔒 ❌ Error getting throttle status: $e');
      return null;
    }
  }

  /// Clean up old throttle records (call periodically)
  static Future<void> cleanupOldRecords() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      final query = _firestore
          .collection(_collection)
          .where('updatedAt', isLessThan: Timestamp.fromDate(cutoffDate));

      final snapshot = await query.get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }

      print('🔒 🧹 Cleaned up ${snapshot.docs.length} old throttle records');

    } catch (e) {
      print('🔒 ❌ Error cleaning up records: $e');
    }
  }
}

/// Result of throttle check
class ThrottleResult {
  final bool isAllowed;
  final String? reason;
  final int? remainingSeconds;
  final bool isBlocked;

  ThrottleResult({
    required this.isAllowed,
    this.reason,
    this.remainingSeconds,
    this.isBlocked = false,
  });

  @override
  String toString() {
    return 'ThrottleResult(isAllowed: $isAllowed, reason: $reason, remainingSeconds: $remainingSeconds, isBlocked: $isBlocked)';
  }
} 