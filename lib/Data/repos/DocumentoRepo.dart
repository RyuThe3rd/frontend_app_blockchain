import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart' as basic_utils;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';

import 'package:app_pfc_blockchain/Domain/entidade/DocumentoDeExtratoBancario.dart';
import '../Services/clienteApiBlockchain.dart';

class DocumentoRepo {
  Future<DocumentoDeExtratoBancario> processarQrCode({
    required String textoDoQrCode,
    required String nomeDoBanco,
  }) async {
    bool assinaturaValida = false;
    bool extratoConstaNoBlockchain = false;

    try {
      // 1. Busca a chave pública do banco no mock
      final chavePublicaBase64 =
      await ClienteApiBlockchainMock.getChavePublicaDoBanco(nomeDoBanco);

      // 2. Decodifica base64 -> DER -> ECPublicKey (pointycastle)
      final derBytes = base64Decode(chavePublicaBase64);
      final ecPub = basic_utils.CryptoUtils.ecPublicKeyFromDerBytes(derBytes);

      // 3. Parseia o JSON do QR code
      final payload = jsonDecode(textoDoQrCode) as Map<String, dynamic>;
      final assinaturaHex = payload.remove('assinaturaBanco') as String;

      // 4. Re-encoda o payload SEM assinatura (mesma string que foi assinada)
      final mensagem = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

      // 5. Converte hex -> bytes (r||s, 64 bytes)
      final assinaturaRaw = hexToBytes(assinaturaHex);

      // 6. Verifica
      assinaturaValida = _verificarEcdsa(
        assinaturaRaw: assinaturaRaw,
        pub: ecPub,
        mensagem: mensagem,
      );

      // 7. Hash do payload (pra consultar blockchain)
      final hashBytes = SHA256Digest().process(mensagem);
      final hashDoPayload = bytesToHex(hashBytes);

      if (assinaturaValida) {
        extratoConstaNoBlockchain = await ClienteApiBlockchainMock
            .extratoConstaNoBlockchain(hashDoPayload);
      }

      if (!assinaturaValida) {
        return DocumentoDeExtratoBancario(payload)
          ..isDocumentoVeridico = false
          ..mensagemDeErro = 'Este extrato não é válido.';
      }

      if (!extratoConstaNoBlockchain) {
        return DocumentoDeExtratoBancario(payload)
          ..isDocumentoVeridico = false
          ..mensagemDeErro = 'O extrato foi revogado pelo banco.';
      }

      return DocumentoDeExtratoBancario(payload)..isDocumentoVeridico = true;
    } catch (e, st) {
      print('ERRO em processarQrCode: $e');
      print(st);
      throw DocumentoException(
        'Houve um erro ao processar o QR Code:\n$e',
      );
    }
  }

  bool _verificarEcdsa({
    required Uint8List assinaturaRaw,
    required ECPublicKey pub,
    required Uint8List mensagem,
  }) {
    if (assinaturaRaw.length != 64) {
      throw FormatException(
        'Assinatura deve ter 64 bytes (r||s), mas tem ${assinaturaRaw.length}',
      );
    }

    final r = _bytesToBigInt(assinaturaRaw.sublist(0, 32));
    final s = _bytesToBigInt(assinaturaRaw.sublist(32, 64));

    final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64))
      ..init(false, basic_utils.PublicKeyParameter<ECPublicKey>(pub));

    return signer.verifySignature(mensagem, ECSignature(r, s));
  }
}

BigInt _bytesToBigInt(List<int> bytes) =>
    BigInt.parse(bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
        radix: 16);

String bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

Uint8List hexToBytes(String hexString) {
  var clean = hexString.startsWith('0x') ? hexString.substring(2) : hexString;
  if (clean.length.isOdd) clean = '0$clean';
  return Uint8List.fromList(List.generate(
    clean.length ~/ 2,
        (i) => int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16),
  ));
}

class DocumentoException implements Exception {
  final String? message;
  DocumentoException(this.message);

  @override
  String toString() => message ?? super.toString();
}