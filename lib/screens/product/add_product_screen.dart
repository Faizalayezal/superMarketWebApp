import 'package:button_kit/button_kit.dart';
import 'package:button_kit/common_import.dart';
import 'package:shivam_super_market/common_import.dart';
import 'package:shivam_super_market/core/helper_function.dart';
import 'package:shivam_super_market/widget/app_dropdown.dart';
import 'package:shivam_super_market/widget/app_form_field.dart';


class AddProductPage extends StatefulWidget {
  final Map<dynamic, dynamic>? map;

  const AddProductPage({super.key, this.map});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _productExpiryDate;

  final nameController = TextEditingController();
  final sellingPriceController = TextEditingController();
  final costPriceController = TextEditingController();
  final mrpPriceController = TextEditingController();
  final stockController = TextEditingController();
  final lowStockController = TextEditingController();
  final barcodeController = TextEditingController();

  String? selectedCategory;
  String? selectedUnit;
  bool isActive = true;
  List<Map> categoryList = [];
  List<Map> units = [];

  @override
  void initState() {
    getCatList();
    getUnit();
    if (widget.map != null) {
      final m = widget.map!;
      if (m['expiry_date'] != null) {
        _productExpiryDate = (m['expiry_date'] as Timestamp).toDate();
      }
      nameController.text = m['name'];
      sellingPriceController.text = m['selling_price'].toString();
      costPriceController.text = m['cost_price'].toString();
      mrpPriceController.text = m['mrp'].toString();
      stockController.text = m['stock'].toString();
      lowStockController.text = m['low_stock'].toString();
      barcodeController.text = m['barcode'];
      selectedCategory = m['category'];
      selectedUnit = m['unit'];
      isActive = m['is_active'];
    }
    super.initState();
  }

  @override
  void dispose() {
    nameController.dispose();
    sellingPriceController.dispose();
    costPriceController.dispose();
    mrpPriceController.dispose();
    stockController.dispose();
    lowStockController.dispose();
    barcodeController.dispose();
    super.dispose();
  }

  void getCatList() async {
    categoryList.clear();
    final res =
        await FirebaseFirestore.instance.collection("categories").get();
    for (var e in res.docs) {
      categoryList.add(e.data());
    }
    setState(() {});
  }

  void getUnit() async {
    units.clear();
    final res =
        await FirebaseFirestore.instance.collection("product_units").get();
    for (var e in res.docs) {
      units.add(e.data());
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backGroundColor,
      appBar: AppBar(
        title: const Text("Update Product"),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  "Active Product",
                  style: TextStyle(fontSize: 16),
                ),
                value: isActive,
                onChanged: (val) => setState(() => isActive = val),
              ),
              const SizedBox(height: 12),

              // Product Name
              AppFormField(nameController, "Product Name", autoFocus: true),

              // Prices row
              Row(
                children: [
                  Expanded(
                    child: AppFormField(sellingPriceController, "Selling Price",
                        isNumber: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppFormField(costPriceController, "Cost Price",
                        isNumber: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppFormField(mrpPriceController, "MRP",
                        isNumber: true),
                  ),
                ],
              ),

              // Category & Unit row
              Row(
                children: [
                  Expanded(
                    child: AppDropdown(
                      value: selectedCategory,
                      hint: "Select Category",
                      items: categoryList
                          .map((e) => e['category'].toString())
                          .toList(),
                      onChanged: (val) =>
                          setState(() => selectedCategory = val),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppDropdown(
                      value: selectedUnit,
                      hint: "Select Unit",
                      items:
                          units.map((e) => e['unit'].toString()).toList(),
                      onChanged: (val) => setState(() => selectedUnit = val),
                    ),
                  ),
                ],
              ),

              // Stock row
              Row(
                children: [
                  Expanded(
                    child: AppFormField(stockController, "Stock Quantity",
                        isNumber: true),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppFormField(lowStockController, "Low Stock Limit",
                        isNumber: true),
                  ),
                ],
              ),

              // Barcode row
              Row(
                children: [
                  Expanded(
                    child: AppFormField(barcodeController, "Barcode / SKU",
                        isNumber: true),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: SizedBox()),
                ],
              ),

              const SizedBox(height: 20),
              ButtonKit(
                onTap: _saveProduct,
                title: "Save",
                type: ButtonType.rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct() async {
    final double sellingPrice =
        double.tryParse(sellingPriceController.text) ?? 0;
    final double costPrice = double.tryParse(costPriceController.text) ?? 0;
    final double mrp = double.tryParse(mrpPriceController.text) ?? 0;

    if (sellingPrice < costPrice || mrp < costPrice) {
      return toast("Provide Valid Price");
    }
    if (sellingPrice > mrp) {
      return toast("Provide Valid Sell Price");
    }

    final AggregateQuerySnapshot b1 = await FirebaseFirestore.instance
        .collection("products")
        .where("barcode", isEqualTo: barcodeController.text)
        .count()
        .get();

    if ((b1.count ?? 0) > 0 && widget.map == null) {
      return toast("Barcode Already Exist");
    }

    if (_formKey.currentState!.validate()) {
      final product = {
        "name": nameController.text,
        "sort_name": _productSortName(nameController.text),
        "selling_price": double.parse(sellingPriceController.text),
        "cost_price": double.parse(costPriceController.text),
        "mrp": double.parse(mrpPriceController.text),
        "category": selectedCategory,
        "unit": selectedUnit,
        "stock": int.parse(stockController.text),
        "low_stock": int.parse(lowStockController.text),
        "barcode": barcodeController.text.trim(),
        "is_active": isActive,
        "expiry_date": _productExpiryDate != null
            ? Timestamp.fromDate(_productExpiryDate!)
            : null,
        "created_at": DateTime.now().toString(),
        "is_low_stock": int.parse(stockController.text) <=
            int.parse(lowStockController.text),
      };

      if (widget.map != null) {
        product['id'] = widget.map!['id'];
        await FirebaseFirestore.instance
            .collection("products")
            .doc(widget.map!['id'])
            .update(product);
      } else {
        final ref =
            await FirebaseFirestore.instance.collection("products").add(product);
        await ref.update({"id": ref.id});
      }
      Navigator.pop(context);
    }
  }

  String _productSortName(String text) {
    if (text.isEmpty) return "";
    final words = text.trim().split(RegExp(r'\s+'));
    return words
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase())
        .join();
  }
}
