import 'package:flutter/material.dart';

/// Common dialog for adding/editing a single named item (Unit, Category, etc.)
/// Usage:
///   await AddItemDialog.show(
///     context,
///     title: "Unit",
///     controller: nameController,
///     onSave: () async { ... },
///   );
class AddItemDialog extends StatelessWidget {
  final String title;
  final TextEditingController controller;
  final VoidCallback onSave;

  const AddItemDialog({
    super.key,
    required this.title,
    required this.controller,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required TextEditingController controller,
    required VoidCallback onSave,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddItemDialog(
        title: title,
        controller: controller,
        onSave: onSave,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Add $title",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(title),
            const SizedBox(height: 6),
            TextField(
              autofocus: true,
              controller: controller,
              decoration: InputDecoration(
                hintText: "Enter $title",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
