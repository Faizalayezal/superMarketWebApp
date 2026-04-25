import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:shivam_super_market/core/Textfield.dart';
import 'package:shivam_super_market/core/config.dart';

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

/// ================== API ==================
Future<DashboardData> getDashboardData({DateTime? selectedDate}) async {
  DateTime now = selectedDate ?? DateTime.now();

  DateTime startOfDay = DateTime(now.year, now.month, now.day);
  DateTime endOfDay = startOfDay.add(const Duration(days: 1));

  QuerySnapshot snapshot = await FirebaseFirestore.instance
      .collection('sales')
      .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('date', isLessThan: Timestamp.fromDate(endOfDay))
      .get();

  double totalSales = 0;
  double totalProfit = 0;
  int totalOrders = 0;
  int itemsSold = 0;

  for (var doc in snapshot.docs) {
    var data = doc.data() as Map<String, dynamic>;
    List items = data['order'] ?? [];

    totalOrders++;

    for (var item in items) {
      int qty = item['qty'] ?? 0;
      double selling = (item['selling_price'] ?? 0).toDouble();
      double cost = (item['cost_price'] ?? 0).toDouble();

      totalSales += selling * qty;
      totalProfit += (selling - cost) * qty;
      itemsSold += qty;
    }
  }

  return DashboardData(
    todaySales: totalSales,
    totalProfit: totalProfit,
    totalOrders: totalOrders,
    itemsSold: itemsSold,
  );
}

/// ================== UI ==================
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

  // Future<void> pickDate() async {
  //   DateTime? picked = await showDatePicker(
  //     context: context,
  //     initialDate: selectedDate,
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime(2100),
  //   );
  //
  //   if (picked != null) {
  //     setState(() {
  //       selectedDate = picked;
  //     });
  //   }
  // }

  Future<void> pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryColor,        // Header background color
              onPrimary: Colors.white,     // Header text color
              onSurface: Colors.black,     // Body text color
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: primaryColor, // Button text color
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  @override
  void initState() {
    getMonthlyDetails();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade100,
      appBar: AppBar(
        title: const Text("Dashboard"),
      ),
      body: FutureBuilder(
        future: getDashboardData(selectedDate: selectedDate),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data as DashboardData;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                /// DATE DISPLAY
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMM yyyy').format(selectedDate),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedDate = DateTime.now();
                            });
                          },
                          child:Text("Today",style: TextStyle(color: primaryColor,fontWeight: FontWeight.bold),),
                        ),
                        IconButton(
                          icon: Icon(Icons.calendar_month_sharp,color: primaryColor,),
                          onPressed: pickDate,
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                /// BIG CARD
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [secondaryColor, primaryColor],
                      begin: AlignmentGeometry.topLeft,
                      end: AlignmentGeometry.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Sales",
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "₹${data.todaySales.toStringAsFixed(2)}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Profit ₹${data.totalProfit.toStringAsFixed(2)}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),

                // const SizedBox(height: 20),

                /// GRID
                // Row(
                //   spacing: 12,
                //   // runSpacing: 12,
                //   children:  [
                //     _card("Orders", data.totalOrders.toString(),
                //         Icons.receipt),
                //     _card("Items Sold", data.itemsSold.toString(),
                //         Icons.shopping_cart),
                //     _card("Profit",
                //         "₹${data.totalProfit.toStringAsFixed(2)}",
                //         Icons.trending_up),
                //     _card("Sales",
                //         "₹${data.todaySales.toStringAsFixed(2)}",
                //         Icons.currency_rupee),
                //   ],
                // ),
                // const SizedBox(height: 24),
                // const Divider(),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// MONTHLY SECTION
                            const Text(
                              "Daily Overview",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _monthlyRow(
                              "Bills: ",
                              data.totalOrders.toString(),
                              Colors.blue,
                            ),
                            const Divider(height: 8),
                            _monthlyRow(
                              "Sellings: ",
                              "₹${data.todaySales.toStringAsFixed(2)}",
                              Colors.blue,
                            ),
                            const Divider(height: 8),
                            _monthlyRow(
                              "Profit: ",
                              "₹${data.totalProfit.toStringAsFixed(2)}",
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 24),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// MONTHLY SECTION
                            Text(
                              "Current Monthly Overview: ${printDate(date: DateTime.now().toString(), format: "MMMM yyyy")}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 12),

                            _monthlyRow(
                              "Total Monthly Bills: ",
                              "${monthlyBills}",
                              Colors.blue,
                            ),
                            const Divider(height: 8),
                            _monthlyRow(
                              "Total Monthly Sales: ",
                              "₹${monthlySales.toStringAsFixed(2)}",
                              Colors.blue,
                            ),
                            const Divider(height: 8),
                            _monthlyRow(
                              "Total Monthly Profit: ",
                              "₹${monthlyProfit.toStringAsFixed(2)}",
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                /// Add this inside the Column in your FutureBuilder
                // const SizedBox(height: 24),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Top Selling Products of This Month",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        // Crucial inside SingleChildScrollView
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: topProducts.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final product = topProducts[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(
                                "${index + 1}",
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(product.name),
                            trailing: Text(
                              "${product.qty} sold",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                _buildSalesChart(salesTrend),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _card(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        // width: 200,
        height: 200,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blueGrey),
            const SizedBox(height: 10),
            Text(title),
            const SizedBox(height: 5),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Monthly Rows
  Widget _monthlyRow(String label, String value, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 15, color: Colors.grey)),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSalesChart(Map<int, double> dailySales) {
    List<FlSpot> spots = [];
    // Ensure we show all days of the month even if sales are 0
    for (int i = 1; i <= 31; i++) {
      spots.add(FlSpot(i.toDouble(), dailySales[i] ?? 0));
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.only(right: 20, top: 20, bottom: 10, left: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // Inside your Column...
          const Text(
            "Monthly Sales Trend",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1, // Show date every 5 days to avoid crowding
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: Colors.blue.withOpacity(0.1),
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
    DateTime now = DateTime.now();
    // Fetch Monthly Snapshot
    // Monthly Range
    DateTime startOfMonth = DateTime(now.year, now.month, 1);
    DateTime endOfMonth = DateTime(now.year, now.month + 1, 1);
    // Temporary map to store product quantities
    Map<String, int> productMap = {};
    QuerySnapshot monthlySnapshot = await FirebaseFirestore.instance
        .collection('sales')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .get();
    for (var doc in monthlySnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      List items = data['order'] ?? [];

      for (var item in items) {
        int qty = item['qty'] ?? 0;
        monthlyBills += 1;
        monthlySales += (item['selling_price'] ?? 0) * qty;
        monthlyProfit +=
            ((item['selling_price'] ?? 0) - (item['cost_price'] ?? 0)) * qty;
        // Aggregate product quantity
        productMap[item['name'] ?? "-"] =
            (productMap[item['name'] ?? 'Unknown'] ?? 0) + qty;
      }
      DateTime date = (data['date'] as Timestamp).toDate();
      int day = date.day;
      salesTrend[day] = (salesTrend[day] ?? 0) + data['total'];
    }
    // Convert Map to List and sort by quantity descending
    List<ProductSales> sortedProducts = productMap.entries
        .map((e) => ProductSales(e.key, e.value))
        .toList();
    sortedProducts.sort((a, b) => b.qty.compareTo(a.qty));
    topProducts = sortedProducts.take(10).toList();
    setState(() {});
  }
}

class ProductSales {
  final String name;
  final int qty;

  ProductSales(this.name, this.qty);
}
