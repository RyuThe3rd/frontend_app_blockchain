
import 'package:app_pfc_blockchain/Domain/contratos/BancoRepoContract.dart';
import 'package:flutter/material.dart';

class BancoProvider extends ChangeNotifier {
  final BancoRepoContract bancoRepo;
  String? bancoCorrente;
  List<String> bancos = [];
  bool isLoading = true;

  BancoProvider(this.bancoRepo) {
    _init();
  }

  Future<void> _init() async {
    try {
      bancos = await bancoRepo.getDeListaDeBancos();
    } catch (e) {
      debugPrint("Erro ao buscar bancos: $e");
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setBancoCorrente(String valor) {

    if (bancos.length == 2)
      bancoCorrente = valor.split("-")[1];
    else
      bancoCorrente = valor;

    notifyListeners();
  }
}
