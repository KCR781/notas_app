import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/nota.dart';

class NotaViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  List<Nota> _notas = [];

  List<Nota> get notas => List.unmodifiable(_notas);

  Future<void> create(Nota nota) async {
    try {
      // Permite criar notas sem exigir autenticação.
      // Se um usuário estiver conectado, armazena o uid; caso contrário, deixa o userId nulo.
      final user = _auth.currentUser;
      final id = Uuid().v4();
      
      final novaNota = Nota(
        id: id,
        title: nota.title,
        conteudo: nota.conteudo,
        timestamp: DateTime.now(),
        userId: user?.uid ?? ''
      );

      await _firestore.collection('notas').doc(id).set(novaNota.toJson());
      _notas.add(nota);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao criar nota: $e');
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    try {
      await _firestore.collection('notas').doc(id).delete();
      _notas.removeWhere((e) => e.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao deletar nota: $e');
      rethrow;
    }
  }

  Future<void> update(Nota nota) async {
    try {
      // Permite atualizações sem exigir verificações de autenticação/propriedade.
      await _firestore.collection('notas').doc(nota.id).update(nota.toJson());

      var index = _notas.indexWhere((e) => e.id == nota.id);
      if (index != -1) {
        _notas[index] = nota;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar nota: $e');
      rethrow;
    }
  }

  Future<void> read() async {
    try {
      // Permite leituras sem autenticação: busca todas as notas.
      final snapshot = await _firestore.collection('notas').get();

      _notas = snapshot.docs.map((doc) => Nota.fromJson(doc.data())).toList();
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao ler notas: $e');
      rethrow;
    }
  }

  // Método para observar mudanças em tempo real
  void startListening() {
    // Começa a observar todas as notas, sem necessidade de autenticação para leituras.
    _firestore.collection('notas').snapshots().listen((snapshot) {
      _notas = snapshot.docs.map((doc) => Nota.fromJson(doc.data())).toList();
      notifyListeners();
    });
  }
}