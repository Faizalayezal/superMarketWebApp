import 'dart:async';
import 'package:input_quantity/input_quantity.dart';
import 'package:shivam_super_market/core/Textfield.dart';
import 'package:shivam_super_market/common_import.dart';
import 'package:shivam_super_market/core/helper_function.dart';
import 'package:shivam_super_market/core/services/printer_service.dart' show PrinterService;

class POSSaleScreen extends StatefulWidget {
  final String? docId;
  final Map<String, dynamic>? saleData;

  const POSSaleScreen({super.key, this.docId, this.saleData});

  @override
  _POSSaleScreenState createState() => _POSSaleScreenState();
}

class _POSSaleScreenState extends State<POSSaleScreen> {
  final PrinterService _printerService = PrinterService();
  DocumentSnapshot? _lastDocument; // Stores the last item of the current page
  bool _isLoading = false;
  bool _hasMore = true; // To stop fetching when the database is empty
  int _pageSize = 10; // Number of items per page
  ScrollController itemsScrollCount = ScrollController();
  ScrollController _scrollController = ScrollController();
  final FocusNode searchFocusNode = FocusNode();
  var searchController = TextEditingController();
  Timer? _debounce;
  String selectedPaymentMethod = "Cash";
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _extraPurchaseController = TextEditingController();
  // List<Map<String, double>> extraItems = [];

