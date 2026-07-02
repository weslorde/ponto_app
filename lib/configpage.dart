import 'package:flutter/material.dart';
import 'package:numberpicker/numberpicker.dart';
import 'function.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final pontoService = PontoService();

  int horas = 0;
  int minutos = 0;
  bool positivo = true;

  @override
  void initState() {
    super.initState();

    pontoService.onAtualizar = () {
      if (mounted) setState(() {});
    };

    pontoService.iniciar().then((_) {
      final total = pontoService.saldoAnterior;

      positivo = total >= 0;

      final abs = total.abs();

      horas = abs ~/ 60;
      minutos = abs % 60;

      setState(() {});
    });
  }

  String formatarSaldo(int minutos) {
    final horas = minutos ~/ 60;
    final mins = minutos.abs() % 60;
    final sinal = minutos < 0 ? "-" : "+";

    return "$sinal${horas.abs()}h ${mins.toString().padLeft(2, "0")}m";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Configurações")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Saldo anterior",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Text(
              "Saldo salvo: ${formatarSaldo(pontoService.saldoAnterior)}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: pontoService.saldoAnterior > 0
                    ? Colors.blue
                    : pontoService.saldoAnterior < 0
                    ? Colors.red
                    : Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    const Text("Horas"),
                    NumberPicker(
                      minValue: 0,
                      maxValue: 300,
                      value: horas,
                      onChanged: (v) => setState(() => horas = v),
                    ),
                  ],
                ),
                Column(
                  children: [
                    const Text("Minutos"),
                    NumberPicker(
                      minValue: 0,
                      maxValue: 59,
                      value: minutos,
                      onChanged: (v) => setState(() => minutos = v),
                    ),
                  ],
                ),
              ],
            ),

            SwitchListTile(
              title: Text(positivo ? "Saldo positivo" : "Saldo negativo"),
              value: positivo,
              onChanged: (v) => setState(() => positivo = v),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text("Salvar"),
              onPressed: () async {
                int total = horas * 60 + minutos;

                if (!positivo) total = -total;

                await pontoService.salvarSaldoAnterior(total);

                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("Saldo salvo!")));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
