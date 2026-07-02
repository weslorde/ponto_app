import 'package:alarm/alarm.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ponto_app/espelho.dart';
import 'package:ponto_app/fotoCardWidget.dart';
import 'package:ponto_app/function.dart';

void main() async {
  Future<void> solicitarPermissoes() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Verifica o status atual da permissão de notificações
    var status = await Permission.notification.status;

    // 2. Se ainda não foi permitida, faz o pedido na tela
    if (status.isDenied) {
      await Permission.notification.request();
    }

    // 3. No Android 12 ou superior, também é bom pedir autorização para alarmes exatos
    if (await Permission.scheduleExactAlarm.isDenied) {
      await Permission.scheduleExactAlarm.request();
    }

    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }

    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    await [
      Permission.camera,
      Permission.photos,
      Permission.notification,
    ].request();
  }

  await solicitarPermissoes();

  await Alarm.init();

  runApp(MaterialApp(debugShowCheckedModeBanner: false, home: HomePage()));
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
    final dias = pontoService.agruparPorDia();

    print("MAP DIASSSssssssssss: $dias");

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
          // Parte principal da tela, mostrando a lista de registros
          : ListView.builder(
              itemCount: dias.length,
              itemBuilder: (context, index) {
                index =
                    dias.length -
                    1 -
                    index; //Inverter a ordem dos dias do mais recente para o mais antigo
                final List<String> chavesDias = dias.keys.toList();
                final List<Map<String, dynamic>> list =
                    dias[chavesDias[index]]!;

                final String dateIndex =
                    chavesDias[index]; //Facilitar a leitura do código do bloco abaixo

                // print("aaaaaaaaaaa   " + list.toString());

                //final data = DateTime.parse(item["data"]);

                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ExpansionTile(
                    initiallyExpanded: index == (dias.length - 1)
                        ? true
                        : false, //Abrir o Tile do dia mais atual.
                    title: Text(
                      "$dateIndex  -  ${pontoService.diaSemana(dateIndex)} ",
                    ),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "Entradas",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                RegistroCard(
                                  registro: list[0],
                                  index: index,
                                  pontoService: pontoService,
                                ),
                                if (list.length > 1)
                                  RegistroCard(
                                    registro: list[1],
                                    index: index,
                                    pontoService: pontoService,
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  "Saídas",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (list.length > 3)
                                  RegistroCard(
                                    registro: list[3],
                                    index: index,
                                    pontoService: pontoService,
                                  ),
                                if (list.length == 3) SizedBox(height: 200),
                                if (list.length > 2)
                                  RegistroCard(
                                    registro: list[2],
                                    index: index,
                                    pontoService: pontoService,
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
