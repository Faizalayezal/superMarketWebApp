import 'package:flutter/material.dart';

/// Generic table widget for listing items (units, categories) with edit/delete popup
class ItemsTable extends StatelessWidget {
  final List<Map> items;
  final String columnLabel;
  final String Function(Map item) itemLabel;
  final Future<void> Function(int index) onEdit;
  final Future<void> Function(int index) onDelete;

  const ItemsTable({
    super.key,
    required this.items,
    required this.columnLabel,
    required this.itemLabel,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Header Row
        Row(
          children: [
            const Expanded(
              flex: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0),
                child: Text("#"),
              ),
            ),
            Expanded(flex: 4, child: Text(columnLabel)),
            const Expanded(flex: 1, child: Text("")),
          ],
        ),
        const Divider(),
        ...List.generate(items.length, (index) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 0,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Text("${index + 1}"),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(itemLabel(items[index])),
                  ),
                  Expanded(
                    flex: 1,
                    child: PopupMenuButton(
                      onSelected: (value) async {
                        if (value == "edit") {
                          await onEdit(index);
                        } else if (value == "delete") {
                          await onDelete(index);
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "edit", child: Text("Edit")),
                        PopupMenuItem(value: "delete", child: Text("Delete")),
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
    );
  }
}
