import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _content = '';

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/content/faq.md').then((value) => setState(() => _content = value));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About / FAQ')),
      body: Markdown(data: _content, padding: const EdgeInsets.all(16)),
    );
  }
}
