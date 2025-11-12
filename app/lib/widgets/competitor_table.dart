import 'package:flutter/material.dart';
import 'package:shared_models/shared_models.dart';
import 'package:url_launcher/url_launcher.dart';

class CompetitorTable extends StatelessWidget {
  const CompetitorTable({super.key, required this.items});

  final List<CompetitorItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Text('No competitors found');
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Title')),
          DataColumn(label: Text('Similarity')),
          DataColumn(label: Text('Price')),
        ],
        rows: items
            .map(
              (item) => DataRow(cells: [
                DataCell(GestureDetector(
                  onTap: () {
                    final url = item.url;
                    if (url != null) launchUrl(Uri.parse(url));
                  },
                  child: Text(item.title, style: const TextStyle(decoration: TextDecoration.underline)),
                )),
                DataCell(Text(item.similarityScore?.toStringAsFixed(2) ?? '-')),
                DataCell(Text(item.price?.toStringAsFixed(2) ?? '-')),
              ]),
            )
            .toList(),
      ),
    );
  }
}
