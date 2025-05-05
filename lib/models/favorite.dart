class Favorite{
  final int id;
  final int userId;
  final int snackId;

  Favorite({
    required this.id,
    required this.userId,
    required this.snackId,
  });

  factory Favorite.fromJson(Map<String, dynamic> json) {
    return Favorite(
      id: json['id'] as int,
      userId: json['userId'] as int,
      snackId: json['snackId'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'snackId': snackId,
    };
  }
}