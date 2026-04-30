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

// ✅ FIX 3: Add AutomaticKeepAliveClientMixin
// This keeps the widget alive inside IndexedStack even when not visible.
// Without this, Flutter may still dispose the widget to free memory.
class _POSSaleScreenState extends State<POSSaleScreen>
    with AutomaticKeepAliveClientMixin {

  // ✅ FIX 3: Must override wantKeepAlive and return true
  @override
  bool get wantKeepAlive => true;

  final PrinterService _printerService = PrinterService();
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 10;
  final ScrollController _itemsScrollCtrl = ScrollController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  String _selectedPaymentMethod = "Cash";
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _extraPurchaseController =
  TextEditingController();
  List<Map<String, dynamic>> cartItems = [];
  List<Map<String, dynamic>> products = [];
  String? selectedCategory;
  List<Map> categoryList = [];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _fetchProduct(isLoadMore: true);
      }
    });
    _getCatList();
    _fetchProduct();
    if (widget.docId != null) {
      cartItems =
      List<Map<String, dynamic>>.from(widget.saleData!['order']);
      _selectedPaymentMethod = widget.saleData!['payment_method'] ?? "";
      calculateTotal();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    _itemsScrollCtrl.dispose();
    super.dispose();
  }

  void _getCatList() async {
    categoryList.clear();
    final res =
    await FirebaseFirestore.instance.collection("categories").get();
    for (var e in res.docs) {
      categoryList.add(e.data());
    }
    if (mounted) setState(() {});
  }

  Future<void> _searchProduct(String text) async {
    final query = text.trim();

    if (query.isEmpty) {
      return _fetchProduct();
    }

    setState(() {
      _isLoading = true;
      products.clear();
    });

    try {
      final queryText = query.toUpperCase();

      final collection = FirebaseFirestore.instance.collection("products");

      // 🔥 MAIN SEARCH
      final nameSnap = await collection
          .where("is_active", isEqualTo: true)
          .orderBy("sort_name")
          .startAt([queryText])
          .endAt([queryText + '\uf8ff'])
          .limit(20)
          .get();

      // 🔥 BARCODE SEARCH
      final barcodeSnap = await collection
          .where("barcode", isEqualTo: query)
          .where("is_active", isEqualTo: true)
          .get();

      // 🔥 MERGE + REMOVE DUPLICATE
      final Map<String, Map<String, dynamic>> unique = {};

      for (var doc in [...nameSnap.docs, ...barcodeSnap.docs]) {
        unique[doc.id] = doc.data();
      }

      setState(() {
        products = unique.values.toList();
        _hasMore = false;
      });

    } catch (e, st) {
      debugPrint("❌ Search Error: $e");
      debugPrintStack(stackTrace: st);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
  Future<void> _fallbackSearch(String query) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("products")
          .where("is_active", isEqualTo: true)
          .limit(50)
          .get();

      final lower = query.toLowerCase();

      final filtered = snap.docs.where((doc) {
        final name = (doc['name'] ?? "").toString().toLowerCase();
        return name.contains(lower);
      }).map((e) => e.data()).toList();

      setState(() {
        products = filtered;
      });

    } catch (e) {
      debugPrint("❌ Fallback Error: $e");
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    final String productId = product['id'];
    setState(() {
      int index = cartItems.indexWhere((item) => item['id'] == productId);
      if (index != -1) {
        cartItems[index]['qty'] = cartItems[index]['qty'] + 1;
      } else {
        cartItems.add(Map<String, dynamic>.from({...product, "qty": 1}));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_itemsScrollCtrl.hasClients) {
            _itemsScrollCtrl.animateTo(
              _itemsScrollCtrl.position.maxScrollExtent,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  double calculateTotal() {
    final num discount = num.tryParse(_discountController.text) ?? 0.0;
    final num extra = num.tryParse(_extraPurchaseController.text) ?? 0.0;
    num total = cartItems.fold(0.0, (sum, item) {
      final double unitPrice = item['selling_price'] ?? 0.0;
      final int qty = item['qty'] ?? 0;
      double itemTotal = 0;
      if (item['promotion'] == 'Combo' &&
          item['combo_qty'] != null &&
          qty >= int.parse(item['combo_qty'])) {
        final int comboCount = qty ~/ int.parse(item['combo_qty']);
        final int remaining = qty % int.parse(item['combo_qty']);
        final double comboPrice =
        double.parse(item['combo_price'].toString());
        itemTotal = (comboCount * comboPrice) + (remaining * unitPrice);
      } else {
        itemTotal = qty * unitPrice;
      }
      return sum + itemTotal;
    });
    return (total - discount + extra).toDouble();
  }

  double _savedAmountTotal() {
    double saved = 0;
    for (var item in cartItems) {
      final double mrp = double.parse(item['mrp'].toString());
      final double sp = double.parse(item['selling_price'].toString());
      final int qty = int.parse(item['qty'].toString());
      saved += (mrp - sp) * qty;
    }
    return saved;
  }

  double _getLineItemTotal(Map item) {
    final double price = (item['selling_price'] ?? 0).toDouble();
    final int qty = item['qty'] ?? 0;
    return qty * price;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX 3: super.build() REQUIRED when using AutomaticKeepAliveClientMixin
    super.build(context);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          '$superMarketTitle — POS',
          style: const TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined, color: Colors.white),
            tooltip: 'Print',
            onPressed: () async {
              try {
                await _printerService.printReceipt(
                  invId:
                  "INV_${printDate(date: DateTime.now().toString(), format: "ddmmyyhhmmss")}",
                  cartItems: List.from(cartItems),
                  total: calculateTotal(),
                  savedOnMRP: _savedAmountTotal(),
                  paymentMethod: _selectedPaymentMethod,
                  extraCharges: {},
                );
              } catch (_) {}
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;
        return isMobile ? _buildMobileBody() : _buildDesktopBody();
      }),
    );
  }

  Widget _buildDesktopBody() {
    return Row(
      children: [
        SizedBox(width: 380, child: _cartPanel()),
        const VerticalDivider(width: 1),
        Expanded(child: _productsPanel()),
      ],
    );
  }

  Widget _buildMobileBody() {
    return Stack(
      children: [
        _productsPanel(),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _mobileCartSummary(),
        ),
      ],
    );
  }

  Widget _mobileCartSummary() {
    final total = calculateTotal();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${cartItems.length} items',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            const Spacer(),
            Text(
              '₹${total.toStringAsFixed(2)}',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryColor),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: () => _showCartSheet(),
              style: ElevatedButton.styleFrom(
                backgroundColor: secondaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('View Cart'),
            ),
          ],
        ),
      ),
    );
  }

  void _showCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (_, ctrl) => _cartPanel(scrollCtrl: ctrl),
      ),
    );
  }

  Widget _cartPanel({ScrollController? scrollCtrl}) {
    return StatefulBuilder(
      builder: (context, setSheetState) {
        void updateCart(VoidCallback fn) {
          setState(fn);
          setSheetState(() {});
        }

        return Container(
          color: const Color(0xFFF8FAFC),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                color: Colors.white,
                child: Row(
                  children: [
                    Icon(Icons.shopping_cart_rounded, color: primaryColor),
                    const SizedBox(width: 8),
                    Text('Current Sale',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor)),
                    const Spacer(),
                    if (cartItems.isNotEmpty)
                      TextButton(
                        onPressed: () => updateCart(() => cartItems.clear()),
                        child: const Text('Clear',
                            style: TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: cartItems.isEmpty
                    ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.shopping_cart_outlined,
                          size: 60,
                          color: Colors.grey.withOpacity(0.4)),
                      const SizedBox(height: 12),
                      const Text('Cart is empty',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
                    : ListView.builder(
                  controller: scrollCtrl ?? _itemsScrollCtrl,
                  padding: const EdgeInsets.all(12),
                  itemCount: cartItems.length,
                  itemBuilder: (_, index) =>
                      _cartItem(index, onUpdate: updateCart),
                ),
              ),
              _checkoutPanel(onUpdate: updateCart),
            ],
          ),
        );
      },
    );
  }

  Widget _cartItem(int index,
      {required void Function(VoidCallback) onUpdate}) {
    final item = cartItems[index];
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.15),
            ),
            child: Center(
              child: Text('${index + 1}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700])),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'],
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Text('₹${item['selling_price']} × ',
                        style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
                    InputQty(
                      key: ValueKey('${item['id']}_${item['qty']}'),
                      maxVal: 999,
                      initVal: item['qty'],
                      minVal: 1,
                      steps: 1,
                      onQtyChanged: (val) {
                        onUpdate(() => cartItems[index]['qty'] = val);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.red, size: 18),
                onPressed: () => onUpdate(() => cartItems.removeAt(index)),
              ),
              const SizedBox(height: 6),
              Text(
                '₹${_getLineItemTotal(item).toStringAsFixed(0)}',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                    fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _checkoutPanel({void Function(VoidCallback)? onUpdate}) {
    void update(VoidCallback fn) =>
        onUpdate != null ? onUpdate(fn) : setState(fn);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedPaymentMethod,
                  isDense: true,
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  decoration: InputDecoration(
                    labelText: 'Payment',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: "Cash", child: Text("Cash")),
                    DropdownMenuItem(
                        value: "Online", child: Text("Online")),
                  ],
                  onChanged: (v) => update(() => _selectedPaymentMethod = v!),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                  child: _miniTextField(_discountController, 'Discount')),
              const SizedBox(width: 8),
              Expanded(
                  child: _miniTextField(_extraPurchaseController, 'Misc.')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL',
                  style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(
                '₹${calculateTotal().toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _processCheckOut,
                  icon: const Icon(Icons.save_rounded, size: 18),
                  label: const Text('Save Bill'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _iconBtn(Icons.print_outlined, () async {
                try {
                  await _printerService.printReceipt(
                    invId:
                    "INV_${printDate(date: DateTime.now().toString(), format: "ddmmyyhhmmss")}",
                    cartItems: List.from(cartItems),
                    total: calculateTotal(),
                    savedOnMRP: _savedAmountTotal(),
                    paymentMethod: _selectedPaymentMethod,
                    extraCharges: {},
                  );
                } catch (_) {}
              }),
              const SizedBox(width: 4),
              _iconBtn(Icons.message_outlined, () {
                final total = calculateTotal();
                final saved = _savedAmountTotal();
                final invId =
                    "INV_${printDate(date: DateTime.now().toString(), format: "ddmmyyhhmmss")}";
                final itemsText = cartItems
                    .asMap()
                    .entries
                    .map((e) =>
                '${e.key + 1}. ${e.value['name']} x ${e.value['qty']} = ₹${e.value['selling_price']}')
                    .join('\n');
                final msg =
                    '*$superMarketTitle*\n$billAddress\n$telNumber\n'
                    '------------------------------\n'
                    'Bill No: $invId\nDate: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}\n'
                    'Payment: $_selectedPaymentMethod\n'
                    '------------------------------\n*Items:*\n$itemsText\n'
                    '------------------------------\n*TOTAL: ₹${total.toStringAsFixed(2)}*\n'
                    '------------------------------\n*Saved ₹${saved.toStringAsFixed(2)} on MRP*\n'
                    '------------------------------\nThank you for shopping!';
                showWhatsAppDialog(context, msg);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: const Color(0xFFF1F5F9),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Icon(icon, size: 20, color: primaryColor),
        ),
      ),
    );
  }

  Widget _miniTextField(TextEditingController ctrl, String label) {
    return TextFormField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border:
        OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        isDense: true,
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  // ══════════════════════════════════════════════════════════
  // Products panel
  // ✅ FIX 4: Category chip — selectedCategory must be set INSIDE setState
  //           before calling _fetchProduct(), otherwise Firestore query runs
  //           with the OLD value of selectedCategory
  // ══════════════════════════════════════════════════════════
  Widget _productsPanel() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            onSubmitted: (_) async {
              try {
                final result = await FirebaseFirestore.instance
                    .collection("products")
                    .where("barcode",
                    isEqualTo: _searchController.text)
                    .where("is_active", isEqualTo: true)
                    .get();
                for (var doc in result.docs) {
                  _addToCart(doc.data());
                }
                _searchController.clear();
                FocusScope.of(context).requestFocus(_searchFocusNode);
              } catch (_) {}
            },
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();

              _debounce = Timer(
                const Duration(milliseconds: 400),
                    () => _searchProduct(value), // ✅ value pass karo
              );
            },
            decoration: InputDecoration(
              hintText: 'Search by name / barcode...',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                const BorderSide(color: Color(0xFFE0E8F0), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide(color: primaryColor, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
            ),
          ),
        ),
        // Category chips
        SizedBox(
          height: 40,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                // ✅ FIX 4: "All" chip — set selectedCategory=null inside setState
                // then call _fetchProduct AFTER setState completes
                _categoryChip('All', selectedCategory == null, () {
                  setState(() => selectedCategory = null);
                  _fetchProduct();
                }),
                ...categoryList.map((cat) => _categoryChip(
                  cat['category'].toString(),
                  selectedCategory == cat['category'],
                      () {
                    setState(() => selectedCategory = cat['category']);
                    _fetchProduct();
                  },
                )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: products.length + (_hasMore ? 1 : 0),
            itemBuilder: (_, index) {
              if (index == products.length) {
                if (products.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('No products found',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              return _productCard(products[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _categoryChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? primaryColor : const Color(0xFFDDE4ED)),
          boxShadow: selected
              ? [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            )
          ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
            selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  Widget _productCard(Map<String, dynamic> product) {
    final int stock = product['stock'] ?? 0;
    final bool lowStock = stock < 10;
    return Card(
      elevation: 0,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE8EDF2), width: 1),
      ),
      child: ListTile(
        onTap: () => _addToCart(product),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        title: Text(
          product['name'],
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          'Barcode: ${product['barcode'] ?? 'N/A'}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '₹${product['selling_price']}',
              style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (lowStock)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('Low',
                        style: TextStyle(
                            color: Colors.red, fontSize: 10)),
                  ),
                Text(
                  'Stock: $stock',
                  style: TextStyle(
                      color:
                      lowStock ? Colors.red : Colors.grey[600],
                      fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchProduct({bool isLoadMore = false}) async {
    if (_isLoading || (isLoadMore && !_hasMore)) return;

    setState(() => _isLoading = true);

    try {
      Query<Map<String, dynamic>> query =
      FirebaseFirestore.instance.collection("products");

      // 🔹 Base filter
      query = query.where("is_active", isEqualTo: true);

      // 🔹 Category filter
      if (selectedCategory != null && selectedCategory!.trim().isNotEmpty) {
        final category = selectedCategory!.trim();
        query = query.where("category", isEqualTo: category);
      }

      // 🔹 Sorting (IMPORTANT: requires index)
      query = query.orderBy("name");

      // 🔹 Pagination
      query = query.limit(_pageSize);

      if (isLoadMore && _lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snap = await query.get();

      // 🔹 First load reset
      if (!isLoadMore) {
        products.clear();
      }

      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;

        final newProducts = snap.docs
            .map((doc) => doc.data())
            .toList();

        setState(() {
          products.addAll(newProducts);
        });
      }

      // 🔹 Check end
      if (snap.docs.length < _pageSize) {
        _hasMore = false;
      }
    } catch (e, st) {
      debugPrint("❌ Firestore Fetch Error: $e");
      debugPrintStack(stackTrace: st);

      // Optional: show UI error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to load products")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Processing Sale...'),
            ],
          ),
        ),
      ),
    );
  }

  void _processCheckOut() async {
    if (cartItems.isEmpty) return toast("Add items to cart");
    if (widget.docId != null) {
      final double finalTotal = calculateTotal();
      final double savedAmount = _savedAmountTotal();
      final String invId = widget.saleData!['inv_id'];
      final oldDoc = await FirebaseFirestore.instance
          .collection("sales")
          .doc(widget.docId)
          .get();
      final List oldOrders =
          (oldDoc.data() as Map)['order'] ?? [];
      final Map<String, num> oldQtyMap = {};
      for (var item in oldOrders) {
        oldQtyMap[item['id']] = item['qty'] ?? 0;
      }
      final Map<String, num> newQtyMap = {};
      double billProfit = 0;
      for (var item in cartItems) {
        newQtyMap[item['id']] = item['qty'] ?? 0;
        final double sp =
            double.tryParse(item['selling_price'].toString()) ?? 0;
        final double cp =
            double.tryParse(item['cost_price'].toString()) ?? 0;
        billProfit += (sp - cp) * (item['qty'] as num);
      }
      await FirebaseFirestore.instance
          .collection("sales")
          .doc(widget.docId)
          .update({
        "order": cartItems,
        "total": finalTotal,
        "saved_on_mrp": savedAmount,
        "date": Timestamp.fromDate(DateTime.now()),
        "inv_id": invId,
        "extra_purchase_amount":
        double.tryParse(_extraPurchaseController.text) ?? 0.0,
        "profit": billProfit,
        "payment_method": _selectedPaymentMethod,
      });
      final allIds = {...oldQtyMap.keys, ...newQtyMap.keys};
      for (var id in allIds) {
        final diff =
            (newQtyMap[id] ?? 0) - (oldQtyMap[id] ?? 0);
        if (diff != 0) {
          await FirebaseFirestore.instance
              .collection("products")
              .doc(id)
              .update({'stock': FieldValue.increment(-diff)});
        }
      }
      if (mounted) Navigator.pop(context);
    } else {
      final double finalTotal = calculateTotal();
      final double savedAmount = _savedAmountTotal();
      _showLoadingDialog();
      final String invId =
          "INV_${printDate(date: DateTime.now().toString(), format: "ddmmyyhhmmss")}";
      await FirebaseFirestore.instance.collection("sales").add({
        "order": cartItems,
        "total": finalTotal,
        "saved_on_mrp": savedAmount,
        "date": Timestamp.fromDate(DateTime.now()),
        "inv_id": invId,
        "payment_method": _selectedPaymentMethod,
      }).then((doc) async {
        for (var item in cartItems) {
          await FirebaseFirestore.instance
              .collection("products")
              .doc(item['id'])
              .update({'stock': FieldValue.increment(-(item['qty'] as num))});
        }
        toast("Bill Saved Successfully");
        if (mounted) {
          Navigator.of(context).pop();
          setState(() {
            cartItems.clear();
            _discountController.clear();
            _extraPurchaseController.clear();
          });
        }
      });
    }
  }
}
