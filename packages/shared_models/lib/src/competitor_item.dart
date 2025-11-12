class CompetitorItem {
  final String id;
  final String title;
  final String? url;
  final String? imageUrl;
  final double? price;
  final double? similarityScore;
  final Map<String, dynamic>? meta;

  const CompetitorItem({
    required this.id,
    required this.title,
    this.url,
    this.imageUrl,
    this.price,
    this.similarityScore,
    this.meta,
  });

  factory CompetitorItem.fromJson(Map<String, dynamic> json) => CompetitorItem(
        id: json['id'] as String,
        title: json['title'] as String? ?? '',
        url: json['url'] as String?,
        imageUrl: json['image_url'] as String?,
        price: (json['price'] as num?)?.toDouble(),
        similarityScore: (json['similarity_score'] as num?)?.toDouble(),
        meta: json['meta'] as Map<String, dynamic>?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'url': url,
        'image_url': imageUrl,
        'price': price,
        'similarity_score': similarityScore,
        'meta': meta,
      };
}
