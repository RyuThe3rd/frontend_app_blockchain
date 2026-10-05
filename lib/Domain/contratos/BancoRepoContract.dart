import "package:http/http.dart" as http;

abstract interface class BancoRepoContract {

  List<String> getDeListaDeBancos();
  String getChavePublicaDoBanco({String? banco, String? id});


}