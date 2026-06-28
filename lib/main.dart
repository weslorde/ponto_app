import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:ponto_app/espelho.dart';

void main() {
  runApp(
    const MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()),
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final picker = ImagePicker();

  List<Map<String, dynamic>> registros = [];

  late Directory pasta;
  late File arquivoJson;

  @override
  void initState() {
    super.initState();
    iniciar();
  }

  Future<void> iniciar() async {
    pasta = await getApplicationDocumentsDirectory();

    final pastaFotos = Directory("${pasta.path}/fotos");

    if (!await pastaFotos.exists()) {
      await pastaFotos.create(recursive: true);
    }

    arquivoJson = File("${pasta.path}/registros.json");

    if (await arquivoJson.exists()) {
      final texto = await arquivoJson.readAsString();

      if (texto.isNotEmpty) {
        registros = List<Map<String, dynamic>>.from(jsonDecode(texto));
      }
    }

    setState(() {});
  }

  Future<void> salvarJson() async {
    await arquivoJson.writeAsString(jsonEncode(registros));
  }

  Future<void> tirarFoto() async {
    final foto = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );

    if (foto == null) return;

    final nome =
        "${DateTime.now().millisecondsSinceEpoch}${p.extension(foto.path)}";

    final destino = "${pasta.path}/fotos/$nome";

    await File(foto.path).copy(destino);

    registros.insert(0, {
      "foto": destino,
      "data": DateTime.now().toIso8601String(),
    });

    await salvarJson();

    setState(() {});
  }

  String formatar(DateTime d) {
    return "${d.day.toString().padLeft(2, "0")}/"
        "${d.month.toString().padLeft(2, "0")}/"
        "${d.year} "
        "${d.hour.toString().padLeft(2, "0")}:"
        "${d.minute.toString().padLeft(2, "0")}";
  }

  Future<void> excluir(int index) async {
    final caminho = registros[index]["foto"];

    final f = File(caminho);

    if (await f.exists()) {
      await f.delete();
    }

    registros.removeAt(index);

    await salvarJson();

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Registro de Ponto"),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EspelhoPontoPage()),
              );
            },
          ),
        ],
      ),

      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60.0),
        child: FloatingActionButton(
          onPressed: tirarFoto,
          child: const Icon(Icons.camera_alt),
        ),
      ),
      body: registros.isEmpty
          ? const Center(child: Text("Nenhum registro"))
          : ListView.builder(
              itemCount: registros.length,
              itemBuilder: (context, index) {
                final item = registros[index];

                final data = DateTime.parse(item["data"]);

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formatar(data),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(item["foto"]),
                            width: double.infinity,
                            height: 220,
                            fit: BoxFit.cover,
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                excluir(index);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
