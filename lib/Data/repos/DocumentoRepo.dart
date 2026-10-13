import 'dart:collection'; // Necessário para SplayTreeMap
import 'dart:convert';
import 'dart:typed_data';

import 'package:app_pfc_blockchain/Domain/entidade/DocumentoDeExtratoBancario.dart';
import 'package:pointycastle/digests/sha256.dart';
//import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import '../Services/clienteApiBlockchain.dart';

class DocumentoRepo {
  Future<DocumentoDeExtratoBancario> processarQrCode({
    required String textoDoQrCode,
    required String idDoBanco,
  }) async {
    bool assinaturaValida = false;
    bool extratoConstaNoBlockchain = false;

    try {
      // 1. Busca a operationalKey oficial do banco na blockchain (Endereço Hex ex: 0xaa70...)
      final String operationalKeyHex =
      await ClienteApiBlockchain().getChavePublicaDoBanco(idDoBanco);

      // 2. Parseia o JSON bruto lido do QR Code
      final payloadOriginal = jsonDecode(textoDoQrCode) as Map<String, dynamic>;

      // Remove a assinatura para reconstruir a mensagem original
      final assinaturaHex = payloadOriginal.remove('assinaturaBanco') as String;

      // 3. CANONIZAÇÃO: Ordena as chaves alfabeticamente via SplayTreeMap (RFC 8785)
      final sortedPayload = SplayTreeMap<String, dynamic>.from(payloadOriginal);
      final String jsonCanonico = jsonEncode(sortedPayload);

      print("JSON Canónico reconstruído no Flutter: $jsonCanonico");

      // 4. Calcula o Hash SHA-256 da mensagem canonizada (32 bytes)
      final mensagemBytes = Uint8List.fromList(utf8.encode(jsonCanonico));
      final hashBytes = SHA256Digest().process(mensagemBytes);
      final documentHashHex = '0x${bytesToHex(hashBytes)}';

      // 5. Prepara a Assinatura ECDSA (65 bytes: R[32] || S[32] || V[1])
      final assinaturaBytes = hexToBytes(assinaturaHex);

      if (assinaturaBytes.length == 65) {
        final r = BigInt.parse(bytesToHex(assinaturaBytes.sublist(0, 32)), radix: 16);
        final s = BigInt.parse(bytesToHex(assinaturaBytes.sublist(32, 64)), radix: 16);
        int v = assinaturaBytes[64];

        // Normalização de 'v' para o padrão Web3 (27 ou 28)
        if (v < 27) v += 27;

        final msgSig = MsgSignature(r, s, v);

        // --- TENTATIVAS DE RECUPERAÇÃO DO ENDEREÇO ---
        final candidatos = <String, Uint8List>{};

        // Opção A: Hash SHA-256 direto dos 32 bytes
        candidatos['SHA-256 Direto'] = hashBytes;

        // Opção B: Prefixo Ethereum (\x19Ethereum Signed Message:\n32 + hashBytes) + Keccak256
        final prefix32 = utf8.encode("\x19Ethereum Signed Message:\n32");
        candidatos['Prefixo Eth (32 bytes)'] = keccak256(
          Uint8List.fromList([...prefix32, ...hashBytes]),
        );

        // Opção C: Prefixo Ethereum aplicado sobre a String Hex (0x...)
        final docStringBytes = utf8.encode(documentHashHex);
        final prefix66 = utf8.encode("\x19Ethereum Signed Message:\n${documentHashHex.length}");
        candidatos['Prefixo Eth (String Hex)'] = keccak256(
          Uint8List.fromList([...prefix66, ...docStringBytes]),
        );

        // Avalia qual variação reconstrói a operationalKeyHex oficial
        for (final entry in candidatos.entries) {
          try {
            final pubKey = ecRecover(entry.value, msgSig);
            final addrHex = '0x${bytesToHex(publicKeyToAddress(pubKey))}';

            print("Testando ${entry.key} -> Endereço Derivado: $addrHex");

            if (addrHex.toLowerCase() == operationalKeyHex.toLowerCase()) {
              print("Assinatura Válida! Método identificado: ${entry.key}");
              assinaturaValida = true;
              break;
            }
          } catch (_) {}
        }
      }

      // 6. Consulta a prova de existência na Blockchain Besu
      if (assinaturaValida) {
        extratoConstaNoBlockchain = await ClienteApiBlockchain()
            .extratoConstaNoBlockchain(documentHashHex);
      }

      if (!assinaturaValida) {
        return DocumentoDeExtratoBancario(sortedPayload)
          ..isDocumentoVeridico = false
          ..mensagemDeErro =
              'A assinatura digital deste extrato não pertence ao banco $idDoBanco.';
      }

      if (!extratoConstaNoBlockchain) {
        return DocumentoDeExtratoBancario(sortedPayload)
          ..isDocumentoVeridico = false
          ..mensagemDeErro =
              'O extrato possui assinatura válida, mas não consta na Blockchain Besu.';
      }

      print("Documento verificado com sucesso!");
      return DocumentoDeExtratoBancario(sortedPayload)
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

/// Converte String Hexadecimal para Uint8List
Uint8List hexToBytes(String hexString) {
  var clean = hexString.startsWith('0x') ? hexString.substring(2) : hexString;
  if (clean.length.isOdd) clean = '0$clean';
  return Uint8List.fromList(List.generate(
    clean.length ~/ 2,
        (i) => int.parse(clean.substring(i * 2, i * 2 + 2), radix: 16),
  ));
}

/// Converte Uint8List para String Hexadecimal
String bytesToHex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

class DocumentoException implements Exception {
  final String? message;
  DocumentoException(this.message);

  @override
  String toString() => message ?? super.toString();
}