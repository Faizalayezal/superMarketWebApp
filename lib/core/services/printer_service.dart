import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shivam_super_market/core/config.dart';

class PrinterService {

  Future<void> printReceipt({
    required List<dynamic> cartItems,
    required double total,
    required String paymentMethod, required double savedOnMRP, required String invId, required Map<String, dynamic> extraCharges,
  }) async {
    if (kIsWeb) {
      await _printPdf(invId,cartItems, total,savedOnMRP, paymentMethod,extraCharges);
    }
  }

  Future<void> _printPdf(
      String invId,
      List<dynamic> cartItems, double total,double savedOnMRP, String paymentMethod, Map<String, dynamic> extraCharges)
  async {
    final pdf = pw.Document();

    // ✅ Common Styles
    final titleStyle = pw.TextStyle(
      fontSize: 16,
      fontWeight: pw.FontWeight.bold,
    );

    final normalStyle = pw.TextStyle(
      fontSize: 10,
    );

    final smallStyle = pw.TextStyle(
      fontSize: 8,
    );

    final boldStyle = pw.TextStyle(
      fontSize: 10,
      fontWeight: pw.FontWeight.bold,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              /// 🏪 Header
              pw.Center(
                child: pw.Text("$superMarketTitle", style: titleStyle),
              ),
              pw.Center(child: pw.Text("$billAddress", style: normalStyle)),
              pw.Center(
                  child: pw.Text("Phone: $telNumber", style: normalStyle)),

              pw.SizedBox(height: 10),


              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Bill No:", style: normalStyle),
                  pw.Text(
                    invId,
                    style: normalStyle,
                  ),
                ],
              ),
              /// 📅 Date & Payment
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Date:", style: normalStyle),
                  pw.Text(
                    DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()),
                    style: normalStyle,
                  ),
                ],
              ),

              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text("Payment:", style: normalStyle),
                  pw.Text(paymentMethod, style: normalStyle),
                ],
              ),

              pw.Divider(),

              /// 🧾 Table Header
              pw.Row(
                children: [
                  pw.Expanded(child: pw.Text("Item", style: boldStyle)),
                  pw.Expanded(
                    child: pw.Text("Qty",
                        textAlign: pw.TextAlign.center, style: boldStyle),
                  ),
                  pw.Expanded(
                    child: pw.Text("Price",
                        textAlign: pw.TextAlign.end, style: boldStyle),
                  ),
                ],
              ),

              pw.Divider(),

              /// 🛒 Items List
              ...cartItems.asMap().entries.map((entry) {
                int index = entry.key + 1; // Sr No
                var item = entry.value;

                return pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(vertical: 2),
                  child: pw.Row(
                    children: [
                      /// 🔢 Sr No
                      pw.SizedBox(
                        // width: 20,
                        child:   pw.Container(
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey),
                                shape: pw.BoxShape.circle,
                                color: PdfColors.grey
                                // color: Colors.green,
                                // shape: BoxShape.circle
                            ),
                            padding: pw.EdgeInsets.all(2),
                            margin: pw.EdgeInsets.only(right: 2),
                            child: pw.Center(child: pw.Text("${index}",style: smallStyle,))),
                        // child: pw.Text(
                        //   index.toString(),
                        //   style: smallStyle,
                        // ),
                      ),

                      /// 🛒 Item Name
                      pw.Expanded(
                        child: pw.Text(
                          item['name'].toString(),
                          maxLines: 2,
                          style: smallStyle,
                        ),
                      ),

                      /// 🔢 Qty
                      pw.Expanded(
                        child: pw.Text(
                          item['qty'].toString(),
                          textAlign: pw.TextAlign.center,
                          style: smallStyle,
                        ),
                      ),

                      /// 💰 Price
                      pw.Expanded(
                        child: pw.Text(
                          item['selling_price'].toString(),
                          textAlign: pw.TextAlign.end,
                          style: smallStyle,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              pw.Divider(),
              pw.ListView(
                // shrinkWrap: true,
                children: extraCharges.entries.map((entry) {
                  return pw.Text(
                    textAlign: pw.TextAlign.end,
                      "${entry.key}"+": "+"${entry.value}"
                  );
                }).toList(),
              ),
              pw.Divider(),

              /// 💰 Total
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  "TOTAL: ${total.toStringAsFixed(2)} INR",
                  style: normalStyle,
                ),
              ),
              pw.Divider(),

              pw.SizedBox(height: 10),
          /// 💰 Total
          pw.Align(
          alignment: pw.Alignment.center,
          child: pw.Text(
          "*** Saved Rs. ${savedOnMRP.toStringAsFixed(2)}/- on MRP ***",
          style: normalStyle,
          ),
          ),

              pw.SizedBox(height: 10),
              /// 🙏 Footer
              pw.Center(
                child: pw.Text("Thank you for shopping!", style: normalStyle),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }
}
