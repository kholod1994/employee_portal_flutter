import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

class FileAttachmentPreview extends StatelessWidget {
  final String? fileName;
  final String? fileData;
  final double imageSize;

  const FileAttachmentPreview({
    super.key,
    required this.fileName,
    required this.fileData,
    this.imageSize = 84,
  });

  Uint8List? _imageBytes() {
    final data = fileData;
    if (data == null || data.isEmpty || data.toLowerCase().contains('.pdf')) {
      return null;
    }
    final comma = data.indexOf(',');
    final encoded = data.startsWith('data:') && comma >= 0
        ? data.substring(comma + 1)
        : data;
    try {
      return base64Decode(encoded);
    } on FormatException {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _imageBytes();
    final isPdf = fileName?.toLowerCase().endsWith('.pdf') ?? false;
    if (bytes == null && fileName == null) return const SizedBox.shrink();

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: bytes == null
          ? null
          : () => showDialog<void>(
              context: context,
              builder: (context) => Dialog(
                child: InteractiveViewer(
                  child: Image.memory(bytes, fit: BoxFit.contain),
                ),
              ),
            ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (bytes != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                bytes,
                width: imageSize,
                height: imageSize,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => _fileIcon(isPdf),
              ),
            )
          else
            _fileIcon(isPdf),
          if (fileName != null) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: imageSize < 84 ? 120 : 180,
              child: Text(
                fileName!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _fileIcon(bool isPdf) => Container(
    width: imageSize,
    height: imageSize,
    decoration: BoxDecoration(
      color: const Color(0xFFF2F4F6),
      borderRadius: BorderRadius.circular(12),
    ),
    alignment: Alignment.center,
    child: Icon(
      isPdf ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded,
      color: isPdf ? Colors.redAccent : Colors.blueGrey,
      size: 32,
    ),
  );
}
