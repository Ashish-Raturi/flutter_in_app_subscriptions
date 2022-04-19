import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionDbService {
  FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserData> get featchUserDataFromDb {
    return _firestore
        .collection('User Data')
        .doc('vt1g6YbzBkxblkyrXfzT')
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
