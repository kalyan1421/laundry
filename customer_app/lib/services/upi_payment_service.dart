import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:upi_pay/upi_pay.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:logger/logger.dart';
import '../data/models/transaction_model.dart';

/// Comprehensive UPI Payment Service for handling all payment operations
class UpiPaymentService {
  static final UpiPaymentService _instance = UpiPaymentService._internal();
  factory UpiPaymentService() => _instance;
  UpiPaymentService._internal();

  final Logger _logger = Logger();
  Database? _database;
  final UpiPay _upiPay = UpiPay();

  // Business configuration - Update these with your actual details
  static const String _merchantId = 'CLOUDIRONING001';
  static const String _merchantName = 'Cloud Ironing Factory';
  static const String _merchantUpiId = '7396674546-3@ybl'; // Replace with actual UPI ID
  static const String _merchantPhone = '9063290012'; // Replace with actual phone
  static const String _transactionNote = 'Payment for laundry services';

  /// Initialize the payment service
  Future<void> initialize() async {
    try {
      await _initializeDatabase();
      _logger.i('UPI Payment Service initialized successfully');
    } catch (e) {
      _logger.e('Failed to initialize UPI Payment Service: $e');
      rethrow;
    }
  }

  /// Initialize local database for transaction storage
  Future<void> _initializeDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'upi_transactions.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE transactions (
            id TEXT PRIMARY KEY,
            order_id TEXT NOT NULL,
            customer_id TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT NOT NULL,
            upi_id TEXT NOT NULL,
            payer_name TEXT NOT NULL,
            payee_vpa TEXT NOT NULL,
            status TEXT NOT NULL,
            transaction_ref_id TEXT,
            response_code TEXT,
            error_message TEXT,
            upi_app TEXT,
            created_at TEXT NOT NULL,
            completed_at TEXT,
            metadata TEXT
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_transactions_order_id ON transactions(order_id);
        ''');

        await db.execute('''
          CREATE INDEX idx_transactions_customer_id ON transactions(customer_id);
        ''');

        await db.execute('''
          CREATE INDEX idx_transactions_status ON transactions(status);
        ''');
      },
    );
  }

  /// Get all available UPI apps on the device
  Future<List<ApplicationMeta>> getAvailableUpiApps() async {
    try {
      final apps = await _upiPay.getInstalledUpiApplications();
      _logger.i('Found ${apps.length} UPI apps');
      return apps;
    } catch (e) {
      _logger.e('Error getting UPI apps: $e');
      return [];
    }
  }

  /// Generate unique transaction ID
  String _generateTransactionId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random().nextInt(9999);
    final combined = '$_merchantId$timestamp$random';
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16).toUpperCase();
  }

  /// Validate UPI ID format
  bool isValidUpiId(String upiId) {
    final upiRegex = RegExp(r'^[a-zA-Z0-9.-]{2,256}@[a-zA-Z]{2,64}$');
    return upiRegex.hasMatch(upiId);
  }

  /// Validate payment amount
  bool isValidAmount(double amount) {
    return amount > 0 && amount <= 100000; // Max ₹1,00,000
  }

  /// Create a new transaction record
  Future<TransactionModel> createTransaction({
    required String orderId,
    required String customerId,
    required double amount,
    required String description,
    required String upiId,
    required String payerName,
    Map<String, dynamic>? metadata,
  }) async {
    if (!isValidAmount(amount)) {
      throw Exception('Invalid amount: ₹$amount');
    }

    if (!isValidUpiId(upiId)) {
      throw Exception('Invalid UPI ID format');
    }

    final transaction = TransactionModel(
      id: _generateTransactionId(),
      orderId: orderId,
      customerId: customerId,
      amount: amount,
      description: description,
      upiId: upiId,
      payerName: payerName,
      payeeVpa: _merchantUpiId,
      status: TransactionStatus.pending,
      createdAt: DateTime.now(),
      metadata: metadata,
    );

    await _saveTransaction(transaction);
    _logger.i('Created transaction: ${transaction.id}');
    return transaction;
  }

  /// Initiate UPI payment
  Future<UpiTransactionResponse> initiatePayment({
    required TransactionModel transaction,
    required ApplicationMeta appMeta,
  }) async {
    try {
      _logger.i('Initiating payment for transaction: ${transaction.id}');

      // Update transaction with UPI app info
      final updatedTransaction = transaction.copyWith(
        upiApp: appMeta.upiApplication.getAppName(),
      );
      await _updateTransaction(updatedTransaction);

      // Initiate UPI transaction using correct API
      final response = await _upiPay.initiateTransaction(
        app: appMeta.upiApplication,
        receiverUpiAddress: _merchantUpiId,
        receiverName: _merchantName,
        transactionRef: transaction.id,
        amount: transaction.amount.toStringAsFixed(2),
        transactionNote: transaction.description,
      );

      // Handle the response
      await _handlePaymentResponse(transaction, response);
      
      return response;
    } catch (e) {
      _logger.e('Payment initiation failed: $e');
      
      // Update transaction as failed
      final failedTransaction = transaction.copyWith(
        status: TransactionStatus.failed,
        errorMessage: e.toString(),
        completedAt: DateTime.now(),
      );
      await _updateTransaction(failedTransaction);
      
      rethrow;
    }
  }

  /// Handle payment response from UPI app
  Future<void> _handlePaymentResponse(
    TransactionModel transaction,
    UpiTransactionResponse response,
  ) async {
    TransactionStatus status;
    String? errorMessage;
    String? responseCode;
    String? transactionRefId;

    try {
      // Get response code (Android only)
      responseCode = response.responseCode;
    } catch (e) {
      // iOS doesn't support responseCode
      responseCode = null;
    }

    switch (response.status) {
      case UpiTransactionStatus.success:
        status = TransactionStatus.success;
        try {
          transactionRefId = response.txnId; // Correct property name
        } catch (e) {
          // iOS doesn't support txnId
          transactionRefId = null;
        }
        _logger.i('Payment successful: ${transaction.id}');
        break;
        
      case UpiTransactionStatus.failure:
        status = TransactionStatus.failed;
        errorMessage = 'Payment failed'; // No error property in response
        _logger.w('Payment failed: ${transaction.id} - $errorMessage');
        break;
        
      case UpiTransactionStatus.submitted:
        status = TransactionStatus.pending;
        try {
          transactionRefId = response.txnId; // Correct property name
        } catch (e) {
          // iOS doesn't support txnId
          transactionRefId = null;
        }
        _logger.i('Payment submitted: ${transaction.id}');
        break;
        
      case UpiTransactionStatus.launched:
        // iOS specific - app launched successfully
        status = TransactionStatus.pending;
        _logger.i('Payment app launched: ${transaction.id}');
        break;
        
      case UpiTransactionStatus.failedToLaunch:
        // iOS specific - app failed to launch
        status = TransactionStatus.failed;
        try {
          errorMessage = response.launchError ?? 'Failed to launch UPI app';
        } catch (e) {
          errorMessage = 'Failed to launch UPI app';
        }
        _logger.w('Payment app launch failed: ${transaction.id}');
        break;
        
      default:
        status = TransactionStatus.cancelled;
        errorMessage = 'Payment cancelled by user';
        _logger.i('Payment cancelled: ${transaction.id}');
    }

    final updatedTransaction = transaction.copyWith(
      status: status,
      transactionRefId: transactionRefId,
      responseCode: responseCode,
      errorMessage: errorMessage,
      completedAt: status != TransactionStatus.pending ? DateTime.now() : null,
    );

    await _updateTransaction(updatedTransaction);
  }

  /// Save transaction to local database
  Future<void> _saveTransaction(TransactionModel transaction) async {
    if (_database == null) await _initializeDatabase();
    
    await _database!.insert(
      'transactions',
      {
        'id': transaction.id,
        'order_id': transaction.orderId,
        'customer_id': transaction.customerId,
        'amount': transaction.amount,
        'description': transaction.description,
        'upi_id': transaction.upiId,
        'payer_name': transaction.payerName,
        'payee_vpa': transaction.payeeVpa,
        'status': transaction.status.name,
        'transaction_ref_id': transaction.transactionRefId,
        'response_code': transaction.responseCode,
        'error_message': transaction.errorMessage,
        'upi_app': transaction.upiApp,
        'created_at': transaction.createdAt.toIso8601String(),
        'completed_at': transaction.completedAt?.toIso8601String(),
        'metadata': transaction.metadata != null 
            ? jsonEncode(transaction.metadata!) 
            : null,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Update transaction in local database
  Future<void> _updateTransaction(TransactionModel transaction) async {
    if (_database == null) await _initializeDatabase();
    
    await _database!.update(
      'transactions',
      {
        'status': transaction.status.name,
        'transaction_ref_id': transaction.transactionRefId,
        'response_code': transaction.responseCode,
        'error_message': transaction.errorMessage,
        'upi_app': transaction.upiApp,
        'completed_at': transaction.completedAt?.toIso8601String(),
        'metadata': transaction.metadata != null 
            ? jsonEncode(transaction.metadata!) 
            : null,
      },
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  /// Get transaction by ID
  Future<TransactionModel?> getTransaction(String transactionId) async {
    if (_database == null) await _initializeDatabase();
    
    final List<Map<String, dynamic>> maps = await _database!.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [transactionId],
    );

    if (maps.isNotEmpty) {
      return _transactionFromMap(maps.first);
    }
    return null;
  }

  /// Get transactions by order ID
  Future<List<TransactionModel>> getTransactionsByOrderId(String orderId) async {
    if (_database == null) await _initializeDatabase();
    
    final List<Map<String, dynamic>> maps = await _database!.query(
      'transactions',
      where: 'order_id = ?',
      whereArgs: [orderId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => _transactionFromMap(map)).toList();
  }

  /// Get transactions by customer ID
  Future<List<TransactionModel>> getTransactionsByCustomerId(
    String customerId, {
    int? limit,
    int? offset,
  }) async {
    if (_database == null) await _initializeDatabase();
    
    final List<Map<String, dynamic>> maps = await _database!.query(
      'transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _transactionFromMap(map)).toList();
  }

  /// Get all transactions with pagination
  Future<List<TransactionModel>> getAllTransactions({
    int? limit,
    int? offset,
    TransactionStatus? status,
  }) async {
    if (_database == null) await _initializeDatabase();
    
    String? whereClause;
    List<dynamic>? whereArgs;
    
    if (status != null) {
      whereClause = 'status = ?';
      whereArgs = [status.name];
    }
    
    final List<Map<String, dynamic>> maps = await _database!.query(
      'transactions',
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
      limit: limit,
      offset: offset,
    );

    return maps.map((map) => _transactionFromMap(map)).toList();
  }

  /// Get transaction statistics
  Future<Map<String, dynamic>> getTransactionStats(String customerId) async {
    if (_database == null) await _initializeDatabase();
    
    final totalResult = await _database!.rawQuery('''
      SELECT 
        COUNT(*) as total_count,
        SUM(amount) as total_amount
      FROM transactions 
      WHERE customer_id = ?
    ''', [customerId]);

    final successResult = await _database!.rawQuery('''
      SELECT 
        COUNT(*) as success_count,
        SUM(amount) as success_amount
      FROM transactions 
      WHERE customer_id = ? AND status = ?
    ''', [customerId, TransactionStatus.success.name]);

    final pendingResult = await _database!.rawQuery('''
      SELECT COUNT(*) as pending_count
      FROM transactions 
      WHERE customer_id = ? AND status = ?
    ''', [customerId, TransactionStatus.pending.name]);

    return {
      'totalTransactions': totalResult.first['total_count'] ?? 0,
      'totalAmount': totalResult.first['total_amount'] ?? 0.0,
      'successfulTransactions': successResult.first['success_count'] ?? 0,
      'successfulAmount': successResult.first['success_amount'] ?? 0.0,
      'pendingTransactions': pendingResult.first['pending_count'] ?? 0,
    };
  }

  /// Convert database map to TransactionModel
  TransactionModel _transactionFromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'] as String,
      orderId: map['order_id'] as String,
      customerId: map['customer_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] as String,
      upiId: map['upi_id'] as String,
      payerName: map['payer_name'] as String,
      payeeVpa: map['payee_vpa'] as String,
      status: TransactionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TransactionStatus.pending,
      ),
      transactionRefId: map['transaction_ref_id'] as String?,
      responseCode: map['response_code'] as String?,
      errorMessage: map['error_message'] as String?,
      upiApp: map['upi_app'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
      metadata: map['metadata'] != null
          ? jsonDecode(map['metadata'] as String) as Map<String, dynamic>
          : null,
    );
  }

  /// Check if device supports UPI
  Future<bool> isUpiSupported() async {
    try {
      final apps = await getAvailableUpiApps();
      return apps.isNotEmpty;
    } catch (e) {
      _logger.e('Error checking UPI support: $e');
      return false;
    }
  }

  /// Get device information for transaction metadata
  Future<Map<String, dynamic>> getDeviceInfo() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      return {
        'device': androidInfo.model,
        'brand': androidInfo.brand,
        'version': androidInfo.version.release,
        'sdkInt': androidInfo.version.sdkInt,
        'manufacturer': androidInfo.manufacturer,
      };
    } catch (e) {
      _logger.e('Error getting device info: $e');
      return {};
    }
  }

  /// Delete old transactions (older than specified days)
  Future<void> cleanupOldTransactions({int daysOld = 365}) async {
    if (_database == null) await _initializeDatabase();
    
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
    
    await _database!.delete(
      'transactions',
      where: 'created_at < ? AND status != ?',
      whereArgs: [
        cutoffDate.toIso8601String(),
        TransactionStatus.pending.name,
      ],
    );
    
    _logger.i('Cleaned up transactions older than $daysOld days');
  }

  /// Retry a failed transaction
  Future<UpiTransactionResponse> retryTransaction({
    required String transactionId,
    required ApplicationMeta appMeta,
  }) async {
    final transaction = await getTransaction(transactionId);
    if (transaction == null) {
      throw Exception('Transaction not found');
    }

    if (transaction.status == TransactionStatus.success) {
      throw Exception('Transaction already successful');
    }

    // Create new transaction for retry
    final retryTransaction = transaction.copyWith(
      id: _generateTransactionId(),
      status: TransactionStatus.pending,
      createdAt: DateTime.now(),
      completedAt: null,
      errorMessage: null,
      transactionRefId: null,
      responseCode: null,
    );

    await _saveTransaction(retryTransaction);
    return initiatePayment(
      transaction: retryTransaction,
      appMeta: appMeta,
    );
  }

  /// Dispose resources
  Future<void> dispose() async {
    await _database?.close();
    _database = null;
  }
} 