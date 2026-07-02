import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:external_path/external_path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PontoService {
  late File arquivoConfig;

  int saldoAnterior = 0; // em minutos

  VoidCallback onAtualizar = () {};

  final picker = ImagePicker();

  List<Map<String, dynamic>> registros = [];

  late Directory pasta;
  late File arquivoJson;

  Future<void> reconstruirJson() async {
    registros.clear();

    final arquivos = pasta.listSync().whereType<File>();

    for (final arquivo in arquivos) {
      final ext = p.extension(arquivo.path).toLowerCase();

      if (![".jpg", ".jpeg", ".png"].contains(ext)) continue;

      try {
        final millis = int.parse(p.basenameWithoutExtension(arquivo.path));

        registros.add({
          "foto": arquivo.path,
          "data": DateTime.fromMillisecondsSinceEpoch(millis).toIso8601String(),
        });
      } catch (_) {
        // Ignora arquivos que não seguem o padrão
      }
    }

    registros.sort((a, b) {
      final ta = int.parse(p.basenameWithoutExtension(a["foto"]));
      final tb = int.parse(p.basenameWithoutExtension(b["foto"]));

      return ta.compareTo(tb);
    });

    await salvarJson();
  }

  Future<void> iniciar() async {
    // JSON na pasta interna do app
    final pastaInterna = await getApplicationDocumentsDirectory();
    arquivoJson = File("${pastaInterna.path}/registros.json");

    if (!await arquivoJson.exists()) {
      await arquivoJson.writeAsString("[]");
    }

    // Pasta pública das fotos
    final pictures = await ExternalPath.getExternalStoragePublicDirectory(
      ExternalPath.DIRECTORY_PICTURES,
    );

    pasta = Directory("$pictures/fotosPonto");

    if (!await pasta.exists()) {
      await pasta.create(recursive: true);
    }
    //
    //Salvar Saldo anterior Json
    arquivoConfig = File("${pastaInterna.path}/config.json");

    if (!await arquivoConfig.exists()) {
      await arquivoConfig.writeAsString(jsonEncode({"saldoAnterior": 0}));
    }

    final config = jsonDecode(await arquivoConfig.readAsString());

    saldoAnterior = config["saldoAnterior"] ?? 0;
    //Fim salvar saldo anterior Json
    //

    // Reconstrói a lista a partir das fotos
    await reconstruirJson();

    onAtualizar.call();
  }

  Future<void> salvarJson() async {
    await arquivoJson.writeAsString(jsonEncode(registros));
  }

  Future<void> salvarSaldoAnterior(int minutos) async {
    saldoAnterior = minutos;

    await arquivoConfig.writeAsString(
      jsonEncode({"saldoAnterior": saldoAnterior}),
    );

    onAtualizar();
  }

  Future<void> tirarFoto() async {
    final foto = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 100,
    );

    if (foto == null) return;

    final dataTime = DateTime.now();

    final nome = "${dataTime.millisecondsSinceEpoch}${p.extension(foto.path)}";

    final destino = "${pasta.path}/$nome";

    await File(foto.path).copy(destino);

    registros.insert(0, {"foto": destino, "data": dataTime.toIso8601String()});

    await reconstruirJson();

    await verificarAlmoco(dataTime);

    onAtualizar.call();
  }

  Future<void> verificarAlmoco(DateTime dataRegistro) async {
    final quantidadeHoje = registros.where((r) {
      final data = DateTime.parse(r["data"]);

      return data.year == dataRegistro.year &&
          data.month == dataRegistro.month &&
          data.day == dataRegistro.day;
    }).length;

    if (quantidadeHoje == 2) {
      criarAlarme(dataRegistro);
    }
  }

  Future<void> criarAlarme(DateTime horario) async {
    await Alarm.set(
      alarmSettings: AlarmSettings(
        volumeSettings: VolumeSettings.fixed(volume: 1.0),
        id: 1,
        dateTime: horario.add(const Duration(minutes: 55)),
        assetAudioPath: 'assets/alarmsong.wav',
        loopAudio: false,
        vibrate: true,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        androidStopAlarmOnTermination: false,
        notificationSettings: NotificationSettings(
          title: 'Hora de voltar!',
          body: 'Seu horário de almoço terminou.',
          icon: '@mipmap/ic_launcher',
          stopButton: 'Parar',
          iconColor: Color.fromARGB(255, 145, 39, 39),
        ),
      ),
    );
    await Alarm.set(
      alarmSettings: AlarmSettings(
        volumeSettings: VolumeSettings.fixed(volume: 0.1),
        id: 2,
        dateTime: horario.add(const Duration(minutes: 58)),
        assetAudioPath: 'assets/alarmsong.wav',
        loopAudio: false,
        vibrate: true,
        warningNotificationOnKill: true,
        androidFullScreenIntent: true,
        androidStopAlarmOnTermination: false,
        notificationSettings: NotificationSettings(
          title: 'Hora de voltar!',
          body: 'Seu horário de almoço terminou.',
          icon: '@mipmap/ic_launcher',
          stopButton: 'Parar',
          iconColor: Color.fromARGB(255, 145, 39, 39),
        ),
      ),
    );
  }

  String formatar(DateTime d) {
    return "${d.day.toString().padLeft(2, "0")}/"
        "${d.month.toString().padLeft(2, "0")}/"
        "${d.year} "
        "${d.hour.toString().padLeft(2, "0")}:"
        "${d.minute.toString().padLeft(2, "0")}";
  }

  String cardFormatar(DateTime d) {
    return "${d.hour.toString().padLeft(2, "0")}:"
        "${d.minute.toString().padLeft(2, "0")}";
  }

  Future<void> excluir(String caminho) async {
    // 1. Deleta o arquivo físico da foto no dispositivo
    final f = File(caminho);
    if (await f.exists()) {
      try {
        await f.delete();
      } catch (e) {
        throw Exception(
          "Não foi possível deletar este arquivo. Para deletar acesse a pasta de fotos do celular e exclua manualmente.",
        );
      }
    }

    // 2. Remove o mapa correspondente de dentro da lista 'registros'
    registros.removeWhere((registro) => registro["foto"] == caminho);

    // 3. Salva a nova lista no arquivo JSON
    await reconstruirJson();

    // 4. Atualiza a tela
    onAtualizar.call();
  }

  Future<void> editarData(String caminhoFoto, DateTime novaData) async {
    final registro = registros.firstWhere((r) => r["foto"] == caminhoFoto);

    final arquivoAntigo = File(caminhoFoto);

    if (!await arquivoAntigo.exists()) return;

    final extensao = p.extension(caminhoFoto);
    final novoNome = "${novaData.millisecondsSinceEpoch}$extensao";
    final novoCaminho = "${pasta.path}/$novoNome";

    try {
      await arquivoAntigo.rename(novoCaminho);
    } catch (e) {
      throw Exception(
        "Não foi possível alterar este arquivo. Ele pode pertencer a uma instalação anterior do aplicativo.",
      );
    }

    registro["foto"] = novoCaminho;
    registro["data"] = novaData.toIso8601String();

    await reconstruirJson();

    onAtualizar();
  }

  Map<String, List<Map<String, dynamic>>> agruparPorDia() {
    Map<String, List<Map<String, dynamic>>> mapa = {};
    print(registros);
    for (var r in registros) {
      final data = DateTime.parse(r["data"]);

      final chave =
          "${data.day.toString().padLeft(2, '0')}/"
          "${data.month.toString().padLeft(2, '0')}/"
          "${data.year}";

      mapa.putIfAbsent(chave, () => []);
      mapa[chave]!.add(r);
    }

    //print("mapaaaaaaaaa:" + mapa.toString());
    return mapa;
  }

  String diaSemana(String data) {
    final partes = data.split('/');

    final dt = DateTime(
      int.parse(partes[2]), // ano
      int.parse(partes[1]), // mês
      int.parse(partes[0]), // dia
    );

    const dias = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];

    return dias[dt.weekday - 1];
  }

  int saldoDiaMinutos(List<Map<String, dynamic>> lista) {
  if (lista.length < 4) return 0;

  DateTime entrada = DateTime.parse(lista.first["data"]);
  DateTime saida = DateTime.parse(lista.last["data"]);

  final weekday = entrada.weekday;
  final quinta = weekday == DateTime.thursday;
  final fimDeSemana =
      weekday == DateTime.saturday || weekday == DateTime.sunday;

  final jornada = fimDeSemana
      ? Duration.zero
      : Duration(hours: quinta ? 8 : 9);

  // Ajustes apenas para dias úteis
  if (!fimDeSemana) {
    // Entrada: até 5 minutos antes das 07:00 conta como 07:00
    final entradaEsperada = DateTime(
      entrada.year,
      entrada.month,
      entrada.day,
      7,
      0,
    );

    final difEntrada = entradaEsperada.difference(entrada).inMinutes;

    if (difEntrada >= 0 && difEntrada <= 5) {
      entrada = entradaEsperada;
    }

    // Saída: até 5 minutos depois do horário conta como horário exato
    final horaSaida = quinta ? 16 : 17;

    final saidaEsperada = DateTime(
      saida.year,
      saida.month,
      saida.day,
      horaSaida,
      0,
    );

    final difSaida = saida.difference(saidaEsperada).inMinutes;

    if (difSaida >= 0 && difSaida <= 5) {
      saida = saidaEsperada;
    }
  }

  Duration tempoTotal = saida.difference(entrada);
  Duration almocoReal = Duration.zero;

  final saidaAlmoco = DateTime.parse(lista[1]["data"]);
  final voltaAlmoco = DateTime.parse(lista[2]["data"]);

  almocoReal = voltaAlmoco.difference(saidaAlmoco);

  final trabalhoLiquido = tempoTotal - almocoReal;
  final saldo = trabalhoLiquido - jornada;

  return saldo.inMinutes;
}

  // ===== SALDO POR DIA (TEXTO) =====
  String calcularSaldo(List<Map<String, dynamic>> lista) {
    if (lista.length < 2) return "incompleto";

    final minutosSaldo = saldoDiaMinutos(lista);

    final horas = minutosSaldo ~/ 60;
    final minutos = minutosSaldo.abs() % 60;

    final sinal = minutosSaldo < 0 ? "-" : "+";

    return "$sinal${horas.abs()}h ${minutos.toString().padLeft(2, '0')}m";
  }

  // ===== SALDO GERAL =====
  String saldoGeral(Map<String, List<Map<String, dynamic>>> dias) {
    int total = saldoAnterior;

    for (var lista in dias.values) {
      total += saldoDiaMinutos(lista);
    }

    final horas = total ~/ 60;
    final minutos = total.abs() % 60;

    final sinal = total.isNegative ? "-" : "+";

    return "$sinal${horas.abs()}h ${minutos.toString().padLeft(2, '0')}m";
  }

  Map<String, Map<int, Map<String, List<Map<String, dynamic>>>>>
  agruparPorMesESemana() {
    final dias = agruparPorDia();

    final resultado =
        <String, Map<int, Map<String, List<Map<String, dynamic>>>>>{};

    for (final entry in dias.entries) {
      final partes = entry.key.split('/');

      final data = DateTime(
        int.parse(partes[2]),
        int.parse(partes[1]),
        int.parse(partes[0]),
      );

      final mes = "${_nomeMes(data.month)}/${data.year}";

      // Semana do mês (1,2,3,4,5)
      final semana = ((data.day - 1) ~/ 7) + 1;

      resultado.putIfAbsent(mes, () => {});
      resultado[mes]!.putIfAbsent(semana, () => {});
      resultado[mes]![semana]![entry.key] = entry.value;
    }

    return resultado;
  }

  String _nomeMes(int mes) {
    const meses = [
      "Janeiro",
      "Fevereiro",
      "Março",
      "Abril",
      "Maio",
      "Junho",
      "Julho",
      "Agosto",
      "Setembro",
      "Outubro",
      "Novembro",
      "Dezembro",
    ];

    return meses[mes - 1];
  }

  int saldoSemanaMinutos(Map<String, List<Map<String, dynamic>>> dias) {
    int total = 0;

    for (final lista in dias.values) {
      total += saldoDiaMinutos(lista);
    }

    return total;
  }

  String saldoSemana(Map<String, List<Map<String, dynamic>>> dias) {
    final total = saldoSemanaMinutos(dias);

    final horas = total ~/ 60;
    final minutos = total.abs() % 60;

    final sinal = total < 0 ? "-" : "+";

    return "$sinal${horas.abs()}h ${minutos.toString().padLeft(2, '0')}m";
  }

  int saldoMesMinutos(
    Map<int, Map<String, List<Map<String, dynamic>>>> semanas,
  ) {
    int total = 0;

    for (final dias in semanas.values) {
      total += saldoSemanaMinutos(dias);
    }

    return total;
  }

  String saldoMes(Map<int, Map<String, List<Map<String, dynamic>>>> semanas) {
    final total = saldoMesMinutos(semanas);

    final horas = total ~/ 60;
    final minutos = total.abs() % 60;

    final sinal = total < 0 ? "-" : "+";

    return "$sinal${horas.abs()}h ${minutos.toString().padLeft(2, '0')}m";
  }

  // Fim função
}
