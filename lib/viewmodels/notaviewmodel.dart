import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../models/nota.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class NotaViewModel extends ChangeNotifier {

  final String url = "https://sheetdb.io/api/v1/7u6kxme44sp1k";

  List<Nota> _notas = [];

  List<Nota> get notas => List.unmodifiable(_notas);

  void create(Nota nota) {
    nota.id = Uuid().v4();
    _notas.add(nota);

    // EDITAR ESTE BLOCO PARA FIRESTORE, REAL TIME e SUPABASE
    http.post(
      Uri.parse(url),
      body: json.encode(nota.toJson()),
      headers: {
        "Content-Type": "application/json"
      }
    );
    // EDITAR ESTE BLOCO PARA FIRESTORE, REAL TIME e SUPABASE

    notifyListeners();
  }

  void delete(String id) {
    _notas.removeWhere((e) => e.id == id);
    
    // EDITAR ESTE BLOCO PARA FIRESTORE, REAL TIME e SUPABASE
    http.delete(Uri.parse("$url/id/$id"));
    // EDITAR ESTE BLOCO PARA FIRESTORE, REAL TIME e SUPABASE

    notifyListeners();
  }

  void update(Nota nota) {
    // for(var _nota in notas) {
    //   if(_nota.id == nota.id) {
    //     _nota.title = nota.title;
    //   }
    // }
    var _nota = notas.where((e) => e.id == nota.id).first;
    _nota.title = nota.title;

    // EDITAR ESTE BLOCO PARA FIRESTORE, REAL TIME e SUPABASE
    print("$url/id/${nota.id}");
    http.put(
      Uri.parse("$url/id/${nota.id}"),
      body: json.encode(nota.toJson()),
      headers: {
        "Content-Type": "application/json"
      }
    );
    // EDITAR ESTE BLOCO PARA FIRESTORE, REAL TIME e SUPABASE

    notifyListeners();
  }

  void read() {

    // EDITAR ESTE BLOCO PARA FIRESTORE, REAL TIME e SUPABASE
    http.get(Uri.parse(url))
    .then((response) {
      var jsonList = json.decode(response.body) as List;
      _notas = jsonList.map((e) => Nota.fromJson(e)).toList();
    })
    .whenComplete(() {
      notifyListeners();
    });
    // EDITAR ESTE BLOCO PARA FIRESTORE, REAL TIME e SUPABASE
  }
}