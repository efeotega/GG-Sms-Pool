import 'package:http/http.dart' as http;

class DaisySMSProxy {
  final String baseUrl;

  DaisySMSProxy(this.baseUrl);

  /// Get a number
  Future<Map<String, dynamic>> getNumber({
  required String apiKey,
  required String action,
  required String service,
  required double maxPrice,
}) async {
  final uri = Uri.parse('$baseUrl/getNumber').replace(queryParameters: {
    'api_key': apiKey,
    'action': action,
    'service': service,
    'max_price': maxPrice.toString(),
  });

  final response = await http.get(uri);

  if (response.statusCode == 200) {
    return {
      'statusCode': response.statusCode,
      'body': response.body,
    };
  } else {
    print(uri);
    throw Exception('Failed to fetch number: ${response.body}');
  }
}

  /// Check SMS status
  Future<String> getStatus({
    required String apiKey,
    required String action,
    required String id,
  }) async {
    final uri = Uri.parse('$baseUrl/getStatus').replace(queryParameters: {
      'api_key': apiKey,
      'action': action,
      'id': id,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return response.body; // The API response
    } else {
      throw Exception('Failed to fetch status: ${response.body}');
    }
  }

  /// Retrieve SMS code
  Future<String> getCode({
    required String apiKey,
    required String id,
  }) async {
    final uri = Uri.parse('$baseUrl/getCode').replace(queryParameters: {
      'api_key': apiKey,
      'id': id,
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      if(response.body=="STATUS_WAIT_CODE"){
        return "waiting for code";
      }
      if
      (response.body=="STATUS_CANCEL"){
        return "order cancelled";
      }
       if
      (response.body.contains("STATUS_OK")){
        List<String> data=response.body.split(":");
        return data[1];
      }
      return response.body; // The API response
    } else {
      throw Exception('Failed to fetch code: ${response.body}');
    }
  }

  /// Cancel SMS
  Future<String> setStatus({
    required String apiKey,
    required String id,
    required int status,
  }) async {
    final uri = Uri.parse('$baseUrl/setStatus').replace(queryParameters: {
      'api_key': apiKey,
      'action': 'setStatus',
      'id': id,
      'status': status.toString(),
    });

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      return response.body; // The API response
    } else {
      throw Exception('Failed to cancel SMS: ${response.body}');
    }
  }
}
