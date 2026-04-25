class Product {
  int? id;
  String name;
  String barcode;
  double price;
  int stock;

  Product({
    this.id,
    required this.name,
    required this.barcode,
    required this.price,
    required this.stock,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'barcode': barcode,
      'price': price,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      barcode: map['barcode'],
      price: map['price'],
      stock: map['stock'],
    );
  }
}
