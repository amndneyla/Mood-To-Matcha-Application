class Drink {
  final int id;
  final String name;
  final String category;
  final String restaurant;
  final String imageUrl;
  final String description;
  final double priceUsd;
  final String mood;
  final String health;
  final double lat;
  final double long;

  Drink({
    required this.id,
    required this.name,
    required this.category,
    required this.restaurant,
    required this.imageUrl,
    required this.description,
    required this.priceUsd,
    required this.mood,
    required this.health,
    required this.lat,
    required this.long,
  });

  factory Drink.fromJson(Map<String, dynamic> json) {
    return Drink(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      category: json['category'] ?? '',
      restaurant: json['restaurant'] ?? '',
      imageUrl: json['image_url'] ?? '',
      description: json['description'] ?? '',
      priceUsd: (json['price_usd'] ?? 0).toDouble(),
      mood: json['mood'] ?? '',
      health: json['health'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      long: (json['long'] ?? 0).toDouble(),
    );
  }
}
