class OrderHistory {
  final int? id;
  final String drinkName;
  final int price;
  final String currency;
  final double? lat;
  final double? long;
  final DateTime date;
  final String? imageUrl;

  OrderHistory({
    this.id,
    required this.drinkName,
    required this.price,
    required this.currency,
    this.lat,
    this.long,
    required this.date,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() => {
    "id": id,
    "drink_name": drinkName,
    "price": price,
    "currency": currency,
    "lat": lat,
    "long": long,
    "date": date.toIso8601String(),
    "image_url": imageUrl,
  };

  static OrderHistory fromMap(Map<String, dynamic> map) {
    return OrderHistory(
      id: map["id"],
      drinkName: map["drink_name"] ?? "Matcha",
      price: map["price"] ?? 0,
      currency: map["currency"] ?? "IDR",
      lat: map["lat"] != null ? (map["lat"] as num).toDouble() : null,
      long: map["long"] != null ? (map["long"] as num).toDouble() : null,
      date: DateTime.parse(map['date']).toLocal(),
      imageUrl: map["image_url"],
    );
  }
}
