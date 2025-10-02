import 'dart:convert';
import 'dart:io';
import 'package:http/io_client.dart';

class UserService {
  final String baseUrl = "https://clubfrance.org.mx/api/get_user.php";

  Future<Map<String, dynamic>> getUser(String email) async {
    try {
      HttpClient httpClient = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      IOClient client = IOClient(httpClient);

      final response = await client.post(
        Uri.parse(baseUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        return {"success": false, "message": "Error en el servidor"};
      }
    } catch (e) {
      return {"success": false, "message": "Error de conexión: $e"};
    }
  }
}
