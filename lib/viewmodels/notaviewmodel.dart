import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // UUID: gera identificadores únicos universais (ex: "550e8400-e29b-41d4-a716-446655440000")
import 'package:cloud_firestore/cloud_firestore.dart'; // Cloud Firestore: banco de dados NoSQL em tempo real do Firebase
import 'package:firebase_auth/firebase_auth.dart'; // Firebase Auth: gerencia autenticação de usuários (anônima, email/senha, Google, etc.)
import '../models/nota.dart';

/// NotaViewModel: gerencia o estado e a lógica de negócio das notas.
/// 
/// Responsabilidades:
/// - Comunicação com o Firestore (create, read, update, delete)
/// - Gerenciamento da lista de notas em memória (_notas)
/// - Notificação de mudanças para a UI (via ChangeNotifier)
/// 
/// IMPORTANTE: Este ViewModel NÃO implementa regras de segurança.
/// As regras de segurança são aplicadas no servidor Firebase (firestore.rules).
/// O código aqui apenas tenta fazer operações - o Firebase valida e aceita/rejeita.
class NotaViewModel extends ChangeNotifier {
  // FirebaseFirestore.instance: ponto de acesso ao banco Firestore
  // Permite criar/ler/atualizar/deletar documentos em coleções
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // FirebaseAuth.instance: ponto de acesso ao sistema de autenticação
  // Usado para verificar se há um usuário logado (currentUser)
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Lista privada de notas mantida em memória para acesso rápido da UI
  List<Nota> _notas = [];

  // Getter público: retorna uma lista imutável para impedir modificações diretas
  // A UI pode ler as notas, mas só pode modificá-las via métodos deste ViewModel
  List<Nota> get notas => List.unmodifiable(_notas);

  /// CREATE: Cria uma nova nota no Firestore
  /// 
  /// Fluxo:
  /// 1. Verifica se há um usuário autenticado (_auth.currentUser)
  /// 2. Gera um ID único usando UUID v4 (ex: "a3bb189e-8bf9-3888-9912-ace4e6543002")
  /// 3. Cria objeto Nota com timestamp atual e userId (vazio se não autenticado)
  /// 4. Salva no Firestore usando .set() - cria/sobrescreve documento
  /// 5. Adiciona à lista local e notifica ouvintes (UI) da mudança
  /// 
  /// Segurança: validação real acontece nas regras do Firestore, não aqui.
  Future<void> create(Nota nota) async {
    try {
      // FirebaseAuth.currentUser: retorna User? (nullable)
      // - Se usuário está logado: retorna objeto User com uid, email, etc.
      // - Se não há sessão ativa: retorna null
      final user = _auth.currentUser;
      
      // UUID().v4(): gera identificador único no formato RFC 4122
      // Exemplo: "550e8400-e29b-41d4-a716-446655440000"
      // v4 = random-based (não depende de MAC address ou timestamp sequencial)
      final id = Uuid().v4();
      
      // Cria nova instância de Nota com dados atualizados
      final novaNota = Nota(
        id: id,
        title: nota.title,
        conteudo: nota.conteudo,
        timestamp: DateTime.now(), // Timestamp do momento da criação
        userId: user?.uid ?? '' // Se user for null, usa string vazia
      );

      // Firestore.collection('notas'): acessa a coleção "notas"
      // .doc(id): referencia um documento específico pelo ID
      // .set(): cria ou sobrescreve o documento com os dados fornecidos
      // .toJson(): converte Nota para Map<String, dynamic> (formato Firestore)
      await _firestore.collection('notas').doc(id).set(novaNota.toJson());
      
      // Adiciona à lista local (cache em memória)
      _notas.add(novaNota); // NOTA: deve adicionar novaNota, não nota original
      
      // ChangeNotifier.notifyListeners(): avisa widgets que estão "ouvindo"
      // que os dados mudaram, fazendo-os reconstruir a UI
      notifyListeners();
    } catch (e) {
      // Captura erros do Firestore (ex: permissão negada, timeout, etc.)
      debugPrint('Erro ao criar nota: $e');
      rethrow; // Relança exceção para quem chamou este método tratar
    }
  }

  /// DELETE: Remove uma nota do Firestore
  /// 
  /// Fluxo:
  /// 1. Localiza o documento no Firestore pelo ID
  /// 2. Executa .delete() - remove completamente o documento
  /// 3. Remove da lista local usando removeWhere()
  /// 4. Notifica UI da mudança
  /// 
  /// Segurança: as regras Firestore validam se o usuário pode deletar.
  /// Se negado, este método lança FirebaseException e reverte apenas localmente.
  Future<void> delete(String id) async {
    try {
      // .delete(): remove permanentemente o documento do Firestore
      // Não há "soft delete" - o documento some completamente
      await _firestore.collection('notas').doc(id).delete();
      
      // removeWhere(): remove elementos da lista que satisfazem a condição
      // (e) => e.id == id: função que retorna true se o id bater
      _notas.removeWhere((e) => e.id == id);
      
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao deletar nota: $e');
      rethrow;
    }
  }

