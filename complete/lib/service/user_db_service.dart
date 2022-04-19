import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class SubscriptionDbService {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> saveSubcriptionsDetails(PurchaseDetails purchaseDetails) async {
    _firestore.collection('User Data').doc('J2Bu7KDlku5sFbc6S9HR').set({
      'Purchase Details': {
        'error': purchaseDetails.error,
        'pendingCompletePurchase': purchaseDetails.pendingCompletePurchase,
        'productID': purchaseDetails.productID,
        'purchaseID': purchaseDetails.purchaseID,
        'status': purchaseDetails.status.index,
        'transactionDate': purchaseDetails.transactionDate,
        'localVerificationData':
            purchaseDetails.verificationData.localVerificationData,
        'serverVerificationData':
            purchaseDetails.verificationData.serverVerificationData,
        'source': purchaseDetails.verificationData.source,
        'datetime': Timestamp.now()
      }
    }, SetOptions(merge: true));
  }

  Stream<UserData> get featchUserDataFromDb {
    return _firestore
        .collection('User Data')
        .doc('J2Bu7KDlku5sFbc6S9HR')
        .snapshots()
        .map((event) => userDataFromSnapshot(event));
  }

  UserData userDataFromSnapshot(DocumentSnapshot ds) {
    return UserData(username: ds.get('username'));
  }
}

class UserData {
  String username;
  UserData({required this.username});
}
