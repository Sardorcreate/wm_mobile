import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:wm_mobile/core/config/app_config.dart';
import 'package:wm_mobile/core/files/file_export.dart';
import 'package:wm_mobile/core/network/api_client.dart';

import 'tools_models.dart';

/// The `/tools/...` endpoints used by the stock screens.
///
/// Failures arrive as [ApiException], with a message ready to show.
class ToolsApi {
  ToolsApi(this._client);

  final ApiClient _client;

  static const _badFormat = "Server javobi noto'g'ri formatda.";

  Uri _uri(StockType type, String action, [Map<String, String>? query]) =>
      AppConfig.endpoint('/tools/${type.path}/$action', query);

  void _throwIfFailed(http.Response response) {
    if (response.isOk) return;
    throw ApiException(
      response.errorMessage('Server xatoligi (${response.statusCode})'),
      statusCode: response.statusCode,
    );
  }

  Map<String, dynamic> _decodeObject(http.Response response) {
    try {
      return jsonDecode(response.text) as Map<String, dynamic>;
    } on FormatException {
      throw const ApiException(_badFormat);
    } on TypeError {
      throw const ApiException(_badFormat);
    }
  }

  /// `POST /tools/{type}/{page}`. Pages count from 1.
  Future<StockPage> search(
    StockType type,
    StockFilters filters, {
    String? name,
    int page = 1,
  }) async {
    final response = await _client.post(
      _uri(type, '$page'),
      json: filters.toRequest(type, name),
    );

    // Some endpoints answer "nothing matched" with a 404, others with an empty
    // page. Both mean the same thing.
    if (response.statusCode == 404) return StockPage.empty;
    _throwIfFailed(response);

    try {
      return StockPage.fromJson(type, _decodeObject(response));
    } on TypeError {
      throw const ApiException(_badFormat);
    }
  }

  /// `DELETE /tools/{type}/delete`. Returns the server's confirmation.
  Future<String> delete(StockType type, int id) async {
    final response = await _client.delete(_uri(type, 'delete', {'id': '$id'}));
    _throwIfFailed(response);
    return response.text;
  }

  /// `GET /tools/{order|outcome}/get_one`, which answers with an Excel file.
  Future<DownloadedFile> downloadDocument(StockType type, int id) async {
    final response = await _client.get(_uri(type, 'get_one', {'id': '$id'}));
    _throwIfFailed(response);
    return DownloadedFile(
      bytes: response.bodyBytes,
      name: FileExport.fileNameFrom(
        response.headers['content-disposition'],
        '${type.path}_$id.xlsx',
      ),
      mimeType:
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  Future<ToolDetails> getTool(int id) async {
    final response = await _client.get(
      _uri(StockType.tool, 'get_one', {'id': '$id'}),
    );
    _throwIfFailed(response);
    return ToolDetails.fromJson(_decodeObject(response));
  }

  /// Fills in an inactive tool, which also moves it to the warehouse.
  Future<String> activateTool(
    int id, {
    required String inventoryId,
    required String description,
  }) async {
    final response = await _client.put(
      _uri(StockType.tool, 'update'),
      json: {'id': id, 'inventoryId': inventoryId, 'description': description},
    );
    _throwIfFailed(response);
    return response.text;
  }

  Future<String> updateDescription(int id, String description) async {
    final response = await _client.put(
      _uri(StockType.tool, 'update_description', {
        'id': '$id',
        'description': description,
      }),
    );
    _throwIfFailed(response);
    return response.text;
  }

  /// Takes a tool back from its owner into the warehouse.
  Future<String> takeAway(int id) async {
    final response = await _client.put(
      _uri(StockType.tool, 'take_away', {'id': '$id'}),
    );
    _throwIfFailed(response);
    return response.text;
  }

  /// `GET /tools/tool/get_qr`, the printable QR and barcode sheet.
  Future<DownloadedFile> qrSheet(int id) async {
    final response = await _client.get(
      _uri(StockType.tool, 'get_qr', {'id': '$id'}),
    );
    _throwIfFailed(response);

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('application/pdf')) {
      throw const ApiException(_badFormat);
    }
    return DownloadedFile(
      bytes: response.bodyBytes,
      name: FileExport.fileNameFrom(
        response.headers['content-disposition'],
        'tool_${id}_codes.pdf',
      ),
      mimeType: 'application/pdf',
    );
  }
}
