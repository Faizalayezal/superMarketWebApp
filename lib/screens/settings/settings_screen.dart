import 'package:button_kit/button_kit.dart';
import 'package:button_kit/common_import.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shivam_super_market/core/config.dart';
import 'package:shivam_super_market/widget/add_item_dialog.dart';
import 'package:shivam_super_market/widget/items_table.dart';
import 'package:shivam_super_market/widget/section_card.dart';
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
  List<Map> units = [];
  List<Map> categoryList = [];

  // Shared controller for add/edit dialogs
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentSettings();
      _fetchUnits();
      _fetchCategories();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    _telController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ─── Data Fetchers ───────────────────────────────────────────────────────────

  void _fetchCategories() async {
    categoryList.clear();
    final res =
        await FirebaseFirestore.instance.collection("categories").get();
    for (var element in res.docs) {
      categoryList.add(element.data());
    }
    if (mounted) setState(() {});
  }

  void _fetchUnits() async {
    units.clear();
    final res =
        await FirebaseFirestore.instance.collection("product_units").get();
    for (var element in res.docs) {
      units.add(element.data());
    }
    if (mounted) setState(() {});
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

  // ─── Unit Handlers ───────────────────────────────────────────────────────────

  Future<void> _addUnit() async {
    _nameController.clear();
    await AddItemDialog.show(
      context,
      title: "Unit",
      controller: _nameController,
      onSave: () async {
        Navigator.pop(context);
        final res = await FirebaseFirestore.instance
            .collection("product_units")
            .add({"unit": _nameController.text});
        await res.update({"id": res.id});
        _fetchUnits();
      },
    );
  }

  Future<void> _editUnit(int index) async {
    _nameController.text = units[index]['unit'];
    await AddItemDialog.show(
      context,
      title: "Unit",
      controller: _nameController,
      onSave: () async {
        Navigator.pop(context);
        await FirebaseFirestore.instance
            .collection("product_units")
            .doc(units[index]['id'])
            .set({"unit": _nameController.text, "id": units[index]['id']});
        _fetchUnits();
      },
    );
  }

  Future<void> _deleteUnit(int index) async {
    await FirebaseFirestore.instance
        .collection("product_units")
        .doc(units[index]['id'])
        .delete();
    units.removeAt(index);
    setState(() {});
  }

  // ─── Category Handlers ───────────────────────────────────────────────────────

  Future<void> _addCategory() async {
    _nameController.clear();
    await AddItemDialog.show(
      context,
      title: "Category",
      controller: _nameController,
      onSave: () async {
        Navigator.pop(context);
        final res = await FirebaseFirestore.instance
            .collection("categories")
            .add({"category": _nameController.text});
        await res.update({"id": res.id});
        _fetchCategories();
      },
    );
  }

  Future<void> _editCategory(int index) async {
    _nameController.text = categoryList[index]['category'];
    await AddItemDialog.show(
      context,
      title: "Category",
      controller: _nameController,
      onSave: () async {
        Navigator.pop(context);
        await FirebaseFirestore.instance
            .collection("categories")
            .doc(categoryList[index]['id'])
            .set({
          "category": _nameController.text,
          "id": categoryList[index]['id'],
        });
        _fetchCategories();
      },
    );
  }

  Future<void> _deleteCategory(int index) async {
    await FirebaseFirestore.instance
        .collection("categories")
        .doc(categoryList[index]['id'])
        .delete();
    categoryList.removeAt(index);
    setState(() {});
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Store Configuration")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildSettingsConfig(),
            _buildUnitsSection(),
            _buildCategoriesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsConfig() {
    return SectionCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            decoration:
                const InputDecoration(labelText: "Super Market Title"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _addressController,
            decoration:
                const InputDecoration(labelText: "Billing Address"),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _telController,
            decoration:
                const InputDecoration(labelText: "Contact Number"),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 30),
          _isLoading
              ? const CircularProgressIndicator()
              : ButtonKit(
                  type: ButtonType.rounded,
                  title: "Update Setting",
                  onTap: _saveSettings,
                ),
        ],
      ),
    );
  }

  Widget _buildUnitsSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Units",
            buttonLabel: "+ Add Unit",
            onButtonPressed: _addUnit,
          ),
          const SizedBox(height: 16),
          ItemsTable(
            items: units,
            columnLabel: "Product Unit",
            itemLabel: (item) => item['unit'] ?? "",
            onEdit: _editUnit,
            onDelete: _deleteUnit,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection() {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: "Categories",
            buttonLabel: "+ Add Category",
            onButtonPressed: _addCategory,
          ),
          const SizedBox(height: 16),
          ItemsTable(
            items: categoryList,
            columnLabel: "Category Name",
            itemLabel: (item) => item['category'] ?? "",
            onEdit: _editCategory,
            onDelete: _deleteCategory,
          ),
        ],
      ),
    );
  }
}
