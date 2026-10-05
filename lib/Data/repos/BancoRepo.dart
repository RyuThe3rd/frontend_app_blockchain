
import '../../Domain/contratos/BancoRepoContract.dart';

class BancoRepo implements BancoRepoContract{

  late Set<String> listaDeBancos = {
    'Banco Comercial e de Investimentos - BCI',
  'Millennium bim',
  'Standard Bank Moçambique - STB',
  'Absa Bank Moçambique - ABS',
  'Banco Internacional de Moçambique - BIM',
  'Banco Único',
  'Banco Terra',
  'Moza Banco',
  'Banco Nacional de Investimento - BNI',
  'Banco de Poupança e Crédito - BPC',
  'Banco Africano de Investimentos - BAI',
  'First National Bank (FNB) Moçambique - FNB',
  'Ecobank Moçambique',
  'Access Bank Moçambique',
  'Banco Letshego Moçambique',
  'Banco Oportunidade de Moçambique',
  'Banco de Investimento e Comércio - BIC',
  'Banco Comercial do Índico',
  'Banco de Desenvolvimento e Comércio - BDC',
  'Banco Nacional de Desenvolvimento - BND',
  };

  void atualizarInternamenteListaDeBancos() {}

  @override
  String getChavePublicaDoBanco({String? banco, String? id}) {
    // TODO: implement getChavePublicaDoBanco
    throw UnimplementedError();
  }

  @override
  List<String> getDeListaDeBancos() {
    return listaDeBancos.toList();
  }



}

class BancoRepoException implements Exception {

  String? mensagem;

  BancoRepoException(this.mensagem);
  @override
  String toString() {
    // TODO: implement toString
    return mensagem ?? super.toString();
  }
}