
import 'package:button_kit/common_import.dart';
import 'package:shivam_super_market/common_import.dart';
import 'package:shivam_super_market/core/helper_function.dart';


class AddProductPage extends StatefulWidget {
  Map<dynamic, dynamic>? map;
  AddProductPage({super.key, this.map});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  DateTime? _productExpiryDate;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController sellingPriceController = TextEditingController();
  final TextEditingController costPriceController = TextEditingController();
  final TextEditingController mrpPriceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController lowStockController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  // final TextEditingController descriptionController = TextEditingController();
  String? selectedCategory;
  // String? selectedTax;
  String? selectedUnit;
  List<String> taxList =["0", "5", "12", "18", "28"];
  bool isActive = true;
  List<Map> categoryList=[];
  List<Map> units=[];

  @override
  void initState() {
    getCatList();
    getUnit();
    if(widget.map!=null){
      if(widget.map!['expiry_date']!=null)
        _productExpiryDate = (widget.map!['expiry_date'] as Timestamp).toDate();
      nameController.text=widget.map!['name'];
      sellingPriceController.text=widget.map!['selling_price'].toString();
      costPriceController.text=widget.map!['cost_price'].toString();
      mrpPriceController.text=widget.map!['mrp'].toString();
      stockController.text=widget.map!['stock'].toString();
      lowStockController.text=widget.map!['low_stock'].toString();
      barcodeController.text=widget.map!['barcode'];
      selectedCategory=widget.map!['category'];
      selectedUnit=widget.map!['unit'];
      isActive=widget.map!['is_active'];
      selectedUnit=widget.map!['unit'];
      isActive=widget.map!['is_active'];
    }
    super.initState();
  }

  void getCatList() async{
    categoryList.clear();
    var res=await FirebaseFirestore.instance.collection("categories").get();
    res.docs.forEach((element) {
      categoryList.add(element.data());
    },);
    setState(() {

    });
  }

