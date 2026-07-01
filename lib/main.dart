import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:ponto_app/espelho.dart';
import 'package:ponto_app/function.dart';

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
  final PontoService pontoService = PontoService();

  @override
  void initState() {
    super.initState();

    pontoService.onAtualizar = () {
      if (mounted) {
        setState(() {});
      }
    };

    pontoService.iniciar();
  }

  @override
  Widget build(BuildContext context) {
    // print(pontoService.registros);
    
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
          onPressed: pontoService.tirarFoto,
          child: const Icon(Icons.camera_alt),
        ),
      ),
      body: pontoService.registros.isEmpty
          ? const Center(child: Text("Nenhum registro"))
          : ListView.builder(
              itemCount: pontoService.registros.length,
              itemBuilder: (context, index) {
                final item = pontoService.registros[index];

                final data = DateTime.parse(item["data"]);

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pontoService.formatar(data),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: GestureDetector(
                            onLongPress: () async {
                              await OpenFilex.open(item["foto"]);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(item["foto"]),
                                width: double.infinity,
                                height: 220,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () async {
                                final data = await showDatePicker(
                                  context: context,
                                  initialDate: DateTime.parse(item["data"]),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );

                                if (data == null) return;

                                final hora = await showTimePicker(
                                  context: context,
                                  initialTime: TimeOfDay.fromDateTime(
                                    DateTime.parse(item["data"]),
                                  ),
                                );

                                if (hora == null) return;

                                final novaData = DateTime(
                                  data.year,
                                  data.month,
                                  data.day,
                                  hora.hour,
                                  hora.minute,
                                );

                                await pontoService.editarData(index, novaData);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                pontoService.excluir(index);
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
