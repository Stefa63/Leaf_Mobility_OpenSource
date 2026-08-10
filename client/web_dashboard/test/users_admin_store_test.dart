// Test dello store Gestione Utenti/AP alimentato da /api/v1/utenti (Blocco 1, OP.10/17/18).

import 'package:flutter_test/flutter_test.dart';

import 'package:web_dashboard/api/api_client.dart';
import 'package:web_dashboard/api/users_admin_repository.dart';
import 'package:web_dashboard/data/users_admin_data.dart';
import 'package:web_dashboard/data/users_admin_store.dart';

/// GestioneUtentiApi fittizia: account deterministici (o errore di rete).
class _FakeUtenti implements GestioneUtentiApi {
  _FakeUtenti({this.errore = false});
  final bool errore;
  String? ultimoStato;

  @override
  Future<List<Map<String, dynamic>>> elencoAccount({String? ruolo}) async {
    if (errore) throw LeafApiException('rete giù');
    if (ruolo == 'PA') {
      return [
        {
          '_id': 'pa-1',
          'email': 'ente@comune.test',
          'username': 'pa.uno',
          'nominativo': 'Comune di Zootropolis',
          'password_temporanea': true,
        },
      ];
    }
    return [
      {
        '_id': 'ut-1',
        'email': 'utente@leaf.test',
        'username': 'utente.uno',
        'nominativo': 'Mario Bianchi',
        'stato_account': 'attivo',
      },
    ];
  }

  @override
  Future<Map<String, dynamic>> impostaStato(
    String idAccount,
    String stato,
  ) async {
    ultimoStato = stato;
    return {'_id': idAccount, 'stato_account': stato};
  }

  @override
  Future<Map<String, dynamic>> provisionaPa({
    required String email,
    required String username,
    required String ente,
    required String emailIstituzionale,
  }) async {
    return {'id_account': 'pa-new', 'password_temporanea': 'Tmp!2026xy'};
  }
}

void main() {
  setUp(() {
    UsersAdminStore.users.value = const [];
    UsersAdminStore.apAccounts.value = const [];
    UsersAdminStore.offline.value = false;
  });

  test('ManagedUser.daApi mappa nominativo e stato', () {
    final u = ManagedUser.daApi({
      '_id': 'ut-1',
      'email': 'x@leaf.test',
      'username': 'x',
      'nominativo': 'Mario Bianchi',
      'stato_account': 'sospeso',
    });
    expect(u, isNotNull);
    expect(u!.name, 'Mario Bianchi');
    expect(u.status, UserStatus.sospeso);
  });

  test('ApAccount.daApi marca il primo accesso da password temporanea', () {
    final a = ApAccount.daApi({
      '_id': 'pa-1',
      'email': 'e@comune.test',
      'nominativo': 'Ente X',
      'password_temporanea': true,
    });
    expect(a!.status, ApStatus.primoAccesso);
  });

  test('carica popola utenti e AP dai dati reali', () async {
    await UsersAdminStore.carica(repo: _FakeUtenti());
    expect(UsersAdminStore.users.value.single.id, 'ut-1');
    expect(UsersAdminStore.apAccounts.value.single.ente, 'Comune di Zootropolis');
    expect(UsersAdminStore.offline.value, isFalse);
  });

  test('carica segnala offline senza fabbricare dati', () async {
    await UsersAdminStore.carica(repo: _FakeUtenti(errore: true));
    expect(UsersAdminStore.offline.value, isTrue);
    expect(UsersAdminStore.users.value, isEmpty); // nessun dato di riserva fabbricato
  });

  test('impostaStato sospende l\'utente nello store (OP.10)', () async {
    final repo = _FakeUtenti();
    await UsersAdminStore.carica(repo: repo);
    await UsersAdminStore.impostaStato('ut-1', sospendi: true, repo: repo);
    expect(repo.ultimoStato, 'sospeso');
    expect(UsersAdminStore.users.value.single.status, UserStatus.sospeso);
  });

  test('provisionaPa restituisce la password temporanea (OP.17)', () async {
    final temp = await UsersAdminStore.provisionaPa(
      email: 'n@comune.test',
      username: 'nuova',
      ente: 'Ente Nuovo',
      emailIstituzionale: 'ist@comune.test',
      repo: _FakeUtenti(),
    );
    expect(temp, 'Tmp!2026xy');
  });
}
