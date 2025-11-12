import 'dart:convert';

class SeoBasicOutput {
  final String title;
  final List<String> seoKeywords;
  final List<String> etsyTags;
  final String description;

  const SeoBasicOutput({
    required this.title,
    required this.seoKeywords,
    required this.etsyTags,
    required this.description,
  });

  factory SeoBasicOutput.fromJson(Map<String, dynamic> json) => SeoBasicOutput(
        title: json['title'] as String? ?? '',
        seoKeywords: (json['seo_keywords'] as List?)?.cast<String>() ?? const [],
        etsyTags: (json['etsy_tags'] as List?)?.cast<String>() ?? const [],
        description: json['description'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'seo_keywords': seoKeywords,
        'etsy_tags': etsyTags,
        'description': description,
      };
}

class AnalysisModel {
  final String id;
  final String status;
  final String? imageUrl;
  final SeoBasicOutput? seoOutput;
  final DateTime createdAt;

  const AnalysisModel({
    required this.id,
    required this.status,
    required this.imageUrl,
    required this.seoOutput,
    required this.createdAt,
  });

  factory AnalysisModel.fromJson(Map<String, dynamic> json) => AnalysisModel(
        id: json['id'] as String,
        status: json['status'] as String,
        imageUrl: json['image_url'] as String? ?? json['input_image_url'] as String?,
        seoOutput: _parseSeo(json['seo_output']),
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'status': status,
        'image_url': imageUrl,
        'seo_output': seoOutput?.toJson(),
        'created_at': createdAt.toIso8601String(),
      };

  static SeoBasicOutput? _parseSeo(dynamic raw) {
    if (raw == null) return null;
    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return SeoBasicOutput.fromJson(decoded);
        }
      } catch (_) {
        return null;
      }
    }
    if (raw is Map<String, dynamic>) {
      return SeoBasicOutput.fromJson(raw);
    }
    return null;
  }
}
