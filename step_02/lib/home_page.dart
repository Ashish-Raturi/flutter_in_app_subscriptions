import 'package:flutter/material.dart';
import 'package:pim/color.dart';
import 'package:pim/service/subscription_db_service.dart';
import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  _HomepageState createState() => _HomepageState();
}

//Subscription 01
String sub1Id =
    Platform.isAndroid ? 'monthly_subscription' : 'your_ios_sub1_id';

//Subscription 02
String sub2Id = Platform.isAndroid ? 'yearly_subscription' : 'your_ios_sub2_id';

List<String> _subcriptionProductIds = <String>[
  sub1Id,
  sub2Id,
];

class _HomepageState extends State<Homepage> {
  String activeSubId = "pro plan";

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  ///-------Use this Fields---------///
  PurchaseDetails? _activeSubscriptionPurchasesDetails;
  List<ProductDetails> _products = <ProductDetails>[];
  List<String> _notFoundIds = <String>[];

  bool _isAvailable = false;
  String? _queryProductError;
  bool _purchasePending = false;
  bool _loading = true;

  ///-------------------------------///
  @override
  void initState() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription =
        purchaseUpdated.listen((List<PurchaseDetails> purchaseDetailsList) {
      _listenToPurchaseUpdated(purchaseDetailsList);
    }, onDone: () {
      _subscription.cancel();
    }, onError: (Object error) {
      // handle error here.
    });
    initStoreInfo();
    super.initState();
  }

  Future<void> initStoreInfo() async {
    final bool isAvailable = await _inAppPurchase.isAvailable();
    if (!isAvailable) {
      setState(() {
        _isAvailable = isAvailable;
        _products = <ProductDetails>[];

        _notFoundIds = <String>[];

        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
    }

    final ProductDetailsResponse productDetailResponse = await _inAppPurchase
        .queryProductDetails(_subcriptionProductIds.toSet());
    if (productDetailResponse.error != null) {
      setState(() {
        _queryProductError = productDetailResponse.error!.message;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;

        _notFoundIds = productDetailResponse.notFoundIDs;

        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    if (productDetailResponse.productDetails.isEmpty) {
      setState(() {
        _queryProductError = null;
        _isAvailable = isAvailable;
        _products = productDetailResponse.productDetails;

        _notFoundIds = productDetailResponse.notFoundIDs;

        _purchasePending = false;
        _loading = false;
      });
      return;
    }

    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _notFoundIds = productDetailResponse.notFoundIDs;

      _purchasePending = false;
      _loading = false;
    });
  }

  @override
  void dispose() {
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosPlatformAddition.setDelegate(null);
    }
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserData>(
        stream: SubscriptionDbService().featchUserDataFromDb,
        builder: (context, snapshot) {
          if (snapshot.hasData == false) {
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 20,
                    ),
                    Text('Loading User Data, Please wait...')
                  ],
                ),
              ),
            );
          }

          UserData userData = snapshot.data!;

          return SafeArea(
            child: Scaffold(
                backgroundColor: Colors.white,
                body: _loading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            CircularProgressIndicator(),
                            SizedBox(
                              height: 10,
                            ),
                            Text('Loading Product Details, Please wait...')
                          ],
                        ),
                      )
                    : Stack(
                        children: [
                          if (_queryProductError != null)
                            Center(
                                child: Padding(
                              padding: const EdgeInsets.all(18.0),
                              child: Text(
                                'Query Product Error(Got Error While Fetching Product Details) : $_queryProductError',
                                textAlign: TextAlign.center,
                              ),
                            )),
                          if (_queryProductError == null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 5),
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Hi, ${userData.username}',
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 22,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    _buildConnectionCheckTile(),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    if (_isAvailable &&
                                        _notFoundIds.contains(sub1Id) == false)
                                      _buildMonthlySubTile(),
                                    if (_notFoundIds.contains(sub1Id))
                                      Text('Product $sub1Id not found'),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    if (_isAvailable &&
                                        _notFoundIds.contains(sub2Id) == false)
                                      _buildYearlySubTile(),
                                    if (_notFoundIds.contains(sub2Id))
                                      Text('Product $sub2Id not found'),
                                  ],
                                ),
                              ),
                            ),
                          if (_purchasePending)
                            Container(
                              width: double.maxFinite,
                              height: double.maxFinite,
                              color: Colors.black87,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  CircularProgressIndicator(),
                                  SizedBox(
                                    height: 10,
                                  ),
                                  Text(
                                    "Processing Purchase, Please wait...",
                                    style: TextStyle(color: Colors.white),
                                  )
                                ],
                              ),
                            )
                        ],
                      )),
          );
        });
  }

  _buildMonthlySubTile() {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: c1,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product title',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 18)),
                    const SizedBox(
                      height: 5,
                    ),
                    Text('Price',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    SizedBox(
                      height: 5,
                    ),
                    if (activeSubId == sub1Id)
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(06),
                            color: c2,
                          ),
                          // width: 200,
                          alignment: Alignment.center,
                          child: Text(
                            'Price Change',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                    child: SizedBox(
                  width: 3,
                )),
                Image.asset('assets/diamond1.png', width: 60),
              ],
            ),
            Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Description : product description',
                  style: TextStyle(color: c3, fontSize: 16)),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(06),
                  color: activeSubId == sub1Id ? c4 : c2,
                ),
                // width: 200,
                alignment: Alignment.center,
                child: Text(
                  activeSubId == sub1Id ? 'Active' : 'Choose Plan ->',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ));
  }

  _buildYearlySubTile() {
    return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: c1,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 10),
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Product title',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 18)),
                    const SizedBox(
                      height: 5,
                    ),
                    Text('Price',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    SizedBox(
                      height: 5,
                    ),
                    if (activeSubId == sub2Id)
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(06),
                            color: c2,
                          ),
                          // width: 200,
                          alignment: Alignment.center,
                          child: Text(
                            'Price Change',
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                    child: SizedBox(
                  width: 3,
                )),
                Image.asset('assets/diamond2.png', width: 60),
              ],
            ),
            Divider(),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Description : product description',
                  style: TextStyle(color: c3, fontSize: 16)),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(06),
                  color: activeSubId == sub2Id ? c4 : c2,
                ),
                // width: 200,
                alignment: Alignment.center,
                child: Text(
                  activeSubId == sub2Id ? 'Active' : 'Choose Plan ->',
                  style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ),
            const SizedBox(
              height: 10,
            ),
          ],
        ));
  }

  Card _buildConnectionCheckTile() {
    if (_loading) {
      return const Card(child: ListTile(title: Text('Trying to connect...')));
    }
    final Widget storeHeader = ListTile(
      leading: Icon(_isAvailable ? Icons.check : Icons.block,
          color: _isAvailable ? Colors.green : ThemeData.light().errorColor),
      title: Text(
          'The store is ' + (_isAvailable ? 'available' : 'unavailable') + '.'),
    );
    final List<Widget> children = <Widget>[storeHeader];

    if (!_isAvailable) {
      children.addAll(<Widget>[
        const Divider(),
        ListTile(
          title: Text('Not connected',
              style: TextStyle(color: ThemeData.light().errorColor)),
          subtitle: const Text(
              'Unable to connect to the payments processor. Has this app been configured correctly? See the example README for instructions.'),
        ),
      ]);
    }
    return Card(child: Column(children: children));
  }

  Widget _buildRestoreButton() {
    if (_loading) {
      return Container();
    }

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          TextButton(
            child: const Text('Restore purchases'),
            style: TextButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              primary: Colors.white,
            ),
            onPressed: () => _inAppPurchase.restorePurchases(),
          ),
        ],
      ),
    );
  }

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

  ProductDetails? findProductDetail(String id) {
    for (ProductDetails pd in _products) {
      if (pd.id == id) return pd;
    }
    return null;
  }

  buySubscription(ProductDetails productDetails) {
    late PurchaseParam purchaseParam;

    if (Platform.isAndroid) {
      final GooglePlayPurchaseDetails? oldSubscription = _getOldSubscription(
          productDetails, _activeSubscriptionPurchasesDetails);

      purchaseParam = GooglePlayPurchaseParam(
          productDetails: productDetails,
          applicationUserName: null,
          changeSubscriptionParam: (oldSubscription != null)
              ? ChangeSubscriptionParam(
                  oldPurchaseDetails: oldSubscription,
                  prorationMode: ProrationMode.immediateAndChargeProratedPrice,
                )
              : null);
    } else {
      purchaseParam = PurchaseParam(
        productDetails: productDetails,
        applicationUserName: null,
      );
    }
    //buying Subscription
    _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
  }

  Future<void> verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    //Verify Purchase
    //Deliver Product
    setState(() {
      _activeSubscriptionPurchasesDetails = purchaseDetails;
      activeSubId = purchaseDetails.productID;
      _purchasePending = false;
    });
  }

  void handleError(IAPError error) {
    setState(() {
      _purchasePending = false;
    });
  }

  Future<void> _listenToPurchaseUpdated(
      List<PurchaseDetails> purchaseDetailsList) async {
    for (final PurchaseDetails purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        showPendingUI();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          handleError(purchaseDetails.error!);
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
            purchaseDetails.status == PurchaseStatus.restored) {
          verifyAndDeliverProduct(purchaseDetails);
        }
        if (purchaseDetails.pendingCompletePurchase) {
          await _inAppPurchase.completePurchase(purchaseDetails);
        }
      }
    }
  }

  Future<void> confirmPriceChange(
      BuildContext context, String purchaseId) async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final BillingResultWrapper priceChangeConfirmationResult =
          await androidAddition.launchPriceChangeConfirmationFlow(
        sku: purchaseId,
      );
      if (priceChangeConfirmationResult.responseCode == BillingResponse.ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Price change accepted'),
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            priceChangeConfirmationResult.debugMessage ??
                'Price change failed with code ${priceChangeConfirmationResult.responseCode}',
          ),
        ));
      }
    }
    if (Platform.isIOS) {
      final InAppPurchaseStoreKitPlatformAddition iapStoreKitPlatformAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      await iapStoreKitPlatformAddition.showPriceConsentIfNeeded();
    }
  }

  GooglePlayPurchaseDetails? _getOldSubscription(
      ProductDetails productDetails, PurchaseDetails? purchase) {
    GooglePlayPurchaseDetails? oldSubscription;
    if (productDetails.id == sub1Id &&
        purchase != null &&
        purchase.productID == sub2Id) {
      oldSubscription = purchase as GooglePlayPurchaseDetails;
    } else if (productDetails.id == sub2Id &&
        purchase != null &&
        purchase.productID == sub1Id) {
      oldSubscription = purchase as GooglePlayPurchaseDetails;
    }
    return oldSubscription;
  }
}

/// Example implementation of the
/// [`SKPaymentQueueDelegate`](https://developer.apple.com/documentation/storekit/skpaymentqueuedelegate?language=objc).
///
/// The payment queue delegate can be implementated to provide information
/// needed to complete transactions.s
class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
      SKPaymentTransactionWrapper transaction, SKStorefrontWrapper storefront) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
