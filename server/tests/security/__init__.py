"""! @package server.tests.security
@brief Gate di sicurezza critici della Controls Reference Matrix (§12.2): AG-SEC-01..04.

Suite dedicata ai quattro controlli di sicurezza marcati **Critical** nelle direttive
(`wiki/DIRECTIVES.md` §12.2), in precedenza DEFERRED in attesa del backend e ora
eseguibili offline sul client fake (FASE 3):

- @ref test_kyc_format — AG-SEC-01 / IIN-6: formati KYC ammessi solo PDF/JPG/PNG.
- @ref test_encryption — AG-SEC-02 / IIN-4: cifratura AES-256 dei campi 🔒 e dei
  documenti KYC a riposo.
- @ref test_mfa — AG-SEC-03 / IIN-9: login OP/PA impossibile senza OTP valido.
- @ref test_anonymization — AG-SEC-04 / IIN-15: dati delle dashboard PA non
  re-identificabili (nessun id individuale in output).

Tutti i test girano **senza emulatore e senza credenziali** (testabilità §12.2): la
verifica E2E contro l'emulatore Firestore live resta una verifica aggiuntiva (FASE 3).
"""
