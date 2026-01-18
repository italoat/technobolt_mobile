import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // URL JÁ ATUALIZADA PARA O SEU RENDER
  static const String baseUrl = "https://technobolt-backend.onrender.com";

  Future<Map<String, dynamic>> login(String usuario, String senha) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"usuario": usuario, "senha": senha}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['sucesso']) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_data', jsonEncode(data));
        }
        return data;
      } else {
        return {"sucesso": false, "mensagem": "Erro servidor: ${response.statusCode}"};
      }
    } catch (e) {
      return {"sucesso": false, "mensagem": "Erro conexão: $e"};
    }
  }

  Future<Map<String, dynamic>> analisar({
    required File imagem,
    required String usuario,
    required String peso,
    required String altura,
    required String objetivo,
    required String genero,
    String rA = "Nenhuma",
    String rM = "Nenhum",
    String rF = "Nenhuma",
  }) async {
    var uri = Uri.parse('$baseUrl/analisar');
    var request = http.MultipartRequest('POST', uri);

    request.fields['usuario'] = usuario;
    request.fields['peso'] = peso;
    request.fields['altura'] = altura;
    request.fields['objetivo'] = objetivo;
    request.fields['genero'] = genero;
    request.fields['restricoes_a'] = rA;
    request.fields['restricoes_m'] = rM;
    request.fields['restricoes_f'] = rF;

    var pic = await http.MultipartFile.fromPath("file", imagem.path);
    request.files.add(pic);

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {"sucesso": false, "mensagem": "Erro análise: ${response.body}"};
      }
    } catch (e) {
      return {"sucesso": false, "mensagem": "Erro upload: $e"};
    }
  }
}
