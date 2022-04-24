import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

class SubscriptionDbService {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveSubcriptionsDetails(PurchaseDetails purchaseDetails) async {
    GooglePlayPurchaseDetails gpp =
        purchaseDetails as GooglePlayPurchaseDetails;

    _firestore.collection('User Data').doc('vt1g6YbzBkxblkyrXfzT').set({
      'Purchase Wrapper': {
        'developerPayload': gpp.billingClientPurchase.developerPayload,
        'isAcknowledged': gpp.billingClientPurchase.isAcknowledged,
        'isAutoRenewing': gpp.billingClientPurchase.isAutoRenewing,
        'obfuscatedAccountId': gpp.billingClientPurchase.obfuscatedAccountId,
        'obfuscatedProfileId': gpp.billingClientPurchase.obfuscatedProfileId,
        'orderId': gpp.billingClientPurchase.orderId,
        'originalJson': gpp.billingClientPurchase.originalJson,
        'packageName': gpp.billingClientPurchase.packageName,
        'purchaseTime': gpp.billingClientPurchase.purchaseTime,
        'purchaseToken': gpp.billingClientPurchase.purchaseToken,
        'signature': gpp.billingClientPurchase.signature,
        'sku': gpp.billingClientPurchase.sku
      }
    }, SetOptions(merge: true));
  }

  Stream<UserData> get featchUserDataFromDb {
    return _firestore
        .collection('User Data')
        .doc('vt1g6YbzBkxblkyrXfzT')
        .snapshots()
        .map((event) => userDataFromSnapshot(event));
  }

  UserData userDataFromSnapshot(DocumentSnapshot ds) {
    GooglePlayPurchaseDetails? oldPd;

    try {
      var pw = ds.get('Purchase Wrapper');
      oldPd = GooglePlayPurchaseDetails.fromPurchase(PurchaseWrapper(
        isAcknowledged: pw['isAcknowledged'],
        isAutoRenewing: pw['isAutoRenewing'],
        orderId: pw['orderId'],
        originalJson: pw['originalJson'],
        packageName: pw['packageName'],
        purchaseState: PurchaseStateWrapper.purchased,
        purchaseTime: pw['purchaseTime'],
        purchaseToken: pw['purchaseToken'],
        signature: pw['signature'],
        sku: pw['sku'],
        developerPayload: pw['developerPayload'],
        obfuscatedAccountId: pw['obfuscatedAccountId'],
        obfuscatedProfileId: pw['obfuscatedProfileId'],
      ));
    } catch (e) {}

    return UserData(oldPdFromDb: oldPd, username: ds.get('username'));
  }
}

class UserData {
  String username;
  GooglePlayPurchaseDetails? oldPdFromDb;
  UserData({required this.username, required this.oldPdFromDb});
}
