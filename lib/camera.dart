import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraPage2 extends StatefulWidget {
  const CameraPage2({super.key});

  @override
  State<CameraPage2> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage2> {
  final ImagePicker _picker = ImagePicker();

  File? imagem;

  Future<void> tirarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 100,
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