import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  final ImagePicker _picker = ImagePicker();

  File? imagem;

  Future<void> tirarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );

    if (foto != null) {
      setState(() {
        imagem = File(foto.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Câmera')),
      body: Center(
        child: imagem == null
            ? const Text('Nenhuma foto')
            : Image.file(imagem!),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: tirarFoto,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}