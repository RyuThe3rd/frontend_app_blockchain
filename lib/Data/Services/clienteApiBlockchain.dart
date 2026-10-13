import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../Domain/contratos/ClienteApiBlockchainContract.dart';

class ClienteApiBlockchain implements ClienteApiBlockchainContract{
 String apiUrl = 'https://api-blockchain-pfc-1021823144662.africa-south1.run.app' ;


 Future<String> getChavePublicaDoBanco(String idDoBanco) async {

   try {

     String endpoint = "/api/v1/banks/${idDoBanco}/operational-key";

     http.Response chavePublica = await http.get(Uri.parse("$apiUrl/$endpoint"));

     final mapa = jsonDecode(chavePublica.body);

     if(!mapa.containsKey('operationalKey')){

       throw ClienteApiBlockchainException("Chave pública não encontrada.\nAqui está o mapa atual:\n $mapa");
     }

     print("Mapa com chave operacional\n"
         " $mapa");
     return mapa['operationalKey'];

   } catch(e){

     throw ClienteApiBlockchainException(e.toString());
   }
 }

  Future<bool> extratoConstaNoBlockchain(String hashDoPayload) async {

    try {

      String endpoint = "api/v1/documents/verify/${hashDoPayload}";

      http.Response chavePublica = await http.get(Uri.parse("$apiUrl/$endpoint"));

      final mapa = jsonDecode(chavePublica.body);

      /*
      if(!mapa.containsKey('operationalKey')){

        throw ClienteApiBlockchainException("Chave pública não encontrada.\nAqui está o mapa atual:\n $mapa");
      }


       */
      print("Mapa \n"
          " $mapa");
      return mapa["exists"];

    } catch(e){

      throw ClienteApiBlockchainException(e.toString());
    }
  }

  Future<List<Map<String, dynamic>>> getDeListaDeBancos() async {

    try {

      String endpoint = "/api/v1/banks";

      http.Response chavePublica = await http.get(Uri.parse("$apiUrl/$endpoint"));

      final mapa = jsonDecode(chavePublica.body);

      final mapaProcessado = mapa.map((item){

        return Map<String, dynamic>.from(item as Map);
      }).toList().cast<Map<String, dynamic>>();

      assert(mapaProcessado is List<Map<String, dynamic>>, "mapa não é List<Map<String, dynamic>>, é ${mapaProcessado.runtimeType}");

      assert(mapaProcessado.isNotEmpty, "lista esta vazia");

      return mapaProcessado;


    } catch(e){

      throw ClienteApiBlockchainException(e.toString());
    }

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


  Future<String> getChavePublicaDoBanco(String idDoBanco) async {

      try {
        
        String endpoint = "${idDoBanco}/operational-key";
  
        http.Response chavePublica = await http.get(Uri.parse("$apiUrl/$endpoint"));
  
        final mapa = jsonDecode(chavePublica.body);
  
        if(mapa.containsKey('operationalKey')){
          
          throw ClienteApiBlockchainException("Chave pública não encontrada.\nAqui está o mapa atual:\n $mapa");
        }
        return mapa['operationalKey'];
      
      } catch(e){
        
        throw ClienteApiBlockchainException(e.toString());
      }
    }

  static Future<bool> extratoConstaNoBlockchain(String hashDoPayload) async {

    if(hashDoPayload == 'acac426e8cf891cb8e8aba2bf8094d00933a06d37eceaa6cf9177016e14e75bc'){
      return true;
    }

    return false;
  }


}