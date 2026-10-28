/// Strongly-typed passenger review of a driver after a completed ride.
class Review {
  final String id;
  final String rideId;
  final String reviewerId;
  final String revieweeId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.rideId,
    required this.reviewerId,
    required this.revieweeId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic>? json) {
    final data = json == null ? <String, dynamic>{} : Map<String, dynamic>.from(json);
    return Review(
      id: data['id']?.toString() ?? '',
      rideId: data['ride_id']?.toString() ?? '',
      reviewerId: data['reviewer_id']?.toString() ?? '',
      revieweeId: data['reviewee_id']?.toString() ?? '',
      rating: _asInt(data['rating']) ?? 5,
      comment: data['comment']?.toString(),
      createdAt:
          DateTime.tryParse(data['created_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  static int? _asInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