  void getUnit() async{
    units.clear();
    var res=await FirebaseFirestore.instance.collection("product_units").get();
    res.docs.forEach((element) {
      units.add(element.data());
    },);
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backGroundColor,
      appBar: AppBar(title: const Text("Update Product"),backgroundColor:Colors.blueGrey),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 16,horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              SwitchListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: const Text("Active Product",style: TextStyle(fontSize: 16),),
                value: isActive,
                onChanged: (val) {
                  setState(() => isActive = val);
                },
              ),
              SizedBox(height: 12,),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // autofocus: true,
                  Expanded(child: _buildTextField(nameController, "Product Name",autoFocus:true),),
                  // SizedBox(width: 12,),
                  // Expanded(child: InkWell(
                  //   onTap: _pickDate,
                  //   child: Container(
                  //     padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  //     decoration: BoxDecoration(
                  //       borderRadius: BorderRadius.circular(12),
                  //       border: Border.all(color: Color(0xFF1B305B), width: 1),
                  //
                  //     ),
                  //     child: Row(
                  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //       children: [
                  //         Text(
                  //           _productExpiryDate == null
                  //               ? "Select Expiry Date"
                  //               : DateFormat('dd MMM, yyyy').format(_productExpiryDate!),
                  //           style: TextStyle(
                  //             fontSize: 16,
                  //             fontWeight: FontWeight.w600,
                  //             color: _productExpiryDate == null ? Colors.grey : Color(0xFF1B305B),
                  //           ),
                  //         ),
                  //         GestureDetector(
                  //           onTap: () {
                  //             _productExpiryDate=null;
                  //             setState(() {
                  //
                  //             });
                  //           },
                  //           child: Icon(
                  //             _productExpiryDate==null?
                  //             Icons.calendar_month_rounded:Icons.close,
                  //             color: Color(0xFF1B305B),
                  //           ),
                  //         ),
                  //       ],
                  //     ),
                  //   ),
                  // ))
                  // expiryDate
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField(sellingPriceController, "Selling Price", isNumber: true)),
                  SizedBox(width: 12,),
                  Expanded(child: _buildTextField(costPriceController, "Cost Price", isNumber: true)),
                  SizedBox(width: 12,),
                  Expanded(child: _buildTextField(mrpPriceController, "MRP", isNumber: true)),
                ],
              ),

              Row(
                children: [
                  Expanded(
                    child: _buildDropdown(
                      value: selectedCategory,
                      hint: "Select Category",
                      items: categoryList.map((e) => e['category'].toString(),).toList(),
                      onChanged: (val) {
                        setState(() => selectedCategory = val);
                      },
                    ),
                  ),
                  SizedBox(width: 12,),
                  Expanded(
                    child: _buildDropdown(
                      value: selectedUnit,
                      hint: "Select Unit",
                      items: units.map((e) => e['unit'].toString(),).toList(),
                      onChanged: (val) {
                        setState(() => selectedUnit = val);
                      },
                    ),
                  ),
                ],
              ),

              Row(
                children: [
                  Expanded(child: _buildTextField(stockController, "Stock Quantity", isNumber: true)),
                  SizedBox(width: 12,),
                  Expanded(child: _buildTextField(lowStockController, "Low Stock Limit", isNumber: true)),
                ],
              ),
              Row(
                children: [
                  Expanded(child: _buildTextField(barcodeController, "Barcode / SKU",isNumber: true)),
                  SizedBox(width: 12,),
                  Expanded(child: SizedBox())
                  // Expanded(child: _buildDropdown(
                  //   value: selectedTax,
                  //   hint: "Select Tax",
                  //   items: taxList,
                  //   onChanged: (val) {
                  //     setState(() => selectedTax = val);
                  //   },
                  // ),),
                ],
              ),
              // _buildTextField(descriptionController, "Description", maxLines: 3,optional: true),
              const SizedBox(height: 20),
              ButtonKit(
                onTap: _saveProduct,
                title: "Save", type: ButtonType.rounded,
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false, int maxLines = 1,bool? optional,  bool? autoFocus}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        autofocus: autoFocus??false,
        controller: controller,
        inputFormatters: [
          if( isNumber )
            FilteringTextInputFormatter.digitsOnly
        ],
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if(optional==true) return null;
          if (value == null || value.isEmpty) {
            return "Enter $label";
          }
          return null;
        },
      ),
    );
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

  void _saveProduct()async {
    double sellingPrice=double.parse(sellingPriceController.text);
    double costPrice=double.parse(costPriceController.text);
    double mrp=double.parse(mrpPriceController.text);
    if(sellingPrice<costPrice||mrp<costPrice){
      return toast("Provide Valid Price");
    }
    if(sellingPrice>mrp){
      return toast("Provide Valid Sell Price");
    }
    AggregateQuery result=FirebaseFirestore.instance.collection("products").where("barcode",isEqualTo: barcodeController.text).count();
    AggregateQuerySnapshot b1=await result.get();
    if((b1.count??0)>0 && widget.map==null){
      return toast("Barcode Already Exist");
    }
    // if((await result.get().count??0))>0){
    //
    // }
    // barcodeController.text
    if (_formKey.currentState!.validate()) {
      var product = {
        "name": nameController.text,
        "sort_name": productSortName(nameController.text),
        "selling_price": double.parse(sellingPriceController.text),
        "cost_price": double.parse(costPriceController.text),
        "mrp": double.parse(mrpPriceController.text),
        "category": selectedCategory,
        "unit": selectedUnit,
        "stock": int.parse(stockController.text),
        "low_stock": int.parse(lowStockController.text),
        "barcode": barcodeController.text.trim(),
        "is_active": isActive,
        "expiry_date": _productExpiryDate!=null?Timestamp.fromDate(_productExpiryDate!):null,
        "created_at": DateTime.now().toString(),
        "is_low_stock":
        int.parse(stockController.text)<=int.parse(lowStockController.text)
      };
      // print("Check:::${product}");
      // return;
      if(widget.map!=null){
        product['id']=widget.map!['id'];
        FirebaseFirestore.instance.collection("products").doc(widget.map!['id']).update(product);
      }else{
        FirebaseFirestore.instance.collection("products").add(product).then((value) {
          value.update({
            "id":value.id
          });
        },);
      }
      Navigator.pop(context);
    }
  }

  productSortName(String text) {
    if (text.isEmpty) return "";

    final words = text.trim().split(RegExp(r'\s+'));

    String initials = words
        .where((word) => word.isNotEmpty)
        .map((word) => word[0].toUpperCase())
        .join();

    return initials;
  }

  // Widget _buildComboForm() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text("Combo Pricing Logic", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
  //       SizedBox(height: 12,),
  //       Row(
  //         children: [
  //           Expanded(child: _buildTextField( _comboQtyController,"Min Quantity",)),
  //           SizedBox(width: 10),
  //           Expanded(child: _buildTextField( _comboPriceController,"Combo Total Price",)),
  //         ],
  //       ),
  //       Text("Help: Customer pays \$105 if they buy 5 items.", style: TextStyle(fontSize: 12, color: Colors.grey)),
  //     ],
  //   );
  // }
  //
  // Widget _buildBOGOForm() {
  //   return Column(
  //     crossAxisAlignment: CrossAxisAlignment.start,
  //     children: [
  //       Text("BOGO Logic", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
  //       SizedBox(height: 12,),
  //       Row(
  //         children: [
  //           Expanded(child: _buildTextField(_buyXController,"Buy X Quantity")),
  //           SizedBox(width: 10),
  //           Expanded(child: _buildTextField(_getYController,"Get Y Free", )),
  //           SizedBox(width: 10),
  //           Expanded(child: _buildTextField(_getYProductBarcodeController,"Get Y Product Code", )),
  //         ],
  //       ),
  //       Text("Note: Free item price will be set to \$0 at checkout.", style: TextStyle(fontSize: 12, color: Colors.grey)),
  //     ],
  //   );
  // }

}
