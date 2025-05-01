class Snack {
  final int id;
  final String name;
  final double price;
  final String image;
  final String imageUrl;
  final String seller;
  final String contact;
  final String location;
  final double rating;
  final String type;
  final int userId;

  Snack({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.imageUrl,
    required this.seller,
    required this.contact,
    required this.location,
    required this.rating,
    required this.type,
    required this.userId,
  });

  factory Snack.fromJson(Map<String, dynamic> json) {
    return Snack(
      id: json['id'] as int,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      image: json['image'] as String,
      imageUrl: json['image_URL'] as String,
      seller: json['seller'] as String,
      contact: json['contact'] as String,
      location: json['location'] as String,
      rating: (json['rating'] as num).toDouble(),
      type: json['type'] as String,
      userId: json['userId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'image': image,
      'image_URL': imageUrl,
      'seller': seller,
      'contact': contact,
      'location': location,
      'rating': rating,
      'type': type,
      'userId': userId,
    };
  }
}