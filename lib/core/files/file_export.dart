import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// A file received from the API.
class DownloadedFile {
  const DownloadedFile({
    required this.bytes,
    required this.name,
    required this.mimeType,
  });

  final Uint8List bytes;
  final String name;
  final String mimeType;
}

/// Hands downloaded files to the system share sheet, which covers opening them
/// in Excel, saving to Files, or sending them on.
abstract final class FileExport {
  /// Reads the filename out of a `Content-Disposition` header.
  ///
  /// The result is always safe to use as a single path segment: the name comes
  /// from the server and may contain `/` or `:` (one report name does contain a
  /// time such as `14:30`).
  static String fileNameFrom(String? header, String fallback) {
    final value = header ?? '';
    final encoded = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(value)?.group(1);

    String? name;
    if (encoded != null) {
      name = Uri.decodeComponent(encoded);
    } else {
      name = RegExp(r'filename="?([^";]+)"?').firstMatch(value)?.group(1);
    }

    final safe = (name ?? '')
        .trim()
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceFirst(RegExp(r'^\.+'), '');
    return safe.isEmpty ? fallback : safe;
  }

  static Future<void> share(BuildContext context, DownloadedFile file) async {
    // iPads anchor the share popover to this; it has to be read before the gap.
    final box = context.findRenderObject() as RenderBox?;
    final origin = box == null
        ? null
        : box.localToGlobal(Offset.zero) & box.size;

    final directory = await getTemporaryDirectory();
    final path = '${directory.path}${Platform.pathSeparator}${file.name}';
    await File(path).writeAsBytes(file.bytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(path, mimeType: file.mimeType)],
        sharePositionOrigin: origin,
      ),
    );
  }
}
