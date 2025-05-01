class ReviewStatistic {
  final int reviewCount;
  final double averageRating;

  ReviewStatistic({
    required this.reviewCount,
    required this.averageRating,
  });

  factory ReviewStatistic.fromJson(Map<String, dynamic> json) {
    // Add debug print to see what's coming from the API
    print('ReviewStatistic JSON: $json');

    // Handle different possible field names and formats
    return ReviewStatistic(
      reviewCount: json['reviewCount'] ?? json['totalReviews'] ?? json['count'] ?? 0,
      averageRating: _parseDouble(json['averageRating'] ?? json['average'] ?? json['rating'] ?? 0),
    );
  }

  // Helper method to safely parse double values
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        print('Error parsing double: $e');
        return 0.0;
      }
    }
    return 0.0;
  }
}
