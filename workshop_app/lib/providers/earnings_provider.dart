import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/workshop_member.dart';
import '../models/order.dart' as workshop_order;
import '../services/database_service.dart';

class EarningsProvider with ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  
  Map<String, double> _dailyEarnings = {};
  Map<String, int> _dailyOrders = {};
  Map<String, int> _dailyItems = {};
  List<Map<String, dynamic>> _earningsHistory = [];
  
  double _totalEarnings = 0.0;
  double _todaysEarnings = 0.0;
  int _totalOrders = 0;
  int _todaysOrders = 0;
  int _totalItems = 0;
  int _todaysItems = 0;
  
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, double> get dailyEarnings => _dailyEarnings;
  Map<String, int> get dailyOrders => _dailyOrders;
  Map<String, int> get dailyItems => _dailyItems;
  List<Map<String, dynamic>> get earningsHistory => _earningsHistory;
  
  double get totalEarnings => _totalEarnings;
  double get todaysEarnings => _todaysEarnings;
  int get totalOrders => _totalOrders;
  int get todaysOrders => _todaysOrders;
  int get totalItems => _totalItems;
  int get todaysItems => _todaysItems;
  
  bool get isLoading => _isLoading;
  String? get error => _error;

  EarningsProvider() {
    _initializeEarnings();
  }

  // Initialize earnings data
  Future<void> _initializeEarnings() async {
    await loadEarnings();
  }

  // Load earnings data for a member
  Future<void> loadEarnings([WorkshopMember? member]) async {
    if (member == null) return;
    
    setLoading(true);
    _clearError();

    try {
      // Load member's earnings and performance data
      _totalEarnings = member.totalEarnings;
      _todaysEarnings = member.todaysEarnings;
      _totalOrders = member.totalCompletedOrders;
      _todaysOrders = member.todaysCompletedOrders;
      _totalItems = member.totalProcessedItems;
      _todaysItems = member.todaysProcessedItems;
      
      // Process daily earnings
      _dailyEarnings = Map<String, double>.from(
        member.earnings.map((key, value) => MapEntry(key, value.toDouble()))
      );
      
      // Process daily orders
      final completedOrders = member.performance['completedOrders'] as Map<String, dynamic>?;
      _dailyOrders = Map<String, int>.from(
        completedOrders?.map((key, value) => MapEntry(key, value.toInt())) ?? {}
      );
      
      // Process daily items
      final processedItems = member.performance['processedItems'] as Map<String, dynamic>?;
      _dailyItems = Map<String, int>.from(
        processedItems?.map((key, value) => MapEntry(key, value.toInt())) ?? {}
      );
      
      // Load earnings history
      await _loadEarningsHistory(member.id);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load earnings: $e');
    } finally {
      setLoading(false);
    }
  }

  // Load earnings history
  Future<void> _loadEarningsHistory(String memberId) async {
    try {
      _earningsHistory = await _databaseService.getMemberEarningsHistory(memberId);
    } catch (e) {
      debugPrint('Failed to load earnings history: $e');
    }
  }

  // Add earnings for completed order
  Future<void> addEarnings({
    required WorkshopMember member,
    required workshop_order.WorkshopOrder order,
    required double earnings,
  }) async {
    setLoading(true);
    _clearError();

    try {
      final today = DateTime.now();
      final todayKey = DateFormat('yyyy-MM-dd').format(today);
      
      // Update daily earnings
      _dailyEarnings[todayKey] = (_dailyEarnings[todayKey] ?? 0.0) + earnings;
      _dailyOrders[todayKey] = (_dailyOrders[todayKey] ?? 0) + 1;
      _dailyItems[todayKey] = (_dailyItems[todayKey] ?? 0) + order.items.length;
      
      // Update totals
      _totalEarnings += earnings;
      _todaysEarnings = _dailyEarnings[todayKey] ?? 0.0;
      _totalOrders += 1;
      _todaysOrders = _dailyOrders[todayKey] ?? 0;
      _totalItems += order.items.length;
      _todaysItems = _dailyItems[todayKey] ?? 0;
      
      // Create earnings record
      final earningsRecord = {
        'memberId': member.id,
        'orderId': order.id,
        'customerId': order.customerId,
        'customerName': order.customerName,
        'earnings': earnings,
        'itemsProcessed': order.items.length,
        'orderValue': order.totalAmount,
        'date': todayKey,
        'timestamp': DateTime.now().toIso8601String(),
        'orderDetails': {
          'items': order.items.map((item) => {
            'name': item.name,
            'category': item.category,
            'quantity': item.quantity,
            'price': item.price,
          }).toList(),
        },
      };
      
      // Save earnings record
      await _databaseService.saveEarningsRecord(earningsRecord);
      
      // Add to earnings history
      _earningsHistory.insert(0, earningsRecord);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to add earnings: $e');
    } finally {
      setLoading(false);
    }
  }

  // Get earnings for date range
  double getEarningsForDateRange(DateTime startDate, DateTime endDate) {
    double total = 0.0;
    
    for (var entry in _dailyEarnings.entries) {
      final date = DateTime.parse('${entry.key} 00:00:00');
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) && 
          date.isBefore(endDate.add(const Duration(days: 1)))) {
        total += entry.value;
      }
    }
    
    return total;
  }

  // Get orders for date range
  int getOrdersForDateRange(DateTime startDate, DateTime endDate) {
    int total = 0;
    
    for (var entry in _dailyOrders.entries) {
      final date = DateTime.parse('${entry.key} 00:00:00');
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) && 
          date.isBefore(endDate.add(const Duration(days: 1)))) {
        total += entry.value;
      }
    }
    
    return total;
  }

  // Get items for date range
  int getItemsForDateRange(DateTime startDate, DateTime endDate) {
    int total = 0;
    
    for (var entry in _dailyItems.entries) {
      final date = DateTime.parse('${entry.key} 00:00:00');
      if (date.isAfter(startDate.subtract(const Duration(days: 1))) && 
          date.isBefore(endDate.add(const Duration(days: 1)))) {
        total += entry.value;
      }
    }
    
    return total;
  }

  // Get weekly earnings
  double getWeeklyEarnings() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    return getEarningsForDateRange(startOfWeek, endOfWeek);
  }

  // Get monthly earnings
  double getMonthlyEarnings() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    return getEarningsForDateRange(startOfMonth, endOfMonth);
  }

  // Get yearly earnings
  double getYearlyEarnings() {
    final now = DateTime.now();
    final startOfYear = DateTime(now.year, 1, 1);
    final endOfYear = DateTime(now.year, 12, 31);
    
    return getEarningsForDateRange(startOfYear, endOfYear);
  }

  // Get average daily earnings
  double getAverageDailyEarnings() {
    if (_dailyEarnings.isEmpty) return 0.0;
    
    final total = _dailyEarnings.values.fold(0.0, (sum, value) => sum + value);
    return total / _dailyEarnings.length;
  }

  // Get average earnings per order
  double getAverageEarningsPerOrder() {
    if (_totalOrders == 0) return 0.0;
    return _totalEarnings / _totalOrders;
  }

  // Get average earnings per item
  double getAverageEarningsPerItem() {
    if (_totalItems == 0) return 0.0;
    return _totalEarnings / _totalItems;
  }

  // Get earnings chart data for last 7 days
  List<Map<String, dynamic>> getWeeklyChartData() {
    final List<Map<String, dynamic>> chartData = [];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final dayName = DateFormat('EEE').format(date);
      
      chartData.add({
        'day': dayName,
        'date': dateKey,
        'earnings': _dailyEarnings[dateKey] ?? 0.0,
        'orders': _dailyOrders[dateKey] ?? 0,
        'items': _dailyItems[dateKey] ?? 0,
      });
    }
    
    return chartData;
  }

  // Get earnings chart data for last 30 days
  List<Map<String, dynamic>> getMonthlyChartData() {
    final List<Map<String, dynamic>> chartData = [];
    final now = DateTime.now();
    
    for (int i = 29; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final dayName = DateFormat('MMM dd').format(date);
      
      chartData.add({
        'day': dayName,
        'date': dateKey,
        'earnings': _dailyEarnings[dateKey] ?? 0.0,
        'orders': _dailyOrders[dateKey] ?? 0,
        'items': _dailyItems[dateKey] ?? 0,
      });
    }
    
    return chartData;
  }

  // Get top earning days
  List<Map<String, dynamic>> getTopEarningDays({int limit = 5}) {
    final sortedEarnings = _dailyEarnings.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    return sortedEarnings.take(limit).map((entry) {
      final date = DateTime.parse('${entry.key} 00:00:00');
      return {
        'date': entry.key,
        'formattedDate': DateFormat('MMM dd, yyyy').format(date),
        'earnings': entry.value,
        'orders': _dailyOrders[entry.key] ?? 0,
        'items': _dailyItems[entry.key] ?? 0,
      };
    }).toList();
  }

  // Get earnings summary
  Map<String, dynamic> getEarningsSummary() {
    return {
      'today': {
        'earnings': _todaysEarnings,
        'orders': _todaysOrders,
        'items': _todaysItems,
      },
      'week': {
        'earnings': getWeeklyEarnings(),
        'orders': getOrdersForDateRange(
          DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
          DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)),
        ),
        'items': getItemsForDateRange(
          DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1)),
          DateTime.now().add(Duration(days: 7 - DateTime.now().weekday)),
        ),
      },
      'month': {
        'earnings': getMonthlyEarnings(),
        'orders': getOrdersForDateRange(
          DateTime(DateTime.now().year, DateTime.now().month, 1),
          DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
        ),
        'items': getItemsForDateRange(
          DateTime(DateTime.now().year, DateTime.now().month, 1),
          DateTime(DateTime.now().year, DateTime.now().month + 1, 0),
        ),
      },
      'total': {
        'earnings': _totalEarnings,
        'orders': _totalOrders,
        'items': _totalItems,
      },
      'averages': {
        'perDay': getAverageDailyEarnings(),
        'perOrder': getAverageEarningsPerOrder(),
        'perItem': getAverageEarningsPerItem(),
      },
    };
  }

  // Calculate earnings for an order
  double calculateOrderEarnings({
    required workshop_order.WorkshopOrder order,
    double baseRate = 5.0, // Base rate per item
    Map<String, double> categoryMultipliers = const {
      'washing': 1.0,
      'ironing': 1.2,
      'dry_cleaning': 2.0,
      'pressing': 1.1,
    },
  }) {
    double totalEarnings = 0.0;
    
    for (final item in order.items) {
      final multiplier = categoryMultipliers[item.category.toLowerCase()] ?? 1.0;
      final itemEarnings = baseRate * item.quantity * multiplier;
      totalEarnings += itemEarnings;
    }
    
    return totalEarnings;
  }

  // Refresh earnings data
  Future<void> refreshEarnings(WorkshopMember member) async {
    await loadEarnings(member);
  }

  // Set loading state
  void setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  // Set error message
  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  // Clear error message
  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Clear error (public method)
  void clearError() {
    _clearError();
  }

  // Reset earnings data
  void reset() {
    _dailyEarnings.clear();
    _dailyOrders.clear();
    _dailyItems.clear();
    _earningsHistory.clear();
    
    _totalEarnings = 0.0;
    _todaysEarnings = 0.0;
    _totalOrders = 0;
    _todaysOrders = 0;
    _totalItems = 0;
    _todaysItems = 0;
    
    _clearError();
    notifyListeners();
  }
} 