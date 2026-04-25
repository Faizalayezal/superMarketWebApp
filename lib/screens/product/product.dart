import 'dart:async';

import 'package:button_kit/button_kit.dart';
import 'package:button_kit/common_import.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shivam_super_market/core/helper_function.dart';
import 'package:shivam_super_market/core/utils.dart';

import 'add_product_screen.dart';
//
class ProductView extends StatefulWidget {
  const ProductView({super.key});

  @override
  State<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends State<ProductView> {
  List<Map> products=[];
  int _selectedTabIndex = 0;
    int totalProducts = 0;
  // Colors based on your Navy/Brown logo theme
  final Color primaryColor = Color(0xFF1B305B);
  final Color accentColor = Color(0xFFB06A4D);
  DocumentSnapshot? _lastDocument; // Stores the last item of the current page
  bool _isLoading = false;
  bool _hasMore = true; // To stop fetching when the database is empty
  int _pageSize = 10; // Number of items per page
  ScrollController _scrollController = ScrollController();
  var searchController=TextEditingController();


  @override
  void initState() {
    getTotalProduct();
    fetchProduct();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        fetchProduct(isLoadMore: true); // Load next page
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backGroundColor,
      appBar: AppBar(
        centerTitle: false,
        title:  Text(
          "Products ( $totalProducts )",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: MaterialButton(
              // type: ButtonType.rounded,
              color:  Colors.blueGrey,
              // borderColor: Colors.blueGrey,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadiusGeometry.circular(12)
              ),
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text("+Add Product",style: TextStyle(color: Colors.white),),
              onPressed: () async{
              await showDialog(
                context: context,
                builder: (context) =>  AddProductPage(),
              );
              fetchProduct();
            },
            ),
          ),
        ],
      ),
      body: Container(
        color: backGroundColor,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 0.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(width: 12),
                        // --- All Chip ---
                        ChoiceChip(
                          label: Text("All"),
                          selected: _selectedTabIndex == 0,
                          selectedColor: Colors.blueAccent.withOpacity(0.2),
                          checkmarkColor: Colors.blueAccent,
                          labelStyle: TextStyle(
                            color: _selectedTabIndex == 0 ? Colors.blueAccent : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedTabIndex = 0);
                            fetchProduct();
                          },
                        ),
                        SizedBox(width: 12),
                        // --- Low Stock Chip ---
                        ChoiceChip(
                          label: Text("Low Stock"),
                          selected: _selectedTabIndex == 2,
                          selectedColor: Colors.red.withOpacity(0.2),
                          checkmarkColor: Colors.red,
                          labelStyle: TextStyle(
                            color: _selectedTabIndex == 2 ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedTabIndex = 2);
                            fetchProduct();
                          },
                        ),
                        SizedBox(width: 12),
                        // --- Low Stock Chip ---
                        ChoiceChip(
                          label: Text("Inactive"),
                          selected: _selectedTabIndex == 3,
                          selectedColor: Colors.red.withOpacity(0.2),
                          checkmarkColor: Colors.red,
                          labelStyle: TextStyle(
                            color: _selectedTabIndex == 3 ? Colors.red : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                          onSelected: (selected) {
                            setState(() => _selectedTabIndex = 3);
                            fetchProduct();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: searchController,
                        onSubmitted: (value) {
                          try{
                            FirebaseFirestore.instance.collection("products").where("barcode",isEqualTo: searchController.text).get().then((result) {
                              products.clear();
                              result.docs.forEach((element) {
                                products.add(element.data());
                                setState(() {

                                });
                              },);
                              // value
                            },);
                          }catch(e,s){
                            print("CheckSearchErro:::$e===$s");

                          }
                        },
                        onChanged: (value) {
                          if(searchController.text.trim().isEmpty){
                            fetchProduct();
                            return;
                          }else{
                            searchProduct();
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Search Product...",
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Product List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        color:
                        products[index]['is_active']!=true?Colors.grey.shade300:
                        Colors.white,
                        borderRadius: BorderRadius.circular(12)
                      ),
                      margin: EdgeInsets.only(bottom: 12),
                      padding: EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("${products[index]['name']}"),
                              Text("Price: ₹${products[index]['selling_price']}"),
                              Text("Stock: ${products[index]['stock']} ${products[index]['unit']}"),
                            ]
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.checklist),
                                onPressed: () async{
                                  showUpdateStockDialog(
                                    context,
                                    name:products[index]['name'],
                                    initialStock: int.tryParse(products[index]['stock'].toString())??0,
                                    initialLowStock:  int.tryParse(products[index]['low_stock'].toString())??0,
                                    onSubmit: (stock, lowStock) {
                                      FirebaseFirestore.instance.collection("products").doc(products[index]['id']).update({
                                        "low_stock":lowStock,
                                        "stock":stock,
                                      });
                                      fetchProduct();
                                    },
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () async{
                                  await showDialog(
                                    context: context,
                                    builder: (context) =>AddProductPage(
                                        map:products[index]
                                    ),
                                  );
                                  fetchProduct();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () async{
                                  bool confirm = await showDeleteDialog(context);
                                  if(confirm){
                                    FirebaseFirestore.instance.collection("products").doc(products[index]['id']).delete();
                                    products.removeAt(index);
                                    fetchProduct();
                                  }
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void fetchProduct({bool isLoadMore = false}) async {

    setState(() => _isLoading = true);

    // 1. Reset everything if we are refreshing the tab (not loading more)
    if (!isLoadMore) {
      products.clear();
      _lastDocument = null;
      _hasMore = true;
    }

    // 2. Build the Base Query based on the tab
    Query query = FirebaseFirestore.instance.collection("products");

    if (_selectedTabIndex == 0) {
      query = query;
    } else if (_selectedTabIndex == 1) {
      query = query.where("is_active", isEqualTo: true)
          .where("expiry_date", isLessThan: Timestamp.now());
    } else if (_selectedTabIndex == 2) {
      query = query.where("is_active", isEqualTo: true)
          .where("is_low_stock", isEqualTo: true);
    } else if (_selectedTabIndex == 3) {
      query = query.where("is_active", isEqualTo: false);
    }

    // 3. Add Ordering and Pagination
    // Note: Order by a field is required for startAfterDocument to work reliably
    query = query.orderBy("name").limit(_pageSize);

    if (isLoadMore && _lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    // 4. Execute the Query
    try {
      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;

        setState(() {
          for (var doc in querySnapshot.docs) {
            products.add(doc.data() as Map<String, dynamic>);
          }
        });
      }

      // If we fetched fewer items than the page size, there are no more left
      if (querySnapshot.docs.length < _pageSize) {
        _hasMore = false;
      }
    } catch (e) {
      print("Pagination Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(24),
        value: value,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        items: items
            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? "Select $hint" : null,
      ),
    );
  }

  // searchProduct() async{
  //   products.clear();
  //   _lastDocument=null; // Stores the last item of the current page
  //   _isLoading = false;
  //   _hasMore = true;
  //   if(searchController.text.trim().isEmpty) return fetchProduct();
  //   String text=searchController.text;
  //   var query = FirebaseFirestore.instance.collection("products")
  //       .where("is_active", isEqualTo: true)
  //       .where("sort_name", isEqualTo: searchController.text)
  //       .where("name", isEqualTo: searchController.text)
  //       .where("category", isEqualTo: searchController.text)
  //       .where(
  //       "barcode",isEqualTo: text
  //   );
  //   QuerySnapshot snapshot = await query.get();
  //   setState(() {
  //     for (var doc in snapshot.docs) {
  //       products.add(doc.data() as Map<String, dynamic>);
  //     }
  //   });
  // }
  searchProduct() async{
    products.clear();
    _lastDocument=null; // Stores the last item of the current page
    _isLoading = false;
    _hasMore = true;
    if(searchController.text.trim().isEmpty) return fetchProduct();
    String text=searchController.text;

    try {
      List<Map<String, dynamic>> tempList = [];

      final collection = FirebaseFirestore.instance.collection("products");


      // 🔹 2. Name Search (using sort_name for lowercase match)
      var nameSnap = await collection
          // .where("sort_name", isEqualTo: text.toUpperCase())
          .where('sort_name', isGreaterThanOrEqualTo: text.toUpperCase())
          .where('sort_name', isLessThanOrEqualTo: text.toUpperCase() + '\uf8ff')

      // .where("name", isLessThanOrEqualTo: text + '\uf8ff')
          .where("is_active", isEqualTo: true)
          .limit(20)
          .get();

      print("📝 Name results: ${nameSnap.docs.length}");



      // 🔥 Merge all results
      for (var doc in [
        ...nameSnap.docs,
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
    //
    // var query = FirebaseFirestore.instance.collection("products")
    //     .where("is_active", isEqualTo: true)
    //     .where("sort_name", isEqualTo: searchController.text)
    //     .where("name", isEqualTo: searchController.text)
    //     .where("category", isEqualTo: searchController.text)
    //     .where(
    //   "barcode",isEqualTo: text
    // );
    // QuerySnapshot snapshot = await query.get();
    // setState(() {
    //   for (var doc in snapshot.docs) {
    //     products.add(doc.data() as Map<String, dynamic>);
    //   }
    // });
  }

  void getTotalProduct() async{
    var res=await FirebaseFirestore.instance.collection("products").where("is_active", isEqualTo: true).get();
    setState(() {
      totalProducts=res.docs.length;
    });
  }

  void showUpdateStockDialog(
      BuildContext context, {
        required int initialStock,
        required int initialLowStock,
        required Function(int stock, int lowStock) onSubmit, required String name,
      }) {
    final TextEditingController stockController =
    TextEditingController(text: initialStock.toString());

    final TextEditingController lowStockController =
    TextEditingController(text: initialLowStock.toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title:  Text("Update Stock"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: double.infinity,),
              Row(
                children: [
                  Text("Product Name: ",style: TextStyle(fontSize: 14),),
                  Expanded(child: Text(name,style: TextStyle(fontWeight: FontWeight.bold,fontSize: 18),)),
                ],
              ),
              SizedBox(height: 24,),
              // Stock Field
              TextField(
                autofocus: true,
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Stock Quantity",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Low Stock Field
              TextField(
                controller: lowStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Low Stock Limit",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                final int stock =
                    int.tryParse(stockController.text.trim()) ?? 0;
                final int lowStock =
                    int.tryParse(lowStockController.text.trim()) ?? 0;

                onSubmit(stock, lowStock);
                Navigator.pop(context);
              },
              child: const Text("Update"),
            ),
          ],
        );
      },
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

