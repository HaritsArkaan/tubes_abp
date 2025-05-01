class ReviewStatistic {
  final int reviewCount;
  final double averageRating;

  ReviewStatistic({
    required this.reviewCount,
    required this.averageRating,
  });
  factory ReviewStatistic.fromJson(Map<String, dynamic> json) {
    return ReviewStatistic(
      reviewCount: json['reviewCount'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
    );
  }
}