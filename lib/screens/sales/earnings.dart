import 'package:shivam_super_market/common_import.dart';
import 'package:shivam_super_market/core/helper_function.dart';
import 'package:shivam_super_market/core/services/printer_service.dart' show PrinterService;
import 'package:shivam_super_market/models/sales_model.dart';
import 'package:shivam_super_market/screens/menu/pos_sale_screen.dart';

class PaginatedSalesScreen extends StatefulWidget {
  @override
  _PaginatedSalesScreenState createState() => _PaginatedSalesScreenState();
}

class _PaginatedSalesScreenState extends State<PaginatedSalesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  List<DocumentSnapshot> _salesDocs = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _documentLimit = 15; // Number of sales per page
  DocumentSnapshot? _lastDocument;
  DateTimeRange? selectedDateRange;

  @override
  void initState() {
    super.initState();
    _fetchSales(); // Initial load

    // Listen to scroll to trigger "Load More"
    _scrollController.addListener(() {
      double maxScroll = _scrollController.position.maxScrollExtent;
      double currentScroll = _scrollController.position.pixels;
      double delta = 200.0; // Trigger load when 200px from bottom

      if (maxScroll - currentScroll <= delta) {
        _fetchSales();
      }
    });
  }

  Future<void> _fetchSales({bool isRefresh = false}) async {
    if (_isLoading || (!_hasMore && !isRefresh)) return;

    if (isRefresh) {
      _salesDocs.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    setState(() => _isLoading = true);

    Query query = _firestore
        .collection('sales')
        .orderBy('date', descending: true)
        .limit(_documentLimit);

    // ✅ APPLY DATE FILTER
    if (selectedDateRange != null) {
      query = query
          .where('date',
          isGreaterThanOrEqualTo:
          Timestamp.fromDate(selectedDateRange!.start))
          .where('date',
          isLessThanOrEqualTo: Timestamp.fromDate(
              selectedDateRange!.end.add(const Duration(days: 1))));
    }

    if (_lastDocument != null && !isRefresh) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.length < _documentLimit) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;

        setState(() {
          _salesDocs.addAll(querySnapshot.docs);
        });
      }
    } catch (e) {
      print("Error fetching sales: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: selectedDateRange,
    );

    if (picked != null) {
      setState(() {
        selectedDateRange = picked;
      });

      // 🔥 REFRESH DATA WITH FILTER
      _fetchSales(isRefresh: true);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade100,
      appBar: AppBar(
        title: Text("Sales History"),backgroundColor: Colors.blueGrey.shade100,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  selectedDateRange == null
                      ? "All Dates"
                      : "${DateFormat('dd MMM yyyy').format(selectedDateRange!.start)}"
                      " - "
                      "${DateFormat('dd MMM yyyy').format(selectedDateRange!.end)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 12,),
                IconButton(
                  onPressed: _pickDateRange,
                  icon: Icon(Icons.date_range),
                ),
              ],
            ),
          )
        ],
      ),
      body: _salesDocs.isEmpty && _isLoading
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
        controller: _scrollController,
        itemCount: _salesDocs.length + (_hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _salesDocs.length) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final sale = SaleModel.fromFirestore(_salesDocs[index]);

          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ExpansionTile(
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                      onPressed:
                      (){
                        String itemsText = sale.orders.asMap().entries.map((entry) {
                          int index = entry.key + 1; // Sr No starts from 1
                          var item = entry.value;
                          return "$index. ${item['name']} x ${item['qty']} = ₹${item['selling_price']}";
                        }).join("\n");
                        String billMessage = """
*${superMarketTitle}*
$billAddress
$telNumber
------------------------------
Bill No: ${sale.invId}
Date: ${DateFormat('dd-MM-yyyy HH:mm').format(sale.date)}
Payment: ${sale.paymentMethod}
------------------------------
*Items:*

$itemsText
------------------------------
*TOTAL: ₹${sale.total.toStringAsFixed(2)}*
------------------------------
*Saved ₹${sale.savedOnMRP.toStringAsFixed(2)} on MRP*
------------------------------
Thank you for shopping!
""";

                        showWhatsAppDialog(context, billMessage);
                      }, icon: Icon(Icons.message)),
                  IconButton(onPressed: ()  async{
                    bool confirm = await showDeleteDialog(context);
                    if(confirm){
                      DocumentSnapshot<Map<String, dynamic>> res=await _firestore
                          .collection('sales').doc(sale.id).get();
                      if(res.data()!=null){
                        Map<String, dynamic> invoiceData = res.data()!;
                          for (var item in invoiceData['order']) {
                          final productId = item['id'];
                          final qty = item['qty'];

                          final productRef =
                          FirebaseFirestore.instance.collection('products').doc(productId);

                          await FirebaseFirestore.instance.runTransaction((transaction) async {
                            final snapshot = await transaction.get(productRef);

                            if (!snapshot.exists) return;

                            final currentStock = snapshot['stock'] ?? 0;

                            final updatedStock = currentStock + qty;

                            transaction.update(productRef, {
                              'stock': updatedStock,
                            });
                          });
                          _firestore
                              .collection('sales').doc(sale.id).delete();
                          _salesDocs.removeAt(index);
                          setState(() {

                          });
                        }
                      }


                      // final orderList = invoiceData['order'] as List;
                      //
                      // for (var item in orderList) {
                      //   final productId = item['id'];
                      //   final qty = item['qty'];
                      //
                      //   final productRef =
                      //   FirebaseFirestore.instance.collection('products').doc(productId);
                      //
                      //   await FirebaseFirestore.instance.runTransaction((transaction) async {
                      //     final snapshot = await transaction.get(productRef);
                      //
                      //     if (!snapshot.exists) return;
                      //
                      //     final currentStock = snapshot['stock'] ?? 0;
                      //
                      //     final updatedStock = currentStock + qty;
                      //
                      //     transaction.update(productRef, {
                      //       'stock': updatedStock,
                      //     });
                      //   });
                      // }
                    }
                  }, icon: Icon(Icons.delete)),
                  IconButton(onPressed: ()  {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => POSSaleScreen(
                          docId: _salesDocs[index].id,
                          saleData: sale.toJson(),
                        ),
                      ),
                    );
                  }, icon: Icon(Icons.copy)),

                  IconButton(onPressed: ()  async{
                    await PrinterService().printReceipt(
                      invId: sale.invId,
                      cartItems: sale.orders,
                      savedOnMRP: sale.savedOnMRP,
                      total: sale.total,
                      paymentMethod: sale.paymentMethod,
                      extraCharges: {},
                    );
                  }, icon: Icon(Icons.print)),

                  Icon(Icons.keyboard_arrow_down_rounded)
                ],
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade50,
                child: Icon(Icons.receipt, color: Colors.blue),
              ),
              title: Text("Total: ₹${sale.total}", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("${DateFormat('dd MMM, hh:mm a').format(sale.date)} • ${sale.paymentMethod}"),
              children: [
                ...sale.orders.map((item) => ListTile(
                  title: Text(item['name'] ?? 'Unknown'),
                  trailing: Text("₹${item['selling_price']} x ${item['qty']}"),
                )).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }



}
