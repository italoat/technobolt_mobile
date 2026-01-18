import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:technobolt_mobile/services/api_service.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const HomeScreen({super.key, required this.userData});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  String? _resultadoMarkdown;

  // Controladores para inputs básicos
  final _pesoCtrl = TextEditingController(text: "80");
  final _alturaCtrl = TextEditingController(text: "175");
  String _objetivo = "Hipertrofia";

  Future<void> _pickImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(source: source);
    if (picked != null) {
      setState(() {
        _image = File(picked.path);
        _resultadoMarkdown = null; // Limpa resultado anterior se trocar foto
      });
    }
  }

  void _enviarAnalise() async {
    if (_image == null) return;
    setState(() => _isLoading = true);

    final res = await ApiService().analisar(
      imagem: _image!,
      usuario: widget.userData['usuario'],
      peso: _pesoCtrl.text,
      altura: _alturaCtrl.text,
      objetivo: _objetivo,
      genero: widget.userData['genero'] ?? "Masculino"
    );

    setState(() {
      _isLoading = false;
      if (res['sucesso'] == true) {
        _resultadoMarkdown = res['data']['conteudo_bruto'];
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['mensagem'] ?? "Erro"), backgroundColor: Colors.red));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Olá, ${widget.userData['nome'].split(' ')[0]}"),
        actions: [
           Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(child: Text("Créditos: ${widget.userData['creditos']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)))),
          )
        ],
      ),
      body: _resultadoMarkdown != null ? _buildResultado() : _buildConfigEScanner(),
    );
  }

  Widget _buildConfigEScanner() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Configuração Rápida
          Row(
            children: [
              Expanded(child: TextField(controller: _pesoCtrl, decoration: const InputDecoration(labelText: "Peso (kg)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 10),
              Expanded(child: TextField(controller: _alturaCtrl, decoration: const InputDecoration(labelText: "Altura (cm)", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: _objetivo,
            items: ["Hipertrofia", "Lipólise", "Performance", "Postural"]
                .map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: (v) => setState(() => _objetivo = v!),
            decoration: const InputDecoration(labelText: "Objetivo", border: OutlineInputBorder()),
          ),
          
          const SizedBox(height: 20),
          
          // Área da Foto
          Container(
            height: 300,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[800]!),
            ),
            child: _image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.camera_alt, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("Tire uma foto para analisar", style: TextStyle(color: Colors.grey))
                    ],
                  )
                : ClipRRect(borderRadius: BorderRadius.circular(16), child: Image.file(_image!, fit: BoxFit.cover)),
          ),
          
          const SizedBox(height: 20),
          
          Row(
            children: [
              Expanded(child: ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera), label: const Text("Câmera"))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton.icon(onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo), label: const Text("Galeria"))),
            ],
          ),
          
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_image != null && !_isLoading) ? _enviarAnalise : null,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white),
              child: _isLoading 
                ? const Text("PROCESSANDO IA...") 
                : const Text("INICIAR PROTOCOLO", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultado() {
    return Column(
      children: [
        Expanded(
          child: Markdown(
            data: _resultadoMarkdown!,
            styleSheet: MarkdownStyleSheet(
              h1: const TextStyle(color: Color(0xFF3B82F6), fontSize: 22, fontWeight: FontWeight.bold),
              p: const TextStyle(color: Colors.white, fontSize: 16),
              strong: const TextStyle(color: Color(0xFF3B82F6), fontWeight: FontWeight.bold),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.black,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => setState(() { _resultadoMarkdown = null; _image = null; }),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[800]),
              child: const Text("NOVA ANÁLISE", style: TextStyle(color: Colors.white)),
            ),
          ),
        )
      ],
    );
  }
}
