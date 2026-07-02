import 'package:flutter/material.dart';
import 'function.dart';

class EspelhoMensalPage extends StatefulWidget {
  const EspelhoMensalPage({super.key});

  @override
  State<EspelhoMensalPage> createState() => _EspelhoMensalPageState();
}

class _EspelhoMensalPageState extends State<EspelhoMensalPage> {
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
    final meses = pontoService.agruparPorMesESemana();

    if (pontoService.registros.isEmpty) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Espelho Mensal")),
      body: Column(
        children: [
          Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Text(
                    "Saldo Total",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pontoService.saldoGeral(pontoService.agruparPorDia()),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color:
                          pontoService
                              .saldoGeral(pontoService.agruparPorDia())
                              .startsWith("+")
                          ? Colors.blue
                          : pontoService
                                .saldoGeral(pontoService.agruparPorDia())
                                .startsWith("-")
                          ? Colors.red
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: meses.length,
              itemBuilder: (context, mesIndex) {
                mesIndex = meses.length - 1 - mesIndex;

                final mes = meses.keys.elementAt(mesIndex);
                final semanas = meses[mes]!;

                final saldoMes = pontoService.saldoMesMinutos(semanas);

                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            mes,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Text(
                          pontoService.saldoMes(semanas),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: saldoMes > 0
                                ? Colors.blue
                                : saldoMes < 0
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    children: List.generate(semanas.length, (semanaIndex) {
                      semanaIndex = semanas.length - 1 - semanaIndex;

                      final semana = semanas.keys.elementAt(semanaIndex);
                      final dias = semanas[semana]!;

                      final saldoSemana = pontoService.saldoSemanaMinutos(dias);

                      return Card(
                        color: Colors.blueGrey[50],
                        margin: const EdgeInsets.all(8),
                        child: ExpansionTile(
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "Semana $semana",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Text(
                                pontoService.saldoSemana(dias),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: saldoSemana > 0
                                      ? Colors.blue
                                      : saldoSemana < 0
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Table(
                                  border: TableBorder.all(
                                    color: Colors.black12,
                                  ),
                                  defaultColumnWidth:
                                      const IntrinsicColumnWidth(),
                                  children: [
                                    TableRow(
                                      children: dias.keys
                                          .map(
                                            (d) => Padding(
                                              padding: const EdgeInsets.all(6),
                                              child: Text(
                                                d.substring(0, 5),
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          )
                                          .toList(),
                                    ),

                                    linha(
                                      "E1",
                                      dias,
                                      (l) => l.isNotEmpty
                                          ? pontoService.cardFormatar(
                                              DateTime.parse(l[0]["data"]),
                                            )
                                          : "",
                                    ),

                                    linha(
                                      "S1",
                                      dias,
                                      (l) => l.length > 1
                                          ? pontoService.cardFormatar(
                                              DateTime.parse(l[1]["data"]),
                                            )
                                          : "",
                                    ),

                                    linha(
                                      "E2",
                                      dias,
                                      (l) => l.length > 2
                                          ? pontoService.cardFormatar(
                                              DateTime.parse(l[2]["data"]),
                                            )
                                          : "",
                                    ),

                                    linha(
                                      "S2",
                                      dias,
                                      (l) => l.length > 3
                                          ? pontoService.cardFormatar(
                                              DateTime.parse(l[3]["data"]),
                                            )
                                          : "",
                                    ),

                                    linha(
                                      "Saldo",
                                      dias,
                                      (l) => pontoService.calcularSaldo(l),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  TableRow linha(
    String titulo,
    Map<String, List<Map<String, dynamic>>> dias,
    String Function(List<Map<String, dynamic>>) valor,
  ) {
    return TableRow(
      children: dias.values
          .map(
            (l) => Padding(
              padding: const EdgeInsets.all(6),
              child: Text(
                valor(l),
                textAlign: TextAlign.center,
                style: titulo == "Saldo"
                    ? TextStyle(
                        fontWeight: FontWeight.bold,
                        color: pontoService.saldoDiaMinutos(l) > 0
                            ? Colors.blue
                            : pontoService.saldoDiaMinutos(l) < 0
                            ? Colors.red
                            : Colors.grey,
                      )
                    : null,
              ),
            ),
          )
          .toList(),
    );
  }
}
