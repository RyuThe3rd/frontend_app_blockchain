import 'dart:convert';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart' as basic_utils;
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/ecc/api.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:pointycastle/signers/ecdsa_signer.dart';
import 'package:pointycastle/ecc/curves/secp256k1.dart';
import 'package:app_pfc_blockchain/Domain/entidade/DocumentoDeExtratoBancario.dart';
import '../Services/clienteApiBlockchain.dart';
import 'package:pointycastle/api.dart';


class DocumentoRepo {
  Future<DocumentoDeExtratoBancario> processarQrCode({
    required String textoDoQrCode,
    required String nomeDoBanco,
  }) async {
    bool assinaturaValida = false;
    bool extratoConstaNoBlockchain = false;

    try {
      // 1. Busca a chave pública bruta do banco no mock (Base64/Hex do Ponto SEC1)
      final chavePublicaBase64 =
      await ClienteApiBlockchainMock.getChavePublicaDoBanco(nomeDoBanco);

      // 2. Decodifica Base64 -> Bytes (Deve ser o Ponto Bruto)
      final publicKeyBytes = base64Decode(chavePublicaBase64);

      // 3. Parseia o JSON do QR code
      final payload = jsonDecode(textoDoQrCode) as Map<String, dynamic>;
      final assinaturaHex = payload.remove('assinaturaBanco') as String;

      // 4. Re-encoda o payload SEM assinatura (JSON UTF-8)
      final mensagem = Uint8List.fromList(utf8.encode(jsonEncode(payload)));

      // 5. Converte a assinatura Hex -> Bytes (Estritamente RAW 64 bytes)
      final assinaturaBytes = hexToBytes(assinaturaHex);

      // 6. Verifica a Assinatura Criptográfica na curva secp256k1 com Hardening
      assinaturaValida = verificarAssinaturaSecp256k1(
        publicKeyBytes: publicKeyBytes,
        dadosOriginalBytes: mensagem,
        assinaturaBytes: assinaturaBytes,
      );

      // 7. Hash SHA-256 do payload para consulta na Blockchain
      final hashBytes = SHA256Digest().process(mensagem);
      final hashDoPayload = bytesToHex(hashBytes);

      if (assinaturaValida) {
        extratoConstaNoBlockchain = await ClienteApiBlockchainMock
            .extratoConstaNoBlockchain(hashDoPayload);
      }

      if (!assinaturaValida) {
        return DocumentoDeExtratoBancario(payload)
          ..isDocumentoVeridico = false
          ..mensagemDeErro = 'A assinatura digital deste extrato é inválida.';
      }

      if (!extratoConstaNoBlockchain) {
        return DocumentoDeExtratoBancario(payload)
          ..isDocumentoVeridico = false
          ..mensagemDeErro = 'O extrato não consta ou foi revogado na Blockchain.';
      }

      return DocumentoDeExtratoBancario(payload)
        ..isDocumentoVeridico = true;
    } catch (e, st) {
      print('ERRO em processarQrCode: $e');
      print(st);
      throw DocumentoException(
        'Houve um erro ao processar o QR Code:\n$e',
      );
    }
  }
}

/// Valida uma assinatura ECDSA secp256k1 com validação estrita de Ponto Bruto (Hardening)
bool verificarAssinaturaSecp256k1({
  required Uint8List publicKeyBytes, // Estritamente Ponto Bruto SEC1 (64, 65 ou 33 bytes)
  required Uint8List dadosOriginalBytes,
  required Uint8List assinaturaBytes, // Estritamente RAW (64 bytes: R || S)
}) {
  final domainParams = ECCurve_secp256k1();
  Uint8List sec1Bytes;

  // HARDENING 1: Rejeição de cabeçalhos ASN.1/DER (Chaves que começam com a tag ASN.1 0x30)
  if (publicKeyBytes.isNotEmpty && publicKeyBytes[0] == 0x30) {
    throw SecurityException(
      "Violacao de Hardening: Envolucros ASN.1/DER sao rejeitados. Apenas o ponto bruto SEC1 e aceite.",
    );
  }

  // Normalização do Ponto Bruto Não-Comprimido
  if (publicKeyBytes.length == 64) {
    // Se forem passadas apenas as coordenadas X||Y (64 bytes), adiciona o prefixo 0x04
    sec1Bytes = Uint8List(65)
      ..[0] = 0x04
      ..setRange(1, 65, publicKeyBytes);
  } else if (publicKeyBytes.length == 65 || publicKeyBytes.length == 33) {
    sec1Bytes = publicKeyBytes;
  } else {
    throw FormatException(
      "Tamanho invalido de Chave Publica (${publicKeyBytes.length} bytes). Esperado ponto bruto SEC1 de 33, 64 ou 65 bytes.",
    );
  }

  // Descodificação direta do ponto geométrico na curva secp256k1
  final pointQ = domainParams.curve.decodePoint(sec1Bytes);

  // HARDENING: Verifica se o ponto foi descodificado e não é o ponto no infinito
  if (pointQ == null || pointQ.isInfinity) {
    throw FormatException("O ponto fornecido nao pertence a curva secp256k1 ou e o ponto no infinito.");
  }

  final publicKey = ECPublicKey(pointQ, domainParams);

  // Instancia o verificador ECDSA (SHA-256 + secp256k1)
  final signer = ECDSASigner(SHA256Digest(), HMac(SHA256Digest(), 64));
  signer.init(false, PublicKeyParameter<ECPublicKey>(publicKey));

  // HARDENING 2: Validação estrita do formato da assinatura (RAW 64 bytes: R || S)
  if (assinaturaBytes.length != 64) {
    throw FormatException(
      "Violacao de Hardening: A assinatura deve conter estritamente 64 bytes (RAW R||S). Formato recebido com ${assinaturaBytes.length} bytes.",
    );
  }

  final rBytes = assinaturaBytes.sublist(0, 32);
  final sBytes = assinaturaBytes.sublist(32, 64);
  final r = BigInt.parse(bytesToHex(rBytes), radix: 16);
  final s = BigInt.parse(bytesToHex(sBytes), radix: 16);

  final ecSignature = ECSignature(r, s);

  return signer.verifySignature(dadosOriginalBytes, ecSignature);
}

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

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => message;
}

