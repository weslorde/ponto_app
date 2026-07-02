import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:ponto_app/function.dart';

class RegistroCard extends StatelessWidget {
  final PontoService pontoService;

  final Map<String, dynamic> registro;

  final int index;

  RegistroCard({
    super.key,
    required this.registro,
    required this.pontoService,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final data = DateTime.parse(registro["data"]);
    final foto = registro["foto"] as String;

    return Container(
      height: 200,
      width: double.infinity,
      child: Card(
        color: Colors.blueGrey[50],
        margin: const EdgeInsets.all(10),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                pontoService.cardFormatar(data),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              //Foto
              Expanded(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    GestureDetector(
                      onLongPress: () async {
                        await OpenFilex.open(foto);
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(foto),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                            size: 30,
                          ),
                          onPressed: () async {
                            final novaData = await _selecionarDataHora(
                              context,
                              data,
                            );

                            if (novaData != null) {
                              try {
                                await pontoService.editarData(foto, novaData);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceFirst(
                                        "Exception: ",
                                        "",
                                      ),
                                    ),
                                    duration: const Duration(seconds: 6),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                        SizedBox(height: 10),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                            size: 30,
                          ),
                          onPressed: () async {
                            try {
                              await pontoService.excluir(foto);
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    e.toString().replaceFirst(
                                      "Exception: ",
                                      "",
                                    ),
                                  ),
                                  duration: const Duration(seconds: 6),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> _selecionarDataHora(
    BuildContext context,
    DateTime inicial,
  ) async {
    final data = await showDatePicker(
      context: context,
      initialDate: inicial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (data == null) return null;

    final hora = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(inicial),
    );

    if (hora == null) return null;

    return DateTime(data.year, data.month, data.day, hora.hour, hora.minute);
  }
}
