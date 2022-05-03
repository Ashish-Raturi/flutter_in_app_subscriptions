import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:pim/color.dart';
import 'package:pim/service/subscription_db_service.dart';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'dart:async';

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
  String activeSubId = "";

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  List<ProductDetails> _products = <ProductDetails>[];
  List<String> _notFoundIds = <String>[];
  bool _isAvailable = false;
  String? _queryProductError;
  bool _loading = true;

  late StreamSubscription<List<PurchaseDetails>> _subscription;
  bool _purchasePending = false;

  late UserData userData;

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
        _loading = false;
      });
      return;
    }

    setState(() {
      _isAvailable = isAvailable;
      _products = productDetailResponse.productDetails;
      _notFoundIds = productDetailResponse.notFoundIDs;
      _loading = false;
    });
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

  ProductDetails? findProductDetail(String id) {
    for (ProductDetails pd in _products) {
      if (pd.id == id) return pd;
    }
    return null;
  }

  checkForSubStatus(String productId) async {
    bool subStatus =
        await SubscriptionDbService().checkUserSubscriptionStatus();
    if (subStatus == true) {
      activeSubId = productId;
    } else {
      userData.oldPdFromDb = null;
    }
    Future.delayed(Duration(seconds: 1), () {
      setState(() {});
    });
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

          userData = snapshot.data!;
          if (userData.oldPdFromDb != null) {
            checkForSubStatus(userData.oldPdFromDb!.productID);
            // activeSubId = userData.oldPdFromDb!.productID;
          }
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
                                        _buildRestoreButton()
                                      ],
                                    ),
                                    _buildConnectionCheckTile(),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    if (!_notFoundIds.contains(sub1Id) &&
                                        _isAvailable)
                                      _buildMonthlySubTile(),
                                    if (_notFoundIds.contains(sub1Id))
                                      Text('Product $sub1Id not found'),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                    if (!_notFoundIds.contains(sub2Id) &&
                                        _isAvailable)
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
    ProductDetails pd = findProductDetail(sub1Id)!;
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
                    Text(pd.title,
                        // 'Product title',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 18)),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(pd.price,
                        // 'Price',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    SizedBox(
                      height: 5,
                    ),
                    if (activeSubId == sub1Id)
                      GestureDetector(
                        onTap: () {
                          confirmPriceChange(context, sub1Id);
                        },
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
              child: Text('Description : ${pd.description}',
                  style: TextStyle(color: c3, fontSize: 16)),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {
                buySubscription(pd);
              },
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
    ProductDetails pd = findProductDetail(sub2Id)!;
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
                    Text(pd.title,
                        // 'Product title',
                        style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            fontSize: 18)),
                    const SizedBox(
                      height: 5,
                    ),
                    Text(pd.price,
                        // 'Price',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w500,
                            color: Colors.white)),
                    SizedBox(
                      height: 5,
                    ),
                    if (activeSubId == sub2Id)
                      GestureDetector(
                        onTap: () {
                          confirmPriceChange(context, sub2Id);
                        },
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
              child: Text('Description : ${pd.description}',
                  style: TextStyle(color: c3, fontSize: 16)),
            ),
            const SizedBox(
              height: 20,
            ),
            GestureDetector(
              onTap: () {
                buySubscription(pd);
              },
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

  buySubscription(ProductDetails productDetails) async {
    late PurchaseParam purchaseParam;

    if (Platform.isAndroid) {
      //update oldSubscription details for upgrading and downgrading subscription
      GooglePlayPurchaseDetails? oldSubscription;
      if (userData.oldPdFromDb != null) oldSubscription = userData.oldPdFromDb;

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
    //(for ios error) Flutter: storekit_duplicate_product_object : https://stackoverflow.com/questions/67367861/flutter-storekit-duplicate-product-object-there-is-a-pending-transaction-for-t
    var transactions = await SKPaymentQueueWrapper().transactions();
    transactions.forEach(
      (skPaymentTransactionWrapper) {
        SKPaymentQueueWrapper().finishTransaction(skPaymentTransactionWrapper);
      },
    );
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

  Future<void> confirmPriceChange(BuildContext context, String sku) async {
    if (Platform.isAndroid) {
      final InAppPurchaseAndroidPlatformAddition androidAddition =
          _inAppPurchase
              .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final BillingResultWrapper priceChangeConfirmationResult =
          await androidAddition.launchPriceChangeConfirmationFlow(
        sku: sku,
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

  void showPendingUI() {
    setState(() {
      _purchasePending = true;
    });
  }

  Future<void> verifyAndDeliverProduct(PurchaseDetails purchaseDetails) async {
    //verify
    HttpsCallable callable =
        FirebaseFunctions.instance.httpsCallable('verifyPurchase');
    final res = await callable.call({
      'source': Platform.isAndroid ? 'google_play' : 'app_store',
      'productId': purchaseDetails.productID,
      'uid': 'vt1g6YbzBkxblkyrXfzT',
      'verificationData':
          purchaseDetails.verificationData.serverVerificationData
    });

    print('Purchase verified : ${res.data}');
    if (res.data) {
      //save purchase in db
      await SubscriptionDbService().saveSubcriptionsDetails(purchaseDetails);
      //update local variable
      setState(() {
        activeSubId = purchaseDetails.productID;
        _purchasePending = false;
      });
      print('Product details saved');
    } else {
      // payment failed
    }
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
