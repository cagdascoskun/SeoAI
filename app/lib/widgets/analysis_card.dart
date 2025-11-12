import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';

class AnalysisCard extends StatelessWidget {
  const AnalysisCard({super.key, required this.analysis, required this.onTap});

  final AnalysisModel analysis;
  final VoidCallback onTap;

  Color _statusColor(String status) {
    switch (status) {
      case 'done':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = analysis.imageUrl;
    final title = analysis.seoOutput?.title ?? 'Analysis in progress';
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        onTap: onTap,
        leading: image == null
            ? CircleAvatar(
                backgroundColor: _statusColor(analysis.status).withValues(alpha: 0.15),
                child: Icon(Icons.auto_awesome, color: _statusColor(analysis.status)),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(image, width: 56, height: 56, fit: BoxFit.cover),
              ),
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(analysis.status.toUpperCase()),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
