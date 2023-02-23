import 'package:cloud_firestore/cloud_firestore.dart';

class MyFirestoreServices {
  CollectionReference cars = FirebaseFirestore.instance.collection('cars');

  Future<void> updateCar(String id, String deviceId, bool isSelected) {
    return cars
        .doc(id)
        .set({'id': id, 'isSelected': isSelected, "deviceId": deviceId},
            SetOptions(merge: true))
        .then((value) => print("User Added"))
        .catchError((error) => print("Failed to add user: $error"));
  }

  Future<void> deleteCar(String id) {
    return cars.doc(id).delete();
  }
}
