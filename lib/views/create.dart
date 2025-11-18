import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/nota.dart';
import '../viewmodels/notaviewmodel.dart';

class CreatePage extends StatefulWidget {
  const CreatePage({super.key});

  @override
  State<CreatePage> createState() => _CreatePageState();
}

class _CreatePageState extends State<CreatePage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController conteudoCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Nova Nota"),
        actions: [
          IconButton(
            onPressed: () async {
              // Salvar num banco de dados local (em memória).
              var provider = Provider.of<NotaViewModel>(context, listen: false);
              try {
                await provider.create(Nota(
                  id: DateTime.now().toString(),
                  title: titleCtrl.text,
                  conteudo: conteudoCtrl.text,
                  timestamp: DateTime.now(),
                  userId: ''
                ));
                if (context.mounted) {
                  Navigator.pop(context);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao criar nota: $e')),
                  );
                }
              }
            },
            icon: Icon(Icons.save)
          )
        ],
      ),
      body: Container(
        margin: EdgeInsets.all(10),
        child: Column(
          children: [
            TextField(
              controller: titleCtrl,
              decoration: InputDecoration(
                labelText: "Título",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: conteudoCtrl,
                keyboardType: TextInputType.multiline,
                maxLines: null,
                decoration: InputDecoration(
                  labelText: "Conteúdo",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ),
          ],
        ),
      )
    );
  }
}