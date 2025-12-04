import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantapp/models/order_model.dart';
import 'package:restaurantapp/widgets/admin_drawer.dart';

// Restaurant theme colors
const Color _warmOrange = Color(0xFFE85D04);
const Color _deepBrown = Color(0xFF3D2914);
const Color _cream = Color(0xFFFFF8F0);
const Color _gold = Color(0xFFD4A574);
const Color _lightBrown = Color(0xFF8B6914);

enum StatsPeriod { today, week, month }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  StatsPeriod _selectedPeriod = StatsPeriod.today;
  
  DateTime get _startDate {
    final now = DateTime.now();
    switch (_selectedPeriod) {
      case StatsPeriod.today:
        return DateTime(now.year, now.month, now.day);
      case StatsPeriod.week:
        return DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
      case StatsPeriod.month:
        return DateTime(now.year, now.month - 1, now.day);
    }
  }

  String get _periodLabel {
    switch (_selectedPeriod) {
      case StatsPeriod.today:
        return "Aujourd'hui";
      case StatsPeriod.week:
        return 'Cette semaine';
      case StatsPeriod.month:
        return 'Ce mois';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistiques',
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.bold,
            color: _deepBrown,
          ),
        ),
        backgroundColor: _cream,
        iconTheme: const IconThemeData(color: _deepBrown),
        elevation: 0,
        centerTitle: true,
      ),
      drawer: const AdminDrawer(),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_cream, Color(0xFFFFF5E6)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Period selector
              _buildPeriodSelector(),
              const SizedBox(height: 24),
              
              // Stats cards
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('orders')
                    .where('status', isEqualTo: 'paid')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: _warmOrange));
                  }
                  
                  final orders = snapshot.data?.docs
                      .map((doc) => OrderModel.fromFirestore(doc))
                      .where((order) => order.paidAt != null && order.paidAt!.isAfter(_startDate))
                      .toList() ?? [];
                  
                  final totalRevenue = orders.fold<double>(0, (sum, order) => sum + order.totalAmount);
                  final averageOrder = orders.isEmpty ? 0.0 : totalRevenue / orders.length;
                  
                  // Calculate dish popularity
                  final dishCounts = <String, int>{};
                  for (final order in orders) {
                    for (final item in order.items) {
                      dishCounts[item.name] = (dishCounts[item.name] ?? 0) + item.quantity;
                    }
                  }
                  
                  // Calculate server performance
                  final serverCounts = <String, int>{};
                  final serverRevenue = <String, double>{};
                  for (final order in orders) {
                    serverCounts[order.serverName] = (serverCounts[order.serverName] ?? 0) + 1;
                    serverRevenue[order.serverName] = (serverRevenue[order.serverName] ?? 0.0) + order.totalAmount;
                  }
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Revenue cards
                      _buildRevenueCards(totalRevenue, averageOrder, orders.length),
                      const SizedBox(height: 24),
                      
                      // Pie chart for dishes
                      _buildDishesChart(dishCounts),
                      const SizedBox(height: 24),
                      
                      // Bar chart for servers (Orders count)
                      _buildServersChart(serverCounts),
                      const SizedBox(height: 24),

                      // Bar chart for servers (Revenue)
                      _buildServerRevenueChart(serverRevenue),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: _deepBrown.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: StatsPeriod.values.map((period) {
          final isSelected = _selectedPeriod == period;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = period),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? _warmOrange : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected ? [
                    BoxShadow(
                      color: _warmOrange.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ] : null,
                ),
                child: Text(
                  _getPeriodText(period),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isSelected ? Colors.white : Colors.grey[600],
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPeriodText(StatsPeriod period) {
    switch (period) {
      case StatsPeriod.today:
        return "Aujourd'hui";
      case StatsPeriod.week:
        return 'Semaine';
      case StatsPeriod.month:
        return 'Mois';
    }
  }

  Widget _buildRevenueCards(double total, double average, int count) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            title: 'Total',
            value: '${total.toStringAsFixed(0)} DH',
            icon: Icons.payments_rounded,
            color: _warmOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Moyenne',
            value: '${average.toStringAsFixed(0)} DH',
            icon: Icons.trending_up_rounded,
            color: _gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: 'Commandes',
            value: count.toString(),
            icon: Icons.receipt_long_rounded,
            color: _deepBrown,
          ),
        ),
      ],
    );
  }

  Widget _buildDishesChart(Map<String, int> dishCounts) {
    if (dishCounts.isEmpty) {
      return _buildEmptyChart('Plats les plus demandés', 'Aucune donnée disponible');
    }

    // Sort and take top 5
    final sortedDishes = dishCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topDishes = sortedDishes.take(5).toList();
    final totalCount = topDishes.fold<int>(0, (sum, e) => sum + e.value);

    final colors = [
      _warmOrange,
      _deepBrown,
      _gold,
      _lightBrown,
      const Color(0xFF5D3A1A),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: _deepBrown.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _warmOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.pie_chart_rounded, color: _warmOrange, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Plats populaires',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _deepBrown,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(topDishes.length, (i) {
                  final dish = topDishes[i];
                  final percentage = (dish.value / totalCount * 100);
                  return PieChartSectionData(
                    color: colors[i % colors.length],
                    value: dish.value.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: List.generate(topDishes.length, (i) {
              final dish = topDishes[i];
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${dish.key} (${dish.value})',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildServersChart(Map<String, int> serverCounts) {
    if (serverCounts.isEmpty) {
      return _buildEmptyChart('Performance par serveur', 'Aucune donnée disponible');
    }

    final sortedServers = serverCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sortedServers.first.value.toDouble();

    return _buildBarChartContainer(
      title: 'Commandes par serveur',
      subtitle: 'Nombre de commandes',
      icon: Icons.bar_chart_rounded,
      barGroups: List.generate(sortedServers.length, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sortedServers[i].value.toDouble(),
              color: _lightBrown,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue * 1.2,
                color: _lightBrown.withValues(alpha: 0.1),
              ),
            ),
          ],
        );
      }),
      bottomTitles: sortedServers.map((e) => e.key).toList(),
      maxValue: maxValue * 1.2,
      formatValue: (v) => v.toInt().toString(),
    );
  }

  Widget _buildServerRevenueChart(Map<String, double> serverRevenue) {
    if (serverRevenue.isEmpty) {
      return _buildEmptyChart('Revenu par serveur', 'Aucune donnée disponible');
    }

    final sortedServers = serverRevenue.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxValue = sortedServers.first.value;

    return _buildBarChartContainer(
      title: 'Chiffre d\'affaires',
      subtitle: 'Revenu généré (DH)',
      icon: Icons.attach_money_rounded,
      barGroups: List.generate(sortedServers.length, (i) {
        return BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: sortedServers[i].value,
              color: _warmOrange,
              width: 20,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxValue * 1.2,
                color: _warmOrange.withValues(alpha: 0.1),
              ),
            ),
          ],
        );
      }),
      bottomTitles: sortedServers.map((e) => e.key).toList(),
      maxValue: maxValue * 1.2,
      formatValue: (v) => v.toInt().toString(),
    );
  }
  
  Widget _buildBarChartContainer({
    required String title,
    required String subtitle,
    required IconData icon,
    required List<BarChartGroupData> barGroups,
    required List<String> bottomTitles,
    required double maxValue,
    required String Function(double) formatValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: _deepBrown.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _deepBrown.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _deepBrown, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _deepBrown,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxValue,
                barTouchData: BarTouchData(
                  enabled: true,
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${bottomTitles[groupIndex]}\n${rod.toY.toStringAsFixed(0)}',
                        GoogleFonts.inter(color: Colors.white, fontSize: 12),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < bottomTitles.length) {
                          final name = bottomTitles[index];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              name.length > 6 ? '${name.substring(0, 6)}.' : name,
                              style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[600]),
                            ),
                          );
                        }
                        return const Text('');
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink();
                        return Text(
                          formatValue(value),
                          style: GoogleFonts.inter(fontSize: 10, color: Colors.grey[400]),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxValue > 0 ? maxValue / 4 : 1,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey[100],
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String title, String message) {
    return Container(
      padding: const EdgeInsets.all(30),
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _gold.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(
            color: _deepBrown.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: _deepBrown,
            ),
          ),
          const SizedBox(height: 30),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _cream,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.bar_chart_rounded, size: 40, color: _gold.withValues(alpha: 0.5)),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.inter(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
