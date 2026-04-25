
import 'package:cloud_firestore/cloud_firestore.dart';

class SaleModel {
  final String id;
  final String invId;
  final DateTime date;
  final String paymentMethod;
  final double total;
  final double savedOnMRP;
  final List<dynamic> orders;

  SaleModel({required this.id,required this.invId,required this.savedOnMRP, required this.date, required this.paymentMethod, required this.total, required this.orders});

  factory SaleModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return SaleModel(
      id: doc.id,
      invId:data['inv_id']??"",
      // Handle Firestore Timestamp to DateTime
      date: (data['date'] as Timestamp).toDate(),
      paymentMethod: data['payment_method'] ?? 'N/A',
      total: double.tryParse(data['total'].toString())??0.0,
      savedOnMRP: double.tryParse(data['saved_on_mrp'].toString())??0.0,
      orders: data['order'] ?? [],
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "inv_id": invId,
      "date": Timestamp.fromDate(date), // convert DateTime to Firestore Timestamp
      "payment_method": paymentMethod,
      "total": total,
      "saved_on_mrp": savedOnMRP,
      "order": orders,
    };
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class Sale {
//   final DateTime date;
//   final String invId;
//   final String paymentMethod;
//   final int total;
//   final List<OrderItem> orders;
//
//   Sale({
//     required this.date,
//     required this.invId,
//     required this.paymentMethod,
//     required this.total,
//     required this.orders,
//   });
//
//   factory Sale.fromFirestore(Map<String, dynamic> data) {
//     return Sale(
//       date: (data['date'] as Timestamp).toDate(),
//       invId: data['inv_id'] ?? '',
//       paymentMethod: data['payment_method'] ?? '',
//       total: data['total'] ?? 0,
//       orders: (data['order'] as List)
//           .map((item) => OrderItem.fromMap(item))
//           .toList(),
//     );
//   }
// }
//
// class OrderItem {
//   final String name;
//   final int qty;
//   final int sellingPrice;
//   final String barcode;
//
//   OrderItem({
//     required this.name,
//     required this.qty,
//     required this.sellingPrice,
//     required this.barcode,
//   });
//
//   factory OrderItem.fromMap(Map<String, dynamic> map) {
//     return OrderItem(
//       name: map['name'] ?? '',
//       qty: map['qty'] ?? 0,
//       sellingPrice: map['selling_price'] ?? 0,
//       barcode: map['barcode'] ?? '',
//     );
//   }
// }