  @override
  void initState() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        fetchProduct(isLoadMore: true); // Load next page
      }
    });
    getCatList();
    fetchProduct();
    if (widget.docId != null) {
      cartItems = List<Map<String, dynamic>>.from(widget.saleData!['order']);
      selectedPaymentMethod = widget.saleData!['payment_method'] ?? "";
      calculateTotal();
    }
    super.initState();
  }

  @override
  void dispose() {
    _debounce?.cancel(); // Cancel timer
    searchController.dispose();
    super.dispose();
  }

  searchProduct() async {
    products.clear();
    _lastDocument = null; // Stores the last item of the current page
    _isLoading = false;
    _hasMore = true;
    if (searchController.text.trim().isEmpty) return fetchProduct();
    String text = searchController.text;

    try {
      List<Map<String, dynamic>> tempList = [];

      final collection = FirebaseFirestore.instance.collection("products");

      // 🔹 1. Barcode Search (Exact match - highest priority)
      var barcodeSnap = await collection
          .where("barcode", isEqualTo: text)
          .where("is_active", isEqualTo: true)
          .get();

      print("📦 Barcode results: ${barcodeSnap.docs.length}");

      // 🔹 2. Name Search (using sort_name for lowercase match)
      var nameSnap = await collection
          .where('sort_name', isGreaterThanOrEqualTo: text.toUpperCase())
          .where(
            'sort_name',
            isLessThanOrEqualTo: text.toUpperCase() + '\uf8ff',
          )
          .where("is_active", isEqualTo: true)
          .limit(20)
          .get();

      print("📝 Name results: ${nameSnap.docs.length}");

      // 🔹 3. Category Search
      var categorySnap = await collection
          .where("category", isEqualTo: text)
          .where("is_active", isEqualTo: true)
          .get();

      print("📂 Category results: ${categorySnap.docs.length}");

      // 🔥 Merge all results
      for (var doc in [
        ...barcodeSnap.docs,
        ...nameSnap.docs,
        ...categorySnap.docs,
      ]) {
        tempList.add(doc.data() as Map<String, dynamic>);
      }

      // 🔥 Remove duplicates using product ID
      final Map<String, Map<String, dynamic>> uniqueMap = {};

      for (var item in tempList) {
        if (item['id'] != null) {
          uniqueMap[item['id']] = item;
        }
      }

      print("✅ Final unique products: ${uniqueMap.length}");

      setState(() {
        products = uniqueMap.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      print("❌ Search Error: $e");
      setState(() => _isLoading = false);
    }
  }

  // List to store items added to the bill
  List<Map<String, dynamic>> cartItems = [];
  // Map<String, dynamic> extraCharges = {};

  // Example Product Data (In real app, fetch this from your Firestore fetchProduct)
  List<Map<String, dynamic>> products = [];

  String? selectedCategory;
  List<Map> categoryList = [];

  void getCatList() async {
    categoryList.clear();
    var res = await FirebaseFirestore.instance.collection("categories").get();
    res.docs.forEach((element) {
      categoryList.add(element.data());
    });
    if (mounted) setState(() {});
  }

  void addToCart(Map<String, dynamic> product) {

    // Ensure your product maps have an 'id' key from Firestore
    final String productId = product['id'];

    setState(() {
      // Search the cart for the specific ID
      int index = cartItems.indexWhere((item) => item['id'] == productId);

      if (index != -1) {
        // If found, just increment the quantity
        cartItems[index]['qty'] = cartItems[index]['qty'] + 1;
      } else {
        // If not found, add as a new entry with quantity 1
        // We use Map.of to ensure we aren't modifying the original reference
        cartItems.add(Map<String, dynamic>.from({...product, "qty": 1}));
        itemsScrollCount.animateTo(itemsScrollCount.position.maxScrollExtent, duration: Duration(milliseconds: 500), curve: Curves.linear);
      }
    });
  }

  String getPromotionMessage(Map item) {
    return "";
  }

  double calculateTotal() {
    num discount = num.tryParse(_discountController.text) ?? 0.0;
    num additionalCharges = num.tryParse(_extraPurchaseController.text) ?? 0.0;
    num totalSum = 0.0;
    totalSum = cartItems.fold(0.0, (sum, item) {
      double unitPrice = item['selling_price'] ?? 0.0;
      int qty = item['qty'] ?? 0;
      double itemTotal = 0.0;

      // CASE 1: Combo Pricing (e.g., 5 for 105)
      if (item['promotion'] == 'Combo' &&
          item['combo_qty'] != null &&
          qty >= int.parse(item['combo_qty'])) {
        int comboCount =
            int.tryParse("${qty ~/ int.parse(item['combo_qty'])}") ??
            0; // Remaining single items
        int remainingQty =
            int.tryParse("${qty % int.parse(item['combo_qty'])}") ??
            0; // Remaining single items
        double comboPrice = double.parse(item['combo_price'].toString());

        itemTotal = (comboCount * comboPrice) + (remainingQty * unitPrice);
      }
      // CASE 3: Standard Pricing
      else {
        itemTotal = qty * unitPrice;
      }

      return sum + itemTotal;
    });
    num a = totalSum - discount+additionalCharges;
    return a.toDouble();
  }

  double savedAmountTotal() {
    double totalSaved = 0;

    for (var item in cartItems) {
      double mrp = double.parse(item['mrp'].toString());
      double sellingPrice = double.parse(item['selling_price'].toString());
      int qty = int.parse(item['qty'].toString());

      totalSaved += (mrp - sellingPrice) * qty;
    }
    return totalSaved;
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [Text("$superMarketTitle - POS")],
        ),
        backgroundColor: Colors.blueGrey.shade200,
      ),
      backgroundColor: backGroundColor,
      body: Row(
        children: [
          // --- LEFT SIDE: SELECTED ITEMS (CART) ---
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blueGrey.shade50,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Text(
                      "Current Sale",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: itemsScrollCount,
                      padding: EdgeInsets.zero,
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        // final item = cartItems[index];
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: ListTile(
                                title: Row(
                                  children: [
                                    Container(
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle
                                        ),
                                        padding: EdgeInsets.all(8),
                                        child: Center(child: Text("${index+1}",style: TextStyle(fontWeight: FontWeight.bold,fontSize: 12),))),
                                    Text(" "+cartItems[index]['name']),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          "₹${cartItems[index]['selling_price']} x ",
                                        ),
                                        SizedBox(width: 12),
                                        InputQty(
                                          key: ValueKey(
                                            "${cartItems[index]['id']}_${cartItems[index]['qty']}",
                                          ),
                                          maxVal: 999,
                                          initVal: cartItems[index]['qty'],
                                          minVal: 1,
                                          steps: 1,
                                          onQtyChanged: (val) {
                                            cartItems[index]['qty'] = val;
                                            setState(() {});
                                          },
                                        ),
                                      ],
                                    ),

                                    /// 🔥 Promotion Message
                                    if (getPromotionMessage(
                                      cartItems[index],
                                    ).isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4),
                                        child: Text(
                                          getPromotionMessage(
                                            cartItems[index],
                                          ).toString(),
                                          maxLines: 2,
                                          style: TextStyle(
                                            color: Colors.green,
                                            overflow: TextOverflow.ellipsis,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Text(
                                  "₹${getLineItemTotal(cartItems[index])}",
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                cartItems.removeAt(index);
                                setState(() {});
                              },
                              icon: Icon(Icons.close, color: Colors.red),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(20),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text("Payment method:"),
                        SizedBox(height: 4),
                        Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    borderRadius: BorderRadius.circular(24),
                                    dropdownColor: Colors.white,
                                    isDense: true,
                                    value: selectedPaymentMethod,
                                    items: const [
                                      DropdownMenuItem(
                                        value: "Cash",
                                        child: Text("Cash"),
                                      ),
                                      DropdownMenuItem(
                                        value: "Online",
                                        child: Text("Online"),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() => selectedPaymentMethod = val!);
                                    },
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                // New Toggle for Personal Use
                                Expanded(
                                  child: _buildTextField(
                                    _discountController,
                                    "Discount",
                                    onChange: (v) {
                                      calculateTotal();
                                    },
                                  ),
                                ),
                                SizedBox(width: 12),
                                // New Toggle for Personal Use
                                Expanded(
                                  child: _buildTextField(
                                    _extraPurchaseController,
                                    "Misc. Expense",
                                    onChange: (v) {
                                      calculateTotal();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Total:", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            Text("₹${calculateTotal()}", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green[700])),
                          ],
                        ),
                        SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  processCheckOut();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  minimumSize: Size(double.infinity, 50),
                                ),
                                child: Text(
                                  "Save",
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            IconButton(
                              onPressed: () async {
                                double finalTotal = calculateTotal();
                                double savedAmount = savedAmountTotal();
                                List<Map<String, dynamic>> itemsToPrint =
                                    List.from(
                                      cartItems,
                                    ); // Copy items before clearing

                                String invId =
                                    "INV_${printDate(date: DateTime.now().toString(), format: "ddmmyyhhmmss")}";
                                try {
                                  await _printerService.printReceipt(
                                    invId: invId,
                                    cartItems: itemsToPrint,
                                    total: finalTotal,
                                    savedOnMRP: savedAmount,
                                    paymentMethod: selectedPaymentMethod,
                                    extraCharges: {},
                                  );
                                } catch (e) {}
                              },
                              icon: Icon(Icons.print_outlined),
                            ),
                            IconButton(
                                onPressed:
                                    (){
                                      // processCheckOut();
                                      // 1. Attempt to print
                                      double finalTotal = calculateTotal();
                                      double savedAmount = savedAmountTotal();
                                      List<Map<String, dynamic>> itemsToPrint =
                                      List.from(
                                        cartItems,
                                      ); // Copy items before clearing

                                      String invId =
                                          "INV_${printDate(date: DateTime.now().toString(), format: "ddmmyyhhmmss")}";

                                  String itemsText = itemsToPrint.asMap().entries.map((entry) {
                                    int index = entry.key + 1; // Sr No starts from 1
                                    var item = entry.value;
                                    return "$index. ${item['name']} x ${item['qty']} = ₹${item['selling_price']}";
                                  }).join("\n");
                                  String billMessage = """
*${superMarketTitle}*
$billAddress
$telNumber
------------------------------
Bill No: ${invId}
Date: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}
Payment: ${selectedPaymentMethod}
------------------------------
*Items:*

$itemsText
------------------------------
*TOTAL: ₹${finalTotal.toStringAsFixed(2)}*
------------------------------
*Saved ₹${savedAmount.toStringAsFixed(2)} on MRP*
------------------------------
Thank you for shopping!
""";

                                  showWhatsAppDialog(context, billMessage);
                                }, icon: Icon(Icons.message)),
                               IconButton(
                                onPressed:
                                    (){
                                  showDialog(context: context, builder: (context) {
                                    return Stack(
                                      children: [
                                        Center(
                                          child:Image.asset("assets/logo.png",),
                                        ),
                                        Positioned(
                                          top: 24,
                                          right: 24,
                                          child: IconButton(onPressed: () {
                                            Navigator.of(context).pop();
                                          }, icon: Icon(Icons.close_outlined,color: Colors.red,)),
                                        )
                                      ],
                                    );
                                  },);
                                }, icon: Icon(Icons.qr_code_sharp)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          VerticalDivider(width: 1),

          // --- RIGHT SIDE: PRODUCT LISTING ---
          Expanded(
            flex: 3,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocusNode,
                    autofocus: true,
                    onSubmitted: (value) async {
                      try {
                        final result = await FirebaseFirestore.instance
                            .collection("products")
                            .where("barcode", isEqualTo: searchController.text)
                            .get();
                        result.docs.forEach((element) {
                          addToCart(element.data());
                          searchController.clear();
                        });
                        // 🔥 Keep focus after submit
                        FocusScope.of(context).requestFocus(searchFocusNode);
                      } catch (e) {}
                    },
                    onChanged: (value) {
                      // 1. If there's an active timer, cancel it
                      if (_debounce?.isActive ?? false) _debounce!.cancel();
                      // 2. Set a new timer
                      _debounce = Timer(const Duration(milliseconds: 500), () {
                        // 3. This only runs if the user stops typing for 500ms
                        searchProduct();
                      });
                      // searchProduct();
                    },
                    decoration: InputDecoration(
                      hintText: "Search Product...",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 40,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            selectedCategory = null;
                            fetchProduct();
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            margin: EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: selectedCategory == null
                                  ? primaryColor
                                  : null,
                              // border: Border.all(color: primaryColor),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                "All",
                                style: TextStyle(
                                  fontWeight: selectedCategory == null
                                      ? FontWeight.bold
                                      : null,
                                  color: selectedCategory == null
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(color: Colors.blueGrey, height: 30, width: 1),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 0.0,
                            ),
                            itemCount: categoryList.length,
                            itemBuilder: (context, index) {
                              return GestureDetector(
                                onTap: () {
                                  selectedCategory =
                                      categoryList[index]['category'];
                                  fetchProduct();
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  margin: EdgeInsets.symmetric(horizontal: 8),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: primaryColor),
                                    borderRadius: BorderRadius.circular(12),
                                    color:
                                        selectedCategory ==
                                            categoryList[index]['category']
                                        ? primaryColor
                                        : null,
                                  ),
                                  child: Center(
                                    child: Text(
                                      categoryList[index]['category']
                                          .toString(),
                                      style: TextStyle(
                                        fontWeight:
                                            selectedCategory ==
                                                categoryList[index]['category']
                                            ? FontWeight.bold
                                            : null,
                                        color:
                                            selectedCategory ==
                                                categoryList[index]['category']
                                            ? Colors.white
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Product Grid
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length + (_hasMore ? 1 : 0),
                    // Handle pagination loader
                    itemBuilder: (context, index) {
                      if (index == products.length) {
                        if (products.length == 0) {
                          return Text("No Data Found");
                        }
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            onTap: () => addToCart(product),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              product['name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Barcode: ${product['barcode'] ?? 'N/A'}",
                            ),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "₹${product['selling_price']}",
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  "Stock: ${product['stock']}",
                                  style: TextStyle(
                                    color: (product['stock'] ?? 0) < 10
                                        ? Colors.red
                                        : Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void fetchProduct({bool isLoadMore = false}) async {
    if (_isLoading || (isLoadMore && !_hasMore)) return;

    setState(() => _isLoading = true);

    // Reset when NOT loading more (new category / refresh)
    if (!isLoadMore) {
      products.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    try {
      Query query = FirebaseFirestore.instance.collection("products");

      // Base condition
      query = query.where("is_active", isEqualTo: true);

      // Category condition
      if (selectedCategory != null && selectedCategory!.isNotEmpty) {
        query = query.where("category", isEqualTo: selectedCategory);
      }

      // Order + Pagination
      query = query.orderBy("name").limit(_pageSize);

      if (isLoadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      // Execute query
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;

        setState(() {
          for (var doc in querySnapshot.docs) {
            products.add(doc.data() as Map<String, dynamic>);
          }
        });
      }

      // Check if more data available
      if (querySnapshot.docs.length < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      print("Pagination Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }


  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // User cannot tap outside to close it
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                const Text(
                  "Processing Sale...",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void processCheckOut() async {
    if(cartItems.isEmpty)return toast("Enter Valid Entries");
    if (widget.docId != null) {
      double finalTotal = calculateTotal();
      double savedAmount = savedAmountTotal();
      String invId = widget.saleData!['inv_id'];
      // 🔥 1. Get OLD DATA
      DocumentSnapshot oldDoc = await FirebaseFirestore.instance
          .collection("sales")
          .doc(widget.docId)
          .get();

      List oldOrders = (oldDoc.data() as Map)['order'] ?? [];

      // 🔥 2. CREATE MAP (id -> qty)
      Map<String, num> oldQtyMap = {};
      for (var item in oldOrders) {
        oldQtyMap[item['id']] = (item['qty'] ?? 0);
      }

      Map<String, num> newQtyMap = {};
      double billProfit=0.0;
      for (var item in cartItems) {
        newQtyMap[item['id']] = (item['qty'] ?? 0);
        double sellPrice=double.tryParse(item['selling_price'].toString())??0.0;
        double costPrice=double.tryParse(item['cost_price'].toString())??0.0;
        double profit=sellPrice-costPrice;
        double totalProfit=profit*(item['qty'] as num);
        billProfit+=totalProfit;
      }

      // _extraPurchaseController
      // 🔥 3. UPDATE SALE
      await FirebaseFirestore.instance
          .collection("sales")
          .doc(widget.docId)
          .update({
            "order": cartItems,
            "total": finalTotal,
            "saved_on_mrp": savedAmount,
            "date": Timestamp.fromDate(DateTime.now()),
            "inv_id": invId,
            "extra_purchase_amount": double.tryParse(_extraPurchaseController.text)??0.0,
            "profit": billProfit,
            "payment_method": selectedPaymentMethod,
          });

      // 🔥 4. HANDLE STOCK DIFFERENCE
      Set<String> allProductIds = {...oldQtyMap.keys, ...newQtyMap.keys};

      for (var productId in allProductIds) {
        num oldQty = oldQtyMap[productId] ?? 0;
        num newQty = newQtyMap[productId] ?? 0;

        num diff = newQty - oldQty;

        if (diff != 0) {
          await FirebaseFirestore.instance
              .collection("products")
              .doc(productId)
              .update({'stock': FieldValue.increment(-diff)});
        }
      }
    } else {
      double finalTotal = calculateTotal();
      double savedAmount = savedAmountTotal();
      List<Map<String, dynamic>> itemsToPrint = List.from(
        cartItems,
      ); // Copy items before clearing
      _showLoadingDialog(context);
      String invId =
          "INV_${printDate(date: DateTime.now().toString(), format: "ddmmyyhhmmss")}";
      FirebaseFirestore.instance
          .collection("sales")
          .add({
            "order": cartItems,
            "total": finalTotal,
            "saved_on_mrp": savedAmount,
            "date": Timestamp.fromDate(DateTime.now()),
            "inv_id": invId,
            "payment_method": selectedPaymentMethod,
          })
          .then((value) async {
            for (var element in cartItems) {
              await FirebaseFirestore.instance
                  .collection("products")
                  .doc(element['id'])
                  .update({
                    'stock': FieldValue.increment(-(element['qty'] as num)),
                  });
            }
            toast("Bill Saved");
            // 4. Success! Close Loader and Reset UI
            Navigator.of(context).pop(); // This closes the Loading Dialog
            // 2. Clear UI
            setState(() {
              cartItems.clear();
              _discountController.text="";
              _extraPurchaseController.text="";
            });
          });
    }
  }

  double getLineItemTotal(Map item) {
    double unitPrice = (item['selling_price'] ?? 0).toDouble();
    int qty = item['qty'] ?? 0;
    return qty * unitPrice;
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isNumber = false,
    int maxLines = 1,
    bool? optional,
    bool? autoFocus,
    var onChange,
  }) {
    return TextFormField(
      autofocus: autoFocus ?? false,
      controller: controller,
      inputFormatters: [if (isNumber) FilteringTextInputFormatter.digitsOnly],
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onChanged: (value) {
        setState(() {
          onChange(value);
        });
      },
    );
  }

  Future<Map<String, String>?> showExtraChargeDialog(BuildContext context) async {
    TextEditingController titleController = TextEditingController();
    TextEditingController valueController = TextEditingController();

    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text("Add Extra Purchase"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: "Title",
                  hintText: "e.g. Delivery Charge",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: valueController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: "Amount",
                  hintText: "e.g. 50",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: Text("Cancel"),
            ),
            MaterialButton(
              color: primaryColor,
              shape: RoundedRectangleBorder(

              ),
              onPressed: () {
                if (titleController.text.trim().isEmpty ||
                    valueController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter all fields")),
                  );
                  return;
                }

                Navigator.pop(context, {
                  "title": titleController.text.trim(),
                  "value": valueController.text.trim(),
                });
              },
              child: Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddProductDialog({var onSave}) async {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController amountController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Extra Charges'),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Prevents the dialog from taking full screen
            children: [
              TextField(
                autofocus: true,
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Product Title',
                  hintText: 'e.g. Wireless Mouse',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number, // Opens numeric keyboard
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  hintText: '0.00',
                  prefixText: '',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), // Close without saving
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                // 2. Access the data using .text
                final String title = titleController.text;
                final String amount = amountController.text;

                if (title.isNotEmpty && amount.isNotEmpty) {
                  print('Product: $title, Amount: $amount');

                  // Perform your logic here (e.g., add to list or database)

                  Navigator.pop(context); // Close dialog
                  onSave(title,amount);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

}
