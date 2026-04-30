import 'dart:async';

import 'package:button_kit/common_import.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:shivam_super_market/core/helper_function.dart';
import 'package:shivam_super_market/widget/PageWrapper.dart';

import 'add_product_screen.dart';
import 'package:flutter/material.dart';
import 'package:shivam_super_market/core/config.dart';

class ProductView extends StatefulWidget {
  const ProductView({super.key});

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  List<Map> products = [];
  int _selectedTabIndex = 0;
  int totalProducts = 0;
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 10;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _getTotalProduct();
    _fetchProduct();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _fetchProduct(isLoadMore: true);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageWrapper(
      title: 'Products ($totalProducts)',
      subtitle: 'Manage your product catalogue.',
      actions: [
        ElevatedButton.icon(
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (_) =>  AddProductPage(),
            );
            _fetchProduct();
            _getTotalProduct();
          },
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Add Product'),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tab chips ──────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _chip('All', 0, Colors.blue),
                const SizedBox(width: 8),
                _chip('Low Stock', 2, Colors.red),
                const SizedBox(width: 8),
                _chip('Inactive', 3, Colors.grey),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Search ─────────────────────────────────────
          TextField(
            controller: _searchController,
            onChanged: (v) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 400), () {
                if (v.trim().isEmpty) {
                  _fetchProduct();
                } else {
                  _searchProduct();
                }
              });
            },
            decoration: InputDecoration(
              hintText: 'Search products...',
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
                const BorderSide(color: Color(0xFFDDE4ED), width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide:
                BorderSide(color: primaryColor, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Product list ───────────────────────────────
          _isLoading && products.isEmpty
              ? const Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              ))
              : products.isEmpty
              ? Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 60,
                      color: Colors.grey.withOpacity(0.4)),
                  const SizedBox(height: 12),
                  const Text('No products found',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          )
              : ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: products.length,
            itemBuilder: (_, index) =>
                _productRow(index),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, int tabIndex, Color color) {
    final selected = _selectedTabIndex == tabIndex;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedTabIndex = tabIndex);
        _fetchProduct();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? color : const Color(0xFFDDE4ED)),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : Colors.grey[600],
                fontWeight: selected
                    ? FontWeight.bold
                    : FontWeight.normal,
                fontSize: 13)),
      ),
    );
  }

  Widget _productRow(int index) {
    final p = products[index];
    final bool inactive = p['is_active'] != true;
    final int stock = int.tryParse(p['stock'].toString()) ?? 0;
    final bool lowStock =
        stock <= (int.tryParse(p['low_stock']?.toString() ?? '5') ?? 5);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: inactive ? const Color(0xFFF5F5F5) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: inactive
              ? Colors.grey.shade300
              : lowStock
              ? Colors.red.shade100
              : const Color(0xFFE8EDF2),
        ),
      ),
      child: Row(
        children: [
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (inactive)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Inactive',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 10)),
                      ),
                    if (lowStock && !inactive)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text('Low Stock',
                            style: TextStyle(
                                color: Colors.red, fontSize: 10)),
                      ),
                    Flexible(
                      child: Text(p['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${p['selling_price']}  •  Stock: $stock ${p['unit'] ?? ''}',
                  style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600]),
                ),
                if (p['barcode'] != null && p['barcode'].toString().isNotEmpty)
                  Text('Barcode: ${p['barcode']}',
                      style: const TextStyle(
                          fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),

          // Actions
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _actionBtn(Icons.checklist_rounded, Colors.blue, () {
                _showUpdateStockDialog(
                  context,
                  name: p['name'],
                  initialStock:
                  int.tryParse(p['stock'].toString()) ?? 0,
                  initialLowStock:
                  int.tryParse(p['low_stock'].toString()) ?? 0,
                  onSubmit: (stock, lowStock) {
                    FirebaseFirestore.instance
                        .collection("products")
                        .doc(p['id'])
                        .update({
                      "stock": stock,
                      "low_stock": lowStock,
                      "is_low_stock": stock <= lowStock,
                    });
                    _fetchProduct();
                  },
                );
              }),
              _actionBtn(Icons.edit_rounded, Colors.orange, () async {
                await showDialog(
                  context: context,
                  builder: (_) => AddProductPage(map: p as Map<dynamic, dynamic>),
                );
                _fetchProduct();
              }),
              _actionBtn(Icons.delete_rounded, Colors.red, () async {
                final confirm = await showDeleteDialog(context);
                if (confirm) {
                  FirebaseFirestore.instance
                      .collection("products")
                      .doc(p['id'])
                      .delete();
                  setState(() => products.removeAt(index));
                  _getTotalProduct();
                }
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, Color color, VoidCallback onTap) {
    return Tooltip(
      message: icon == Icons.checklist_rounded
          ? 'Update Stock'
          : icon == Icons.edit_rounded
          ? 'Edit'
          : 'Delete',
      child: Material(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: color, size: 18),
          ),
        ),
      ),
    );
  }

  void _fetchProduct({bool isLoadMore = false}) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    if (!isLoadMore) {
      products.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    Query query =
    FirebaseFirestore.instance.collection("products");

    if (_selectedTabIndex == 0) {
      // all
    } else if (_selectedTabIndex == 2) {
      query = query
          .where("is_active", isEqualTo: true)
          .where("is_low_stock", isEqualTo: true);
    } else if (_selectedTabIndex == 3) {
      query = query.where("is_active", isEqualTo: false);
    }

    query = query.orderBy("name").limit(_pageSize);

    if (isLoadMore && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    try {
      final snap = await query.get();
      if (snap.docs.isNotEmpty) {
        _lastDocument = snap.docs.last;
        setState(() {
          for (var doc in snap.docs) {
            products.add(doc.data() as Map<String, dynamic>);
          }
        });
      }
      if (snap.docs.length < _pageSize) _hasMore = false;
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _searchProduct() async {
    products.clear();
    _lastDocument = null;
    _hasMore = true;
    final text = _searchController.text;
    if (text.trim().isEmpty) return _fetchProduct();

    try {
      final nameSnap = await FirebaseFirestore.instance
          .collection("products")
          .where('sort_name',
          isGreaterThanOrEqualTo: text.toUpperCase())
          .where('sort_name',
          isLessThanOrEqualTo: text.toUpperCase() + '\uf8ff')
          .limit(20)
          .get();

      final Map<String, Map<String, dynamic>> uniqueMap = {};
      for (var doc in nameSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['id'] != null) uniqueMap[data['id']] = data;
      }

      if (mounted) {
        setState(() {
          products = uniqueMap.values.toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _getTotalProduct() async {
    final res = await FirebaseFirestore.instance
        .collection("products")
        .where("is_active", isEqualTo: true)
        .get();
    if (mounted) setState(() => totalProducts = res.docs.length);
  }

  void _showUpdateStockDialog(
      BuildContext context, {
        required int initialStock,
        required int initialLowStock,
        required Function(int, int) onSubmit,
        required String name,
      }) {
    final stockCtrl =
    TextEditingController(text: initialStock.toString());
    final lowStockCtrl =
    TextEditingController(text: initialLowStock.toString());

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Update Stock'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: double.infinity),
            RichText(
                text: TextSpan(children: [
                  const TextSpan(
                      text: 'Product: ',
                      style: TextStyle(
                          color: Colors.grey, fontSize: 13)),
                  TextSpan(
                      text: name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 15)),
                ])),
            const SizedBox(height: 20),
            TextField(
              autofocus: true,
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Stock Quantity',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lowStockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Low Stock Limit',
                  border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final s =
                  int.tryParse(stockCtrl.text.trim()) ?? 0;
              final l =
                  int.tryParse(lowStockCtrl.text.trim()) ?? 0;
              onSubmit(s, l);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }
}

// class TaxDropdown extends StatefulWidget {
//   const TaxDropdown({super.key});
//
//   @override
//   State<TaxDropdown> createState() => _TaxDropdownState();
// }
//
// class _TaxDropdownState extends State<TaxDropdown> {
//   String selectedTax = "0";
//   TextEditingController customController = TextEditingController();
//   List<String> taxList = ["0", "5", "12", "18", "28", "Custom"];
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text("Select GST (%)"),
//
//         const SizedBox(height: 8),
//
//         DropdownButtonFormField<String>(
//           value: selectedTax,
//           items: taxList.map((value) {
//             return DropdownMenuItem(
//               value: value,
//               child: Text(value == "Custom" ? "Custom %" : "$value %"),
//             );
//           }).toList(),
//           onChanged: (value) {
//             setState(() {
//               selectedTax = value!;
//             });
//           },
//           decoration: const InputDecoration(
//             border: OutlineInputBorder(),
//           ),
//         ),
//
//         const SizedBox(height: 10),
//
//         // Show custom input if selected
//         if (selectedTax == "Custom")
//           TextField(
//             controller: customController,
//             keyboardType: TextInputType.number,
//             decoration: const InputDecoration(
//               labelText: "Enter Custom GST %",
//               border: OutlineInputBorder(),
//             ),
//           ),
//
//       ],
//     );
//   }
// }

