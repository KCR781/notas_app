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

  NotaViewModel() {
    read();
  }

  void create(Nota nota) {
    nota.id = Uuid().v4();
    _notas.add(nota);
    // exemplo, para seminário:
    // firebase.collection('notas').add(nota);

    http.post(
      Uri.parse(url),
      body: json.encode(nota.toJson()),
      headers: {
        "Content-Type": "application/json"
      }
    );

    notifyListeners();
  }

  void delete(String id) {
    _notas.removeWhere((e) => e.id == id);
    
    http.delete(Uri.parse("$url/$id")).then((_) {});
    
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

    http.put(
      Uri.parse("$url/${nota.id}"),
      body: json.encode(nota.toJson()),
      headers: {
        "Content-Type": "application/json"
      }
    );

    notifyListeners();
  }

  void read() {
    http.get(Uri.parse(url)).then((response) {
      var jsonList = json.decode(response.body) as List;
      _notas = jsonList.map((e) => Nota.fromJson(e)).toList();
    }).whenComplete(() {
      notifyListeners();
    });
  }
}