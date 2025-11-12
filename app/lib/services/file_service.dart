import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

final fileServiceProvider = Provider<FileService>((ref) => FileService());

class PickedFileData {
  final Uint8List bytes;
  final String name;
  final String mimeType;

  const PickedFileData({required this.bytes, required this.name, required this.mimeType});
}

class FileService {
  final ImagePicker _picker = ImagePicker();

  Future<PickedFileData?> pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    return PickedFileData(
      bytes: bytes,
      name: file.name,
      mimeType: file.mimeType ?? 'image/jpeg',
    );
  }

  Future<PickedFileData?> pickCsv() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }
    final file = result.files.single;
    if (file.bytes == null) {
      throw Exception('CSV file could not be read');
    }
    return PickedFileData(
      bytes: file.bytes!,
      name: file.name,
      mimeType: _detectMimeType(file),
    );
  }

  String _detectMimeType(PlatformFile file) {
    final ext = file.extension?.toLowerCase();
    if (ext == 'csv') return 'text/csv';
    return 'application/octet-stream';
  }
}
