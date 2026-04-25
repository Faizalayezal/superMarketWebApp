import 'package:button_kit/button_kit.dart';
import 'package:button_kit/common_import.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shivam_super_market/core/config.dart';
import '../../core/services/settings_service.dart';

class StoreSettingsScreen extends StatefulWidget {
  const StoreSettingsScreen({super.key});

  @override
  State<StoreSettingsScreen> createState() => _StoreSettingsScreenState();
}

class _StoreSettingsScreenState extends State<StoreSettingsScreen> {
  final _service = SettingsService();
  final _titleController = TextEditingController();
  final _addressController = TextEditingController();
  final _telController = TextEditingController();
  bool _isLoading = false;
  List<Map> units=[];
  List<Map> categoryList=[];

  TextEditingController nameController= TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
      _fetchUnits();
      _fetchCategories();
    });
  }

  void _fetchCategories() async{
    categoryList.clear();
    var res=await FirebaseFirestore.instance.collection("categories").get();
    res.docs.forEach((element) {
      categoryList.add(element.data());
    },);
    if(mounted)
      setState(() {

      });
  }
  void _fetchUnits() async{
    units.clear();
    var res=await FirebaseFirestore.instance.collection("product_units").get();
    res.docs.forEach((element) {
      units.add(element.data());
    },);
    if(mounted)
      setState(() {

      });
  }
  void _loadCurrentSettings() async {
    final data = await _service.getSettings();
    if (data != null) {
      setState(() {
        _titleController.text = data['superMarketTitle'] ?? "";
        _addressController.text = data['billAddress'] ?? "";
        _telController.text = data['telNumber'] ?? "";
      });
    }
  }
  void _saveSettings() async {
    setState(() => _isLoading = true);
    try {
      await _service.updateSettings(
        title: _titleController.text,
        address: _addressController.text,
        telNumber: _telController.text,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Settings updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Configuration")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSettingsConfig(),
            _unitsView(),
            _categoriesView(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsConfig() {
    return Container(
      decoration: myDecoration,
      margin: EdgeInsets.symmetric(horizontal: 24,vertical: 12),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Super Market Title"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            decoration: const InputDecoration(labelText: "Billing Address"),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _telController,
            decoration: const InputDecoration(labelText: "Contact Number"),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator()
              :
          ButtonKit(type: ButtonType.rounded, title: "Update Setting", onTap:_saveSettings,),
        ],
      ),
    );
  }

  Widget _unitsView() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 24,vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: myDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Units",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () async{
                  await addUnitDialog(onSave:() async{
                    Navigator.pop(context);
                    var res=await FirebaseFirestore.instance.collection("product_units").add({
                      "unit":nameController.text
                    });
                    res.update({
                      "id":res.id
                    });
                    _fetchUnits();
                  },title: "Unit");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                child: Text("+ Add Unit", style: TextStyle(color: Colors.white)),
              )
            ],
          ),

          const SizedBox(height: 16),

          ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              // Header Row
              Row(
                children: const [
                  Expanded(flex: 0, child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text("#",style: TextStyle(),),
                  )),
                  Expanded(flex: 4, child: Text("Product Unit")),
                  Expanded(flex: 1, child: Text("")),
                ],
              ),

              const Divider(),

              // Data Rows
              ...List.generate(
                  units.length, (index) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text("${index + 1}"),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text("${units[index]['unit']}"),
                        ),
                        Expanded(
                          flex: 1,
                          child: PopupMenuButton(
                            onSelected: (value) async {
                              if (value == "delete") {
                                FirebaseFirestore.instance
                                    .collection("product_units")
                                    .doc(units[index]['id'])
                                    .delete();

                                units.removeAt(index);
                                setState(() {});
                              } else if (value == "edit") {
                                nameController.text=units[index]['unit'];
                                await addUnitDialog(onSave:() async{
                                  Navigator.pop(context);
                                  await FirebaseFirestore.instance.collection("product_units").doc(units[index]['id']).set({
                                    "unit":nameController.text,
                                    "id":units[index]['id']
                                  });
                                  _fetchUnits();
                                },title: "Unit");
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: "edit", child: Text("Edit")),
                              PopupMenuItem(
                                  value: "delete", child: Text("Delete")),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                );
              }),
            ],
          )
        ],
      ),
    );
  }

  Widget _categoriesView() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24,vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: myDecoration,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          /// Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Categories",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              ElevatedButton(
                onPressed: () async{
                  await addUnitDialog(onSave:() async{
                    Navigator.pop(context);
                    var res=await FirebaseFirestore.instance.collection("categories").add({
                      "category":nameController.text
                    });
                    res.update({
                      "id":res.id
                    });
                    _fetchCategories();
                  },title: "Category");
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey,
                ),
                child: Text("+ Add Category", style: TextStyle(color: Colors.white)),
              )
            ],
          ),

          const SizedBox(height: 16),
          ListView(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              // Header Row
              Row(
                children: const [
                  Expanded(flex: 0, child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text("#",style: TextStyle(),),
                  )),
                  Expanded(flex: 4, child: Text("Category Name")),
                  Expanded(flex: 1, child: Text("")),
                ],
              ),

              const Divider(),

              // Data Rows
              ...List.generate(categoryList.length, (index) {
                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 0,
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text("${index + 1}"),
                          ),
                        ),
                        Expanded(
                          flex: 4,
                          child: Text("${categoryList[index]['category']}"),
                        ),
                        Expanded(
                          flex: 1,
                          child: PopupMenuButton(
                            onSelected: (value) async {
                              if (value == "delete") {
                                FirebaseFirestore.instance
                                    .collection("categories")
                                    .doc(categoryList[index]['id'])
                                    .delete();

                                categoryList.removeAt(index);
                                setState(() {});
                              } else if (value == "edit") {
                                nameController.text=categoryList[index]['category'];
                                await addUnitDialog(onSave:() async{
                                  Navigator.pop(context);
                                  await FirebaseFirestore.instance.collection("categories").doc(categoryList[index]['id']).set({
                                    "category":nameController.text,
                                    "id":categoryList[index]['id']
                                  });
                                  _fetchCategories();
                                },title: "Category");
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: "edit", child: Text("Edit")),
                              PopupMenuItem(
                                  value: "delete", child: Text("Delete")),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                  ],
                );
              }),
            ],
          )
        ],
      ),
    );
  }

  Future<void> addUnitDialog({var onSave,required String title}) async {
    return await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// Title
               Text(
                "Add $title",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              /// Category Name
              Text("$title"),
              const SizedBox(height: 6),
              TextField(
                autofocus: true,
                controller: nameController,
                decoration: InputDecoration(
                  hintText: "Enter $title",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              /// Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    child: const Text("Save"),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

}
