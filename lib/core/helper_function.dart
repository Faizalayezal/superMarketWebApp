import 'package:button_kit/common_import.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

void showWhatsAppDialog(BuildContext context, String message) {
  TextEditingController phoneController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Send via WhatsApp"),
        content: TextField(
          autofocus: true,
          controller: phoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            hintText: "Enter phone number",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              String phone = phoneController.text.trim();

              if (phone.isEmpty) return;

              String url =
                  "https://wa.me/+91$phone?text=${Uri.encodeComponent(message)}";

              Navigator.pop(context);

              await launchWhatsApp(url);
            },
            child: Text("Send"),
          ),
        ],
      );
    },
  );
}


/// Displays a toast message.
void toast(
    String? value, {
      ToastGravity? gravity,
      length = Toast.LENGTH_SHORT,
      Color? bgColor,
      Color? textColor,
      bool printLogs = false,
    }) {
  if (value != null && value.isNotEmpty) {
    Fluttertoast.showToast(
      msg: value,
      gravity: gravity,
      toastLength: length,
      backgroundColor: bgColor,
      textColor: textColor,
      timeInSecForIosWeb: 2,
    );
  }
}

Future<void> launchWhatsApp(String url) async {
  final Uri uri = Uri.parse(url);

  if (await canLaunchUrl(uri)) {
    await launchUrl(
      uri,
      mode: LaunchMode.externalApplication, // important for desktop
    );
  } else {
    throw 'Could not launch WhatsApp';
  }
}

Future<bool> showDeleteDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline, color: Colors.red),
            SizedBox(width: 10),
            Text("Confirm Delete"),
          ],
        ),
        content: const Text("Are you sure you want to delete this item? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), // Returns false
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true), // Returns true
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("DELETE"),
          ),
        ],
      );
    },
  ) ?? false; // Return false if user taps outside the dialog
}