import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shivam_super_market/core/Textfield.dart';
import 'package:shivam_super_market/core/config.dart';
import 'package:shivam_super_market/widget/PageWrapper.dart';

/// ================== MODEL ==================


class DashboardData {
  double todaySales;
  double totalProfit;
  int totalOrders;
  int itemsSold;

  DashboardData({
    required this.todaySales,
    required this.totalProfit,
    required this.totalOrders,
    required this.itemsSold,
  });
}

Future<DashboardData> getDashboardData({DateTime? selectedDate}) async {
  final now = selectedDate ?? DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  final snapshot = await FirebaseFirestore.instance
      .collection('sales')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('date', isLessThan: Timestamp.fromDate(endOfDay))
      .get();

  double totalSales = 0, totalProfit = 0;
  int totalOrders = 0, itemsSold = 0;

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final List items = data['order'] ?? [];
    totalOrders++;
    for (var item in items) {
      final int qty = item['qty'] ?? 0;
      final double selling = (item['selling_price'] ?? 0).toDouble();
      final double cost    = (item['cost_price'] ?? 0).toDouble();
      totalSales  += selling * qty;
      totalProfit += (selling - cost) * qty;
      itemsSold   += qty;
    }
  }

  return DashboardData(
    todaySales: totalSales,
    totalProfit: totalProfit,
    totalOrders: totalOrders,
    itemsSold: itemsSold,
  );
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double monthlySales = 0;
  double monthlyProfit = 0;
  double monthlyBills = 0;
  List<ProductSales> topProducts = [];
  Map<int, double> salesTrend = {};
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    getMonthlyDetails();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: primaryColor,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Dashboard',
      subtitle: 'Welcome back! Here\'s today\'s overview.',
      actions: [
        TextButton.icon(
          onPressed: () => setState(() => selectedDate = DateTime.now()),
          icon: const Icon(Icons.today_rounded, size: 16),
          label: const Text('Today'),
          style: TextButton.styleFrom(foregroundColor: secondaryColor),
        ),
        IconButton(
          icon: Icon(Icons.calendar_month_rounded, color: primaryColor),
          onPressed: _pickDate,
          tooltip: 'Pick Date',
        ),
      ],
      child: FutureBuilder(
        future: getDashboardData(selectedDate: selectedDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(60),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final data = snapshot.data as DashboardData;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date chip
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 14, color: primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('dd MMMM yyyy').format(selectedDate),
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── KPI Cards ─────────────────────────────────
              _ResponsiveGrid(
                minItemWidth: 200,
                children: [
                  _StatCard(
                    title: 'Total Sales',
                    value: '₹${data.todaySales.toStringAsFixed(2)}',
                    icon: Icons.currency_rupee_rounded,
                    color: primaryColor,
                  ),
                  _StatCard(
                    title: 'Net Profit',
                    value: '₹${data.totalProfit.toStringAsFixed(2)}',
                    icon: Icons.trending_up_rounded,
                    color: Colors.green[700]!,
                  ),
                  _StatCard(
                    title: 'Total Bills',
                    value: '${data.totalOrders}',
                    icon: Icons.receipt_long_rounded,
                    color: secondaryColor,
                  ),
                  _StatCard(
                    title: 'Items Sold',
                    value: '${data.itemsSold}',
                    icon: Icons.shopping_cart_rounded,
                    color: Colors.purple[600]!,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── Daily + Monthly Overview ──────────────────
              LayoutBuilder(builder: (context, c) {
                final twoCol = c.maxWidth > 600;
                return twoCol
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _dailyCard(data)),
                    const SizedBox(width: 16),
                    Expanded(child: _monthlyCard()),
                  ],
                )
                    : Column(children: [
                  _dailyCard(data),
                  const SizedBox(height: 16),
                  _monthlyCard(),
                ]);
              }),
              const SizedBox(height: 24),

              // ── Top Products ──────────────────────────────
              _topProductsCard(),
              const SizedBox(height: 24),

              // ── Sales Chart ───────────────────────────────
              _buildSalesChart(salesTrend),
            ],
          );
        },
      ),
    );
  }

  Widget _dailyCard(DashboardData data) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: myDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Overview',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor)),
          const SizedBox(height: 14),
          _overviewRow('Bills', '${data.totalOrders}', Colors.blue),
          const Divider(height: 16),
          _overviewRow('Sales',
              '₹${data.todaySales.toStringAsFixed(2)}', Colors.blue),
          const Divider(height: 16),
          _overviewRow('Profit',
              '₹${data.totalProfit.toStringAsFixed(2)}', Colors.green),
        ],
      ),
    );
  }

  Widget _monthlyCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: myDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly – ${printDate(date: DateTime.now().toString(), format: "MMMM yyyy")}',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryColor),
          ),
          const SizedBox(height: 14),
          _overviewRow('Bills', '$monthlyBills', Colors.blue),
          const Divider(height: 16),
          _overviewRow(
              'Sales', '₹${monthlySales.toStringAsFixed(2)}', Colors.blue),
          const Divider(height: 16),
          _overviewRow(
              'Profit', '₹${monthlyProfit.toStringAsFixed(2)}', Colors.green),
        ],
      ),
    );
  }

  Widget _overviewRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(fontSize: 14, color: Colors.grey)),
        Text(value,
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _topProductsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: myDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Top Selling Products (This Month)',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryColor)),
          const SizedBox(height: 12),
          if (topProducts.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text('No data yet',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topProducts.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = topProducts[i];
                return ListTile(
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: primaryColor.withOpacity(0.1),
                    child: Text('${i + 1}',
                        style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  title: Text(p.name,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: Text('${p.qty} sold',
                      style: TextStyle(
                          color: secondaryColor,
                          fontWeight: FontWeight.bold)),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSalesChart(Map<int, double> dailySales) {
    final spots = List.generate(
      31,
          (i) => FlSpot((i + 1).toDouble(), dailySales[i + 1] ?? 0),
    );
    return Container(
      height: 260,
      padding:
      const EdgeInsets.only(right: 20, top: 20, bottom: 12, left: 10),
      decoration: myDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Text('Monthly Sales Trend',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryColor)),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) => FlLine(
                      color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 5,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey),
                      ),
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, _) => Text(
                        '₹${value.toInt()}',
                        style: const TextStyle(
                            fontSize: 9, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: primaryColor,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryColor.withOpacity(0.07),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void getMonthlyDetails() async {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);
    final Map<String, int> productMap = {};

    final snapshot = await FirebaseFirestore.instance
        .collection('sales')
        .where('date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final List items = data['order'] ?? [];
      for (var item in items) {
        final int qty = item['qty'] ?? 0;
        monthlyBills += 1;
        monthlySales += (item['selling_price'] ?? 0) * qty;
        monthlyProfit +=
            ((item['selling_price'] ?? 0) - (item['cost_price'] ?? 0)) * qty;
        productMap[item['name'] ?? '-'] =
            (productMap[item['name'] ?? 'Unknown'] ?? 0) + qty;
      }
      final DateTime date = (data['date'] as Timestamp).toDate();
      salesTrend[date.day] =
          (salesTrend[date.day] ?? 0) + (data['total'] ?? 0);
    }

    final sorted = productMap.entries
        .map((e) => ProductSales(e.key, e.value))
        .toList()
      ..sort((a, b) => b.qty.compareTo(a.qty));
    topProducts = sorted.take(10).toList();
    if (mounted) setState(() {});
  }
}

class ProductSales {
  final String name;
  final int qty;
  ProductSales(this.name, this.qty);
}

// ── Responsive grid ───────────────────────────────────────────
class _ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final double minItemWidth;
  final double spacing;

  const _ResponsiveGrid({
    required this.children,
    this.minItemWidth = 200,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols =
      (constraints.maxWidth / (minItemWidth + spacing)).floor().clamp(1, 6);
      final itemWidth =
          (constraints.maxWidth - spacing * (cols - 1)) / cols;
      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: children
            .map((c) => SizedBox(width: itemWidth, child: c))
            .toList(),
      );
    });
  }
}

// ── Stat card ─────────────────────────────────────────────────
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value,
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}