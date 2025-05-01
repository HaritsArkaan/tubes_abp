class Review{
  final int id;
  final String content;
  final double rating;
  final int userId;
  final int snackId;

  Review({
    required this.id,
    required this.content,
    required this.rating,
    required this.userId,
    required this.snackId,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'] as int,
      content: json['content'] as String,
      rating: (json['rating'] as num).toDouble(),
      userId: json['userId'] as int,
      snackId: json['snackId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'rating': rating,
      'userId': userId,
      'snackId': snackId,
    };
  }
}