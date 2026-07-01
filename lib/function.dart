import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:external_path/external_path.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PontoService {
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

    // Reconstrói a lista a partir das fotos
    await reconstruirJson();

    onAtualizar.call();
  }

  Future<void> salvarJson() async {
    await arquivoJson.writeAsString(jsonEncode(registros));
  }

  Future<void> tirarFoto() async {
    final foto = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 100,
    );

    if (foto == null) return;

    final nome =
        "${DateTime.now().millisecondsSinceEpoch}${p.extension(foto.path)}";

    final destino = "${pasta.path}/$nome";

    await File(foto.path).copy(destino);

    registros.insert(0, {
      "foto": destino,
      "data": DateTime.now().toIso8601String(),
    });

    await salvarJson();

    onAtualizar.call();
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
      await f.delete();
    }

    // 2. Remove o mapa correspondente de dentro da lista 'registros'
    registros.removeWhere((registro) => registro["foto"] == caminho);

    // 3. Salva a nova lista no arquivo JSON
    await salvarJson();

    // 4. Atualiza a tela
    onAtualizar.call();
  }

  Future<void> editarData(int index, DateTime novaData) async {
    final caminhoAntigo = registros[index]["foto"];

    final arquivoAntigo = File(caminhoAntigo);

    if (!await arquivoAntigo.exists()) return;

    final extensao = p.extension(caminhoAntigo);

    final novoNome = "${novaData.millisecondsSinceEpoch}$extensao";

    final novoCaminho = "${pasta.path}/$novoNome";

    await arquivoAntigo.rename(novoCaminho);

    registros[index]["foto"] = novoCaminho;
    registros[index]["data"] = novaData.toIso8601String();

    await salvarJson();

    onAtualizar.call();
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
}