  /// UPDATE: Atualiza uma nota existente no Firestore
  /// 
  /// Fluxo:
  /// 1. Localiza o documento existente pelo ID
  /// 2. Usa .update() para modificar apenas os campos enviados
  /// 3. Atualiza o objeto correspondente na lista local
  /// 4. Notifica UI
  /// 
  /// Diferença entre .set() e .update():
  /// - .set(): sobrescreve documento inteiro (cria se não existir)
  /// - .update(): modifica apenas campos especificados (falha se não existir)
  /// 
  /// Segurança: regras Firestore validam se o usuário pode editar esta nota.
  Future<void> update(Nota nota) async {
    try {
      // .update(): atualiza campos do documento existente
      // Se o documento não existir, lança erro (diferente de .set())
      await _firestore.collection('notas').doc(nota.id).update(nota.toJson());

      // indexWhere(): procura o índice do primeiro elemento que satisfaz condição
      // Retorna -1 se não encontrar
      var index = _notas.indexWhere((e) => e.id == nota.id);
      if (index != -1) {
        // Substitui o objeto antigo pelo novo na lista local
        _notas[index] = nota;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao atualizar nota: $e');
      rethrow;
    }
  }

  /// READ: Busca todas as notas do Firestore (leitura única)
  /// 
  /// Fluxo:
  /// 1. Executa .get() na coleção "notas" - busca snapshot atual
  /// 2. Itera sobre os documentos retornados
  /// 3. Converte cada documento (Map) em objeto Nota
  /// 4. Substitui a lista local completa
  /// 5. Notifica UI
  /// 
  /// Tipo de query: one-time read (não escuta mudanças em tempo real)
  /// Para tempo real, use startListening() em vez deste método.
  /// 
  /// Segurança: regras Firestore determinam quais documentos são retornados.
  /// future significa que é uma operação assíncrona que pode levar tempo.
  Future<void> read() async {
    try {
      // .get(): executa query e retorna QuerySnapshot (resultado imediato)
      // É uma operação assíncrona que busca dados uma única vez
      final snapshot = await _firestore.collection('notas').get();

      // QuerySnapshot.docs: lista de QueryDocumentSnapshot
      // .map(): transforma cada documento em um objeto Nota
      // doc.data(): retorna Map<String, dynamic> com os campos do documento
      // Nota.fromJson(): factory constructor que converte Map → Nota
      // .toList(): converte Iterable em List
      _notas = snapshot.docs.map((doc) => Nota.fromJson(doc.data())).toList();
      
      notifyListeners();
    } catch (e) {
      // Possíveis erros: permissão negada, timeout, documento malformado
      debugPrint('Erro ao ler notas: $e');
      rethrow;
    }
  }

  /// START LISTENING: Escuta mudanças em tempo real na coleção "notas"
  /// 
  /// Fluxo:
  /// 1. .snapshots(): retorna um Stream\<QuerySnapshot\>
  /// 2. Stream emite um novo snapshot toda vez que a coleção muda
  /// 3. .listen(): registra callback que executa a cada nova emissão
  /// 4. Atualiza lista local e notifica UI automaticamente
  /// 
  /// Diferença entre .get() e .snapshots():
  /// - .get(): busca dados uma vez (Future) - você precisa chamar de novo
  /// - .snapshots(): cria listener permanente (Stream) - atualiza automaticamente
  /// 
  /// Performance: streams consomem uma leitura no Firestore a cada mudança.
  /// Para apps com muita escrita, considere estratégias de cache ou debounce.
  /// 
  /// IMPORTANTE: Este método não retorna StreamSubscription, então não pode
  /// ser cancelado facilmente. Em produção, considere retornar a subscription
  /// para poder fazer .cancel() quando o ViewModel for descartado.
  void startListening() {
    // .snapshots(): cria Stream que emite QuerySnapshot toda vez que
    // qualquer documento na coleção é adicionado/modificado/removido
    _firestore.collection('notas').snapshots().listen((snapshot) {
      // Este callback executa:
      // - Imediatamente com snapshot inicial
      // - Toda vez que algo mudar na coleção
      _notas = snapshot.docs.map((doc) => Nota.fromJson(doc.data())).toList();
      notifyListeners();
    });
  }
}