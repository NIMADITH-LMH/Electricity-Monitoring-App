import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/usage_analytics_service.dart';
import '../../models/usage_analytics_model.dart';
import '../../theme/app_colors.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/prediction_card.dart';

class UsageAnalyticsScreen extends StatefulWidget {
  static const routeName = '/usage-analytics';

  const UsageAnalyticsScreen({super.key});

  @override
  _UsageAnalyticsScreenState createState() => _UsageAnalyticsScreenState();
}

class _UsageAnalyticsScreenState extends State<UsageAnalyticsScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String _selectedPeriod = 'monthly'; // Default period
  TabController? _tabController;
  
  // Add debounce timer
  Timer? _debounceTimer;

  UsageAnalyticsModel? _analytics;
  List<UsageDataPoint> _chartData = [];
  List<UsagePredictionModel> _predictions = [];
  DailyUsageBreakdown? _dailyBreakdown;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadAnalyticsData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _debounceTimer?.cancel(); // Cancel debounce timer
    super.dispose();
  }

  Future<void> _loadAnalyticsData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final analyticsService = Provider.of<UsageAnalyticsService>(
        context, 
        listen: false,
      );

      // Load data sequentially to avoid isolate issues
      final analytics = await analyticsService.getUsageAnalytics(
        period: _selectedPeriod
      );
      
      final chartData = await analyticsService.getHistoricalUsageData(
        period: _selectedPeriod
      );
      
      final predictions = await analyticsService.predictFutureUsage();
      
      final dailyBreakdown = await analyticsService.getDailyUsageBreakdown();

      // Only update state if the widget is still mounted
      if (mounted) {
        setState(() {
          _analytics = analytics;
          _chartData = chartData;
          _predictions = predictions;
          _dailyBreakdown = dailyBreakdown;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading analytics data: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Use debounce pattern to avoid excessive reloads
  void _changePeriod(String period) {
    // Cancel existing timer if any
    _debounceTimer?.cancel();
    
    setState(() {
      _selectedPeriod = period;
    });
    
    // Use debounce timer to prevent rapid consecutive calls
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _loadAnalyticsData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'Usage Analytics', showBackButton: true),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading analytics data...')
          : _buildAnalyticsContent(),
    );
  }

  // Helper method to create compact custom cards specifically for analytics screen
  CustomCard _compactCard({required Widget child}) {
    return CustomCard(
      padding: const EdgeInsets.all(6.0), // Very minimal padding
      elevation: 1.0, // Lower elevation
      borderRadius: BorderRadius.circular(12), // Smaller radius
      child: child,
    );
  }

  Widget _buildAnalyticsContent() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(10.0), // Further reduced from 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Period selector
            _buildPeriodSelector(),
            const SizedBox(height: 8), // Further reduced from 12
            // Summary cards
            if (_analytics != null) _buildSummaryCards(),
            const SizedBox(height: 12), // Further reduced from 16
            // Tab bar for different analytics views
            _buildTabBar(),
            const SizedBox(height: 4), // Already reduced
            // Tab views
            SizedBox(
              height: 380, // Further adjusted to ensure proper display in all tabs
              child: TabBarView(
                controller: _tabController,
                physics: ClampingScrollPhysics(), // Prevents overscroll
                children: [
                  _buildUsageChartTab(),
                  _buildCostChartTab(),
                  _buildPredictionsTab(),
                  _buildDailyBreakdownTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _periodButton('Daily', 'daily'),
          _periodButton('Weekly', 'weekly'),
          _periodButton('Monthly', 'monthly'),
          _periodButton('Yearly', 'yearly'),
        ],
      ),
    );
  }

  Widget _periodButton(String label, String period) {
    final isSelected = _selectedPeriod == period;

    return InkWell(
      onTap: () => _changePeriod(period),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final analytics = _analytics!;
    final dateFormat = _selectedPeriod == 'daily'
        ? DateFormat('MMM d, yyyy')
        : _selectedPeriod == 'yearly'
        ? DateFormat('yyyy')
        : DateFormat('MMM d');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Period title
        Text(
          '${dateFormat.format(analytics.startDate)} - ${dateFormat.format(analytics.endDate)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // Usage and cost cards
        Row(
          children: [
            Expanded(
              child: CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced from 16.0
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Usage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ), // Reduced from 14
                      ),
                      const SizedBox(height: 2), // Reduced from 4
                      Text(
                        '${analytics.totalKwh.toStringAsFixed(1)} kWh',
                        style: TextStyle(
                          fontSize: 16, // Reduced from 20
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            analytics.isKwhIncreased
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 12, // Further reduced from 14
                            color: analytics.getKwhTrendColor(),
                          ),
                          const SizedBox(width: 2), // Reduced from 4
                          Flexible(
                            child: Text(
                              analytics.getFormattedKwhChange(),
                              textScaleFactor: 0.9,
                              style: TextStyle(
                                fontSize: 10, // Further reduced from 11
                                color: analytics.getKwhTrendColor(),
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 1), // Further reduced from 2
                          Flexible(
                            child: Text(
                              'vs previous',
                              textScaleFactor: 0.9,
                              style: TextStyle(
                                fontSize: 10, // Reduced from 11
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced from 16.0
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Cost',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ), // Reduced from 14
                      ),
                      const SizedBox(height: 2), // Reduced from 4
                      Text(
                        'LKR ${analytics.totalCost.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 16, // Reduced from 20
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6), // Reduced from 8
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            analytics.isCostIncreased
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            size: 12, // Further reduced from 14
                            color: analytics.getCostTrendColor(),
                          ),
                          const SizedBox(width: 1), // Further reduced from 2
                          Flexible(
                            child: Text(
                              analytics.getFormattedCostChange(),
                              textScaleFactor: 0.9,
                              style: TextStyle(
                                fontSize: 10, // Further reduced from 11
                                color: analytics.getCostTrendColor(),
                                fontWeight: FontWeight.bold,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 1), // Further reduced from 2
                          Flexible(
                            child: Text(
                              'vs previous',
                              textScaleFactor: 0.9,
                              style: TextStyle(
                                fontSize: 10, // Reduced from 11
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Daily average cards
        Row(
          children: [
            Expanded(
              child: CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced from 16.0
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Avg Usage',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ), // Reduced from 14
                      ),
                      const SizedBox(height: 2), // Reduced from 4
                      Text(
                        '${analytics.avgKwhPerDay.toStringAsFixed(1)} kWh',
                        style: TextStyle(
                          fontSize: 14, // Reduced from 18
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(8.0), // Reduced from 16.0
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Daily Avg Cost',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ), // Reduced from 14
                      ),
                      const SizedBox(height: 2), // Reduced from 4
                      Text(
                        'LKR ${analytics.avgCostPerDay.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14, // Reduced from 18
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      labelColor: AppColors.primary,
      unselectedLabelColor: Colors.grey,
      indicatorColor: AppColors.primary,
      labelStyle: TextStyle(fontSize: 12), // Smaller text
      indicatorWeight: 2.0, // Thinner indicator
      tabAlignment: TabAlignment.fill, // Make tabs fill width
      tabs: [
        Tab(text: 'Usage', height: 32), // Reduced height
        Tab(text: 'Cost', height: 32), // Reduced height
        Tab(text: 'Prediction', height: 32), // Reduced height
        Tab(text: 'Breakdown', height: 32), // Reduced height
      ],
    );
  }

  Widget _buildUsageChartTab() {
    if (_chartData.isEmpty) {
      return Center(child: Text('No usage data available'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0), // Reduced from 16.0
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ), // Reduced from 18
          ),
          const SizedBox(height: 4), // Reduced from 8
          Expanded(
            child: _buildLineChart(
              data: _chartData,
              valueSelector: (dataPoint) => dataPoint.kwh,
              valueLabel: 'kWh',
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostChartTab() {
    if (_chartData.isEmpty) {
      return Center(child: Text('No cost data available'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0), // Reduced from 16.0
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cost Trend',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ), // Reduced from 18
          ),
          const SizedBox(height: 4), // Reduced from 8
          Expanded(
            child: _buildLineChart(
              data: _chartData,
              valueSelector: (dataPoint) => dataPoint.cost,
              valueLabel: 'LKR',
              color: Colors.amber[700]!,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    if (_predictions.isEmpty) {
      return Center(child: Text('No prediction data available'));
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Predictions',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 4.0,
                  color: Colors.black.withOpacity(0.3),
                  offset: const Offset(1, 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: PredictionCard(prediction: prediction),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyBreakdownTab() {
    if (_dailyBreakdown == null) {
      return Center(child: Text('No breakdown data available'));
    }

    final breakdown = _dailyBreakdown!;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section with more padding
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Daily Usage Breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Peak: ${breakdown.peakUsageTime}',
                    style: TextStyle(
                      color: Colors.purple[800],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content with better spacing
          Expanded(
            child: Column(
              children: [
                // Pie chart with proper constraints
                Container(
                  height: 180, // Fixed height to prevent overflow
                  child: _buildPieChart(),
                ),
                // Legend and details with padding
                // Legend and details
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 8.0),
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        _buildBreakdownRow(
                          'Morning',
                          breakdown.morningUsage,
                          breakdown.morningPercentage,
                          Colors.blue[400]!,
                        ),
                        _buildBreakdownRow(
                          'Afternoon',
                          breakdown.afternoonUsage,
                          breakdown.afternoonPercentage,
                          Colors.amber[400]!,
                        ),
                        _buildBreakdownRow(
                          'Evening',
                          breakdown.eveningUsage,
                          breakdown.eveningPercentage,
                          Colors.purple[400]!,
                        ),
                        _buildBreakdownRow(
                          'Night',
                          breakdown.nightUsage,
                          breakdown.nightPercentage,
                          Colors.grey[700]!,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(
    String label,
    double usage,
    double percentage,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          // Color indicator
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          
          // Time period label
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const Spacer(),
          
          // Usage value
          Text(
            '${usage.toStringAsFixed(1)} kWh',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Percentage badge
          Container(
            width: 38,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${percentage.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: color.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart({
    required List<UsageDataPoint> data,
    required double Function(UsageDataPoint) valueSelector,
    required String valueLabel,
    required Color color,
  }) {
    // Calculate min and max values for better scaling
    double maxY = 0;
    for (final point in data) {
      final value = valueSelector(point);
      if (value > maxY) maxY = value;
    }
    maxY = maxY * 1.2; // Add some padding

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey[300], strokeWidth: 1);
          },
          getDrawingVerticalLine: (value) {
            return FlLine(color: Colors.grey[300], strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value < 0 || value >= data.length) {
                  return const Text('');
                }
                final date = data[value.toInt()].date;
                String text;
                switch (_selectedPeriod) {
                  case 'daily':
                    text = DateFormat('M/d').format(date);
                    break;
                  case 'weekly':
                    text = 'W${((date.day - 1) ~/ 7) + 1}';
                    break;
                  case 'monthly':
                    text = DateFormat('MMM').format(date);
                    break;
                  case 'yearly':
                    text = DateFormat('yyyy').format(date);
                    break;
                  default:
                    text = DateFormat('M/d').format(date);
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    text,
                    style: TextStyle(color: Colors.grey[700], fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '$valueLabel${value.toInt()}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 10),
                );
              },
            ),
          ),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        minX: 0,
        maxX: data.length.toDouble() - 1,
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              data.length,
              (i) => FlSpot(i.toDouble(), valueSelector(data[i])),
            ),
            isCurved: true,
            color: color,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: color,
                  strokeWidth: 1,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart() {
    if (_dailyBreakdown == null) {
      return Center(child: Text('No data available'));
    }

    // Calculate radius based on container size (not full screen width)
    final radius = 80.0; // Fixed size for consistent display

    final breakdown = _dailyBreakdown!;
    final sections = [
      PieChartSectionData(
        value: breakdown.morningUsage,
        title: '${breakdown.morningPercentage.toInt()}%',
        color: Colors.blue[400],
        radius: radius,
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        showTitle: breakdown.morningPercentage >= 10, // Only show title if percentage is large enough
      ),
      PieChartSectionData(
        value: breakdown.afternoonUsage,
        title: '${breakdown.afternoonPercentage.toInt()}%',
        color: Colors.amber[400],
        radius: radius,
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        showTitle: breakdown.afternoonPercentage >= 10,
      ),
      PieChartSectionData(
        value: breakdown.eveningUsage,
        title: '${breakdown.eveningPercentage.toInt()}%',
        color: Colors.purple[400],
        radius: radius,
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        showTitle: breakdown.eveningPercentage >= 10,
      ),
      PieChartSectionData(
        value: breakdown.nightUsage,
        title: '${breakdown.nightPercentage.toInt()}%',
        color: Colors.grey[700],
        radius: radius,
        titleStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        showTitle: breakdown.nightPercentage >= 10,
      ),
    ];

    return Center(
      child: PieChart(
        PieChartData(
          sectionsSpace: 0,
          centerSpaceRadius: 25, // Fixed center space
          sections: sections,
          pieTouchData: PieTouchData(
            touchCallback: (FlTouchEvent event, pieTouchResponse) {
              // Optional: handle touch events if desired
            },
          ),
        ),
        swapAnimationDuration: Duration(milliseconds: 150),
      ),
    );
  }
}
