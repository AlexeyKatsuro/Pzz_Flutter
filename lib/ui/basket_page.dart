import 'package:flutter/material.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:pzz/domain/actions/actions.dart';
import 'package:pzz/domain/actions/navigate_to_action.dart';
import 'package:pzz/domain/selectors/selector.dart';
import 'package:pzz/models/app_state.dart';
import 'package:pzz/models/basket.dart';
import 'package:pzz/models/combined_basket_product.dart';
import 'package:pzz/models/pizza.dart';
import 'package:pzz/models/product.dart';
import 'package:pzz/res/strings.dart';
import 'package:pzz/routes.dart';
import 'package:pzz/ui/containers/confirm_place_order_container.dart';
import 'package:pzz/ui/containers/payment_way_container.dart';
import 'package:pzz/ui/widgets/basket_combined_item.dart';
import 'package:pzz/ui/widgets/personal_info_form.dart';
import 'package:pzz/utils/extensions/enum_localization_ext.dart';
import 'package:pzz/utils/extensions/to_product_ext.dart';
import 'package:pzz/utils/scoped.dart';
import 'package:pzz/utils/widgets/error_scoped_notifier.dart';
import 'package:redux/redux.dart';

class BasketPage extends StatefulWidget implements Scoped {
  final String scope = Routes.basketScreen;

  @override
  _BasketPageState createState() => _BasketPageState();
}

class _BasketPageState extends State<BasketPage> {
  @override
  Widget build(BuildContext context) {
    return StoreConnector<AppState, _ViewModel>(
      distinct: true,
      onWillChange: (previousViewModel, newViewModel) {
        if (newViewModel.showConfirmOrderDialogEvent) {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (BuildContext context) {
              return SingleChildScrollView(
                child: ConfirmPlaceOrderContainer(),
              );
            },
          );
          newViewModel.handleConfirmOrderDialogEvent();
        }
      },
      converter: (store) {
        return _ViewModel.formStore(store, widget.scope);
      },
      builder: _build,
    );
  }

  Widget _build(BuildContext context, _ViewModel vm) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${StringRes.total_price}: ${vm.totalAmount.toStringAsFixed(2)} р.'),
      ),
      body: ErrorScopedNotifier(
        widget.scope,
        child: ListView(
          children: [
            SizedBox(
              height: 12,
            ),
            ..._buildProducts(context, vm, ProductType.pizza),
            ..._buildProducts(context, vm, ProductType.sauce),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: OutlinedButton(
                onPressed: vm.onChooseSauceClick,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        vm.freeSauceCounts != 0 ? StringRes.chooseFeeSauces(vm.freeSauceCounts) : StringRes.addSauces,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                    )
                  ],
                ),
              ),
            ),
            DividedCenterTitle(StringRes.delivery_address),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: PersonalInfoFormContainer(),
            ),
            DividedCenterTitle(StringRes.payment_way),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: PaymentWayContainer(),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: ElevatedButton(
                onPressed: vm.onPlaceOrderClick,
                child: Text(StringRes.place_order),
              ),
            )
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProducts(BuildContext context, _ViewModel vm, ProductType type) {
    final items = vm.itemsMap[type] ?? [];
    return [
      DividedCenterTitle(type.localizedPluralsString),
      if (items.length != 0) const SizedBox(height: 12),
      for (int index = 0; index < items.length; index++)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              BasketCombinedItem(
                combinedProduct: items[index],
                onAddClick: (p) => vm.onAddItemClick(p.toProduct()),
                onRemoveClick: (p) => vm.onRemoveItemClick(p.toProduct()),
              ),
              if (index != items.length - 1) Divider(),
            ],
          ),
        ),
    ];
  }
}

class DividedCenterTitle extends StatelessWidget {
  const DividedCenterTitle(
    this.title, {
    Key key,
  }) : super(key: key);

  final String title;

  @override
  Widget build(BuildContext context) {
    var theme = Theme.of(context);
    return Row(
      children: [
        Expanded(child: Divider()),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            title,
            style: theme.textTheme.headline6,
          ),
        ),
        Expanded(child: Divider()),
      ],
    );
  }
}

class _ViewModel {
  final int basketCount;
  final Map<ProductType, List<CombinedBasketProduct>> itemsMap;
  final Basket basket;
  final int freeSauceCounts;
  final bool showConfirmOrderDialogEvent;
  // Callbacks
  final ValueSetter<Product> onAddItemClick;
  final ValueSetter<Product> onRemoveItemClick;
  final VoidCallback onPlaceOrderClick;
  final VoidCallback handleConfirmOrderDialogEvent;
  final VoidCallback onChooseSauceClick;

  bool get isBasketEmpty => basketCount == 0;

  num get totalAmount => basket.totalAmount;

  _ViewModel({
    @required this.basketCount,
    @required this.itemsMap,
    @required this.basket,
    @required this.freeSauceCounts,
    @required this.showConfirmOrderDialogEvent,
    @required this.onAddItemClick,
    @required this.onRemoveItemClick,
    @required this.onPlaceOrderClick,
    @required this.handleConfirmOrderDialogEvent,
    @required this.onChooseSauceClick,
  })  : assert(itemsMap != null),
        assert(basketCount != null),
        assert(onAddItemClick != null);

  static _ViewModel formStore(Store<AppState> store, String scope) {
    return _ViewModel(
        showConfirmOrderDialogEvent: showConfirmOrderDialogEventSelector(store.state),
        basket: basketSelector(store.state),
        itemsMap: combinedBasketProductsTypedMap(store.state),
        basketCount: basketCountSelector(store.state),
        freeSauceCounts: freeSauceCountsSelector(store.state),
        onChooseSauceClick: () => store.dispatch(NavigateAction.push(Routes.saucesScreen)),
        onAddItemClick: (item) => store.dispatch(AddProductAction(product: item, scope: scope)),
        handleConfirmOrderDialogEvent: () => store.dispatch(HandleConfirmOrderDialogAction()),
        onRemoveItemClick: (item) => store.dispatch(RemoveProductAction(product: item, scope: scope)),
        onPlaceOrderClick: () => store.dispatch(TryPlaceOrderAction()));
  }
}
