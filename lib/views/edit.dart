import 'package:flutter/material.dart';
import 'package:notas_app/models/nota.dart';
import 'package:provider/provider.dart';

import '../viewmodels/notaviewmodel.dart';

class EditPage extends StatefulWidget {
  const EditPage({super.key});

  @override
  State<EditPage> createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController conteudoCtrl = TextEditingController();
  late final Nota nota;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    nota = ModalRoute.of(context)!.settings.arguments as Nota;
    titleCtrl.text = nota.title;
    conteudoCtrl.text = nota.conteudo;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Edita Nota"),
        actions: [
          IconButton(
            onPressed: () {
              var provider = Provider.of<NotaViewModel>(context, listen: false);
              provider.update(Nota(
                id: nota.id,
                title: titleCtrl.text,
                conteudo: conteudoCtrl.text,
                timestamp: DateTime.now(),
                userId: nota.userId
              ));
              Navigator.pop(context);
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