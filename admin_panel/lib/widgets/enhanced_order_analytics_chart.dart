// widgets/enhanced_order_analytics_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class EnhancedOrderAnalyticsChart extends StatefulWidget {
  const EnhancedOrderAnalyticsChart({super.key});

  @override
  State<EnhancedOrderAnalyticsChart> createState() => _EnhancedOrderAnalyticsChartState();
}

class _EnhancedOrderAnalyticsChartState extends State<EnhancedOrderAnalyticsChart> {
  String selectedPeriod = 'Daily';
  List<OrderAnalyticsData> analyticsData = [];
  bool isLoading = true;
  String? error;
  
  // Custom date range
  DateTime? customStartDate;
  DateTime? customEndDate;
  bool isCustomRange = false;

  final List<String> periods = ['Daily', 'Weekly', 'Monthly', 'Custom Range'];
  
  @override
  void initState() {
    super.initState();
    _loadAnalyticsData();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    try {
      final data = await _fetchOrderAnalytics(selectedPeriod);
      setState(() {
        analyticsData = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<List<OrderAnalyticsData>> _fetchOrderAnalytics(String period) async {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = now;
    
    switch (period) {
      case 'Daily':
        startDate = now.subtract(const Duration(days: 30)); // Last 30 days
        break;
      case 'Weekly':
        startDate = now.subtract(const Duration(days: 84)); // Last 12 weeks
        break;
      case 'Monthly':
        startDate = DateTime(now.year - 1, now.month, 1); // Last 12 months
        break;
      case 'Custom Range':
        if (customStartDate != null && customEndDate != null) {
          startDate = customStartDate!;
          endDate = customEndDate!;
        } else {
          startDate = now.subtract(const Duration(days: 30));
        }
        break;
      default:
        startDate = now.subtract(const Duration(days: 30));
    }

    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('orderTimestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
    
    // Add end date filter for custom range
    if (period == 'Custom Range' && customEndDate != null) {
      query = query.where('orderTimestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
    }
    
    final ordersSnapshot = await query.get();

    return _processOrderData(ordersSnapshot.docs, period, startDate, endDate);
  }

  List<OrderAnalyticsData> _processOrderData(
    List<QueryDocumentSnapshot> orders,
    String period,
    DateTime startDate,
    DateTime endDate,
  ) {
    Map<String, OrderAnalyticsData> dataMap = {};

    // Initialize data points based on period
    switch (period) {
      case 'Daily':
        final days = period == 'Custom Range' 
            ? endDate.difference(startDate).inDays + 1
            : 30;
        for (int i = 0; i < days && i < 60; i++) { // Limit to max 60 days for performance
          final date = startDate.add(Duration(days: i));
          if (date.isAfter(endDate)) break;
          final key = DateFormat('MMM dd').format(date);
          dataMap[key] = OrderAnalyticsData(
            label: key,
            date: date,
            totalOrders: 0,
            pendingOrders: 0,
            processingOrders: 0,
            deliveredOrders: 0,
            orders: [],
          );
        }
        break;
      case 'Weekly':
        final weeks = period == 'Custom Range'
            ? (endDate.difference(startDate).inDays / 7).ceil()
            : 12;
        for (int i = 0; i < weeks && i < 24; i++) { // Limit to max 24 weeks
          final weekStart = startDate.add(Duration(days: i * 7));
          if (weekStart.isAfter(endDate)) break;
          final key = 'Week ${i + 1}';
          dataMap[key] = OrderAnalyticsData(
            label: key,
            date: weekStart,
            totalOrders: 0,
            pendingOrders: 0,
            processingOrders: 0,
            deliveredOrders: 0,
            orders: [],
          );
        }
        break;
      case 'Monthly':
        final months = period == 'Custom Range'
            ? ((endDate.year - startDate.year) * 12 + endDate.month - startDate.month + 1)
            : 12;
        for (int i = 0; i < months && i < 24; i++) { // Limit to max 24 months
          final month = DateTime(startDate.year, startDate.month + i, 1);
          if (month.isAfter(endDate)) break;
          final key = DateFormat('MMM yyyy').format(month);
          dataMap[key] = OrderAnalyticsData(
            label: key,
            date: month,
            totalOrders: 0,
            pendingOrders: 0,
            processingOrders: 0,
            deliveredOrders: 0,
            orders: [],
          );
        }
        break;
      case 'Custom Range':
        // For custom range, default to daily view
        final days = endDate.difference(startDate).inDays + 1;
        for (int i = 0; i < days && i < 60; i++) { // Limit to max 60 days
          final date = startDate.add(Duration(days: i));
          if (date.isAfter(endDate)) break;
          final key = DateFormat('MMM dd').format(date);
          dataMap[key] = OrderAnalyticsData(
            label: key,
            date: date,
            totalOrders: 0,
            pendingOrders: 0,
            processingOrders: 0,
            deliveredOrders: 0,
            orders: [],
          );
        }
        break;
    }

    // Process orders and categorize them
    for (final orderDoc in orders) {
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final orderTimestamp = orderData['orderTimestamp'] as Timestamp;
      final orderDate = orderTimestamp.toDate();
      final status = orderData['status']?.toString().toLowerCase() ?? 'pending';

      String key;
      switch (period) {
        case 'Daily':
          key = DateFormat('MMM dd').format(orderDate);
          break;
        case 'Weekly':
          final weeksDiff = orderDate.difference(startDate).inDays ~/ 7;
          key = 'Week ${weeksDiff + 1}';
          break;
        case 'Monthly':
          key = DateFormat('MMM yyyy').format(orderDate);
          break;
        case 'Custom Range':
          // For custom range, use daily format
          key = DateFormat('MMM dd').format(orderDate);
          break;
        default:
          key = DateFormat('MMM dd').format(orderDate);
      }

      if (dataMap.containsKey(key)) {
        final data = dataMap[key]!;
        data.totalOrders++;
        data.orders.add(orderData);

        // Categorize by status
        if (status.contains('pending') || status.contains('new')) {
          data.pendingOrders++;
        } else if (status.contains('processing') || 
                   status.contains('assigned') || 
                   status.contains('picked') ||
                   status.contains('in_process') ||
                   status.contains('ironing')) {
          data.processingOrders++;
        } else if (status.contains('delivered') || 
                   status.contains('completed')) {
          data.deliveredOrders++;
        } else {
          data.processingOrders++; // Default to processing
        }
      }
    }

    return dataMap.values.toList()..sort((a, b) => a.date.compareTo(b.date));
  }

  Future<void> _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime.now(),
      initialDateRange: customStartDate != null && customEndDate != null
          ? DateTimeRange(start: customStartDate!, end: customEndDate!)
          : DateTimeRange(
              start: DateTime.now().subtract(const Duration(days: 30)),
              end: DateTime.now(),
            ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue[700],
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        customStartDate = picked.start;
        customEndDate = picked.end;
        isCustomRange = true;
      });
      _loadAnalyticsData();
    } else {
      // If user cancels, revert to previous selection
      setState(() {
        selectedPeriod = 'Daily';
        isCustomRange = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with filter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Orders Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedPeriod,
                      icon: Icon(Icons.keyboard_arrow_down, color: Colors.blue[700]),
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.w600,
                      ),
                      items: periods.map((period) {
                        return DropdownMenuItem(
                          value: period,
                          child: Text(period),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null && value != selectedPeriod) {
                          setState(() {
                            selectedPeriod = value;
                            isCustomRange = value == 'Custom Range';
                          });
                          if (value == 'Custom Range') {
                            _showDateRangePicker();
                          } else {
                            _loadAnalyticsData();
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Custom date range display
            if (isCustomRange && customStartDate != null && customEndDate != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.date_range, color: Colors.blue[700], size: 16),
                        const SizedBox(width: 8),
                        Text(
                          'Selected Range: ${DateFormat('MMM dd, yyyy').format(customStartDate!)} - ${DateFormat('MMM dd, yyyy').format(customEndDate!)}',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: _showDateRangePicker,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Change',
                          style: TextStyle(
                            color: Colors.blue[700],
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Legend
            _buildLegend(),
            const SizedBox(height: 20),

            // Chart
            if (isLoading)
              const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              )
            else if (error != null)
              SizedBox(
                height: 300,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading analytics',
                        style: TextStyle(color: Colors.red[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadAnalyticsData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            else if (analyticsData.isEmpty)
              const SizedBox(
                height: 300,
                child: Center(
                  child: Text(
                    'No data available for the selected period',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ),
              )
            else
              SizedBox(
                height: 350,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxY(),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipColor: (group) => Colors.blueGrey[800]!,
                        tooltipRoundedRadius: 8,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final data = analyticsData[groupIndex];
                          String label = '';
                          int value = 0;
                          
                          switch (rodIndex) {
                            case 0:
                              label = 'Total Orders';
                              value = data.totalOrders;
                              break;
                            case 1:
                              label = 'Pending';
                              value = data.pendingOrders;
                              break;
                            case 2:
                              label = 'Processing';
                              value = data.processingOrders;
                              break;
                            case 3:
                              label = 'Delivered';
                              value = data.deliveredOrders;
                              break;
                          }
                          
                          return BarTooltipItem(
                            '$label\n$value orders\n${data.label}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                      touchCallback: (FlTouchEvent event, barTouchResponse) {
                        if (event is FlTapUpEvent && barTouchResponse?.spot != null) {
                          final touchedGroupIndex = barTouchResponse!.spot!.touchedBarGroupIndex;
                          _showOrderDetails(analyticsData[touchedGroupIndex]);
                        }
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final index = value.toInt();
                            if (index >= 0 && index < analyticsData.length) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  analyticsData[index].label,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                            return const Text('');
                          },
                          reservedSize: 40,
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: _buildBarGroups(),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getMaxY() / 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey[300]!,
                          strokeWidth: 1,
                        );
                      },
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Summary stats
            _buildSummaryStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildLegendItem('Total', Colors.blue[600]!),
        _buildLegendItem('Pending', Colors.orange[600]!),
        _buildLegendItem('Processing', Colors.purple[600]!),
        _buildLegendItem('Delivered', Colors.green[600]!),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    return analyticsData.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      
      return BarChartGroupData(
        x: index,
        barRods: [
          // Total orders (background bar)
          BarChartRodData(
            toY: data.totalOrders.toDouble(),
            color: Colors.blue[600]!.withOpacity(0.3),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
          // Pending orders
          BarChartRodData(
            toY: data.pendingOrders.toDouble(),
            color: Colors.orange[600]!,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
          // Processing orders
          BarChartRodData(
            toY: data.processingOrders.toDouble(),
            color: Colors.purple[600]!,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
          // Delivered orders
          BarChartRodData(
            toY: data.deliveredOrders.toDouble(),
            color: Colors.green[600]!,
            width: 6,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
          ),
        ],
      );
    }).toList();
  }

  double _getMaxY() {
    if (analyticsData.isEmpty) return 10;
    final maxValue = analyticsData
        .map((data) => data.totalOrders)
        .reduce((a, b) => a > b ? a : b);
    return (maxValue * 1.2).ceilToDouble();
  }

  Widget _buildSummaryStats() {
    if (analyticsData.isEmpty) return const SizedBox.shrink();

    final totalOrders = analyticsData.fold(0, (sum, data) => sum + data.totalOrders);
    final totalPending = analyticsData.fold(0, (sum, data) => sum + data.pendingOrders);
    final totalProcessing = analyticsData.fold(0, (sum, data) => sum + data.processingOrders);
    final totalDelivered = analyticsData.fold(0, (sum, data) => sum + data.deliveredOrders);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('Total Orders', totalOrders.toString(), Colors.blue[600]!),
          _buildStatItem('Pending', totalPending.toString(), Colors.orange[600]!),
          _buildStatItem('Processing', totalProcessing.toString(), Colors.purple[600]!),
          _buildStatItem('Delivered', totalDelivered.toString(), Colors.green[600]!),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  void _showOrderDetails(OrderAnalyticsData data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Orders Details - ${data.label}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(),
              
              // Stats summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailStatItem('Total', data.totalOrders, Colors.blue[600]!),
                    _buildDetailStatItem('Pending', data.pendingOrders, Colors.orange[600]!),
                    _buildDetailStatItem('Processing', data.processingOrders, Colors.purple[600]!),
                    _buildDetailStatItem('Delivered', data.deliveredOrders, Colors.green[600]!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Orders list
              if (data.orders.isNotEmpty) ...[
                Text(
                  'Recent Orders',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: data.orders.length > 10 ? 10 : data.orders.length,
                    itemBuilder: (context, index) {
                      final order = data.orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(order['status']),
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(
                            order['customerName'] ?? 'Unknown Customer',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Status: ${order['status'] ?? 'Unknown'}'),
                              Text('Amount: ₹${order['totalAmount'] ?? 0}'),
                            ],
                          ),
                          trailing: Text(
                            DateFormat('MMM dd, HH:mm').format(
                              (order['orderTimestamp'] as Timestamp).toDate(),
                            ),
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (data.orders.length > 10)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Showing 10 of ${data.orders.length} orders',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ] else
                const Expanded(
                  child: Center(
                    child: Text(
                      'No orders found for this period',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailStatItem(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    if (status == null) return Colors.grey;
    
    final statusLower = status.toLowerCase();
    if (statusLower.contains('pending') || statusLower.contains('new')) {
      return Colors.orange[600]!;
    } else if (statusLower.contains('processing') || 
               statusLower.contains('assigned') || 
               statusLower.contains('picked') ||
               statusLower.contains('in_process') ||
               statusLower.contains('ironing')) {
      return Colors.purple[600]!;
    } else if (statusLower.contains('delivered') || 
               statusLower.contains('completed')) {
      return Colors.green[600]!;
    }
    return Colors.grey[600]!;
  }
}

class OrderAnalyticsData {
  final String label;
  final DateTime date;
  int totalOrders;
  int pendingOrders;
  int processingOrders;
  int deliveredOrders;
  final List<Map<String, dynamic>> orders;

  OrderAnalyticsData({
    required this.label,
    required this.date,
    required this.totalOrders,
    required this.pendingOrders,
    required this.processingOrders,
    required this.deliveredOrders,
    required this.orders,
  });
}
