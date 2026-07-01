import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ponto_app/function.dart';

class EspelhoPontoPage extends StatefulWidget {
  const EspelhoPontoPage({super.key});

  @override
  State<EspelhoPontoPage> createState() => _EspelhoPontoPageState();
}

class _EspelhoPontoPageState extends State<EspelhoPontoPage> {
  PontoService pontoService = PontoService();
  List<Map<String, dynamic>> registros = [];

  // @override
  // void initState() {
  //   super.initState();
  //   carregar();
  // }
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

  Future<File> getArquivo() async {
    final dir = await getApplicationDocumentsDirectory();
    return File("${dir.path}/registros.json");
  }

  Future<void> carregar() async {
    final file = await getArquivo();

    if (!await file.exists()) return;

    final texto = await file.readAsString();
    if (texto.isEmpty) return;

    registros = List<Map<String, dynamic>>.from(jsonDecode(texto));

    registros.sort(
      (a, b) => DateTime.parse(a["data"]).compareTo(DateTime.parse(b["data"])),
    );

    setState(() {});
  }

  // ===== SALDO POR DIA (TEXTO) =====
  String calcularSaldo(List<Map<String, dynamic>> lista) {
    if (lista.length < 2) return "incompleto";

    final entrada = DateTime.parse(lista.first["data"]);
    final saida = DateTime.parse(lista.last["data"]);

    const jornada = Duration(hours: 9);

    Duration tempoTotal = saida.difference(entrada);
    Duration almocoReal = Duration.zero;

    if (lista.length >= 3) {
      final saidaAlmoco = DateTime.parse(lista[1]["data"]);
      final voltaAlmoco = DateTime.parse(lista[2]["data"]);

      almocoReal = voltaAlmoco.difference(saidaAlmoco);
    }

    final trabalhoLiquido = tempoTotal - almocoReal;
    final saldo = trabalhoLiquido - jornada;

    final horas = saldo.inMinutes ~/ 60;
    final minutos = saldo.inMinutes.abs() % 60;

    final sinal = saldo.isNegative ? "-" : "+";

    return "$sinal${horas.abs()}h ${minutos.toString().padLeft(2, '0')}m";
  }

  // ===== SALDO POR DIA (MINUTOS) =====
  int saldoDiaMinutos(List<Map<String, dynamic>> lista) {
    if (lista.length < 2) return 0;

    final entrada = DateTime.parse(lista.first["data"]);
    final saida = DateTime.parse(lista.last["data"]);

    const jornada = Duration(hours: 9);

    Duration tempoTotal = saida.difference(entrada);
    Duration almocoReal = Duration.zero;

    if (lista.length >= 3) {
      final saidaAlmoco = DateTime.parse(lista[1]["data"]);
      final voltaAlmoco = DateTime.parse(lista[2]["data"]);

      almocoReal = voltaAlmoco.difference(saidaAlmoco);
    }

    final trabalhoLiquido = tempoTotal - almocoReal;
    final saldo = trabalhoLiquido - jornada;

    return saldo.inMinutes;
  }

  // ===== SALDO GERAL =====
  String saldoGeral(Map<String, List<Map<String, dynamic>>> dias) {
    int total = 0;

    for (var lista in dias.values) {
      total += saldoDiaMinutos(lista);
    }

    final horas = total ~/ 60;
    final minutos = total.abs() % 60;

    final sinal = total.isNegative ? "-" : "+";

    return "$sinal${horas.abs()}h ${minutos.toString().padLeft(2, '0')}m";
  }

  String hora(DateTime d) {
    return "${d.hour.toString().padLeft(2, '0')}:"
        "${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final dias = pontoService.agruparPorDia();
    final geral = saldoGeral(dias);

    return Scaffold(
      appBar: AppBar(title: const Text("Espelho de Ponto")),
      body: dias.isEmpty
          ? const Center(child: Text("Sem registros"))
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(10),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "Saldo geral: $geral",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Expanded(
                  child: ListView(
                    children: dias.entries.map((dia) {
                      final lista = dia.value;

                      return Card(
                        margin: const EdgeInsets.all(10),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dia.key,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 5),

                              Text(
                                "Saldo do dia: ${calcularSaldo(lista)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),

                              const Divider(),

                              ...List.generate(lista.length, (i) {
                                final r = lista[i];
                                final data = DateTime.parse(r["data"]);

                                String tipo;

                                switch (i) {
                                  case 0:
                                    tipo = "Entrada";
                                    break;
                                  case 1:
                                    tipo = "Saída Almoço";
                                    break;
                                  case 2:
                                    tipo = "Retorno Almoço";
                                    break;
                                  case 3:
                                    tipo = "Saída";
                                    break;
                                  default:
                                    tipo = "Extra";
                                }

                                return ListTile(
                                  leading: const Icon(Icons.access_time),
                                  title: Text(tipo),
                                  subtitle: Text(hora(data)),
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
    );
  }
}
