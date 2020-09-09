import 'package:pzz/domain/actions/actions.dart';
import 'package:pzz/domain/pzz_net_service.dart';
import 'package:pzz/domain/repository/pzz_repository.dart';
import 'package:pzz/models/basket.dart';
import 'package:pzz/models/pizza.dart';

class PzzRepositoryImpl implements PzzRepository {
  PzzRepositoryImpl(this._service);

  final PzzNetService _service;

  @override
  Future<Basket> addProductToBasket(Product product) {
    return _service.addProductToBasket(product);
  }

  @override
  Future<Basket> loadBasket() {
    return _service.loadBasket();
  }

  @override
  Future<List<Pizza>> loadPizzas() {
    return _service.loadPizzas();
  }

  @override
  Future<Basket> removeProductFromBasket(Product product) {
    return _service.removePizzaFromBasket(product);
  }
}
