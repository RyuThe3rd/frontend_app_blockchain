import 'package:http/http.dart' as http;

import '../../Domain/contratos/ClienteApiBlockchainContract.dart';

class ClienteApiBlockchain implements ClienteApiBlockchainContract{
 String apiUrl = 'https://api-blockchain-pfc-1021823144662.africa-south1.run.app' ;


  static Future<String> getChavePublicaDoBanco(String nomeDoBanco) async {

    return '';
  }

  static Future<bool> extratoConstaNoBlockchain(String hashDoPayload) async {

    return false;
  }


}

class ClienteApiBlockchainException implements Exception {
  String? message;

  ClienteApiBlockchainException(this.message);

  @override
  String toString() {
    // TODO: implement toString
    return message ?? super.toString() ;
  }
}

class ClienteApiBlockchainMock implements ClienteApiBlockchainContract{
  String apiUrl = 'https://api-blockchain-pfc-1021823144662.africa-south1.run.app' ;


  static Future<String> getChavePublicaDoBanco(String nomeDoBanco) async {

    return 'MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEdv/Y3cuipbFOFpdZkF0j/x3sOwBEMU21mh5p5o4CJyUT62AechKYivGqfeDyUTq1a/0f4kq27Gr7nPNwPLbqag==';
  }

  static Future<bool> extratoConstaNoBlockchain(String hashDoPayload) async {

    if(hashDoPayload == 'acac426e8cf891cb8e8aba2bf8094d00933a06d37eceaa6cf9177016e14e75bc'){
      return true;
    }

    return false;
  }


}