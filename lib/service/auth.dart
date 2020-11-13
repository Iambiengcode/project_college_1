import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_web/model/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  //final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email']);

  //create user obj based on FirebaseUser
  UserModel _userFromFirebaseUser(User user) {
    return user != null ? UserModel(uid: user.uid) : null;
  }

  //auth change user stream
  Stream<UserModel> get user {
    return _auth.onAuthStateChanged.map(_userFromFirebaseUser);
  }

  //sign in anon
  //cannot use in purchase
  Future signInAnon() async {
    try {
      var result = await _auth.signInAnonymously();
      FirebaseUser user = result.user;

      //create info client
      await _createDataUser(user.uid, user.uid, '');

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //sign in email and password
  Future signInWithEmailAndPassword(String email, String password) async {
    try {
      var result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      User user = result.user;
      final SharedPreferences prefs = await _prefs;

      Future<String> _uid =
          prefs.setString('uid', user.uid).then((bool success) {
        return user.uid;
      });

      print(user.uid);

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  //register with email & password
  Future registerWithEmailAndPassword(
      String email, String password, String phone) async {
    try {
      var result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      FirebaseUser user = result.user;

      //create info client
      await _createDataUser(email, user.uid, phone);

      return _userFromFirebaseUser(user);
    } catch (e) {
      print(e.toString());
    }
  }

//  Future signInWithGoogle() async {
//    try{
//      GoogleSignInAccount googleUser = await _googleSignIn.signIn();
//      GoogleSignInAuthentication googleAuth = await googleUser.authentication;
//
//      AuthCredential credential = GoogleAuthProvider.getCredential(
//        idToken: googleAuth.idToken,
//        accessToken: googleAuth.accessToken,
//      );
//
//      AuthResult result = await _auth.signInWithCredential(credential);
//      FirebaseUser user = result.user;
//
//      _updateDataUserGoogle(user.email, 'Your phone', user.uid, user.photoUrl, user.displayName);
//
//      return _userFromFirebaseUser(user);
//    }catch(e){
//      print(e.toString());
//      return null;
//    }
//  }

  Future sendPasswordResetEmail(String email) async {
    return _auth.sendPasswordResetEmail(email: email);
  }

  //sign out
  Future signOut() async {
    try {
      return await _auth.signOut();
    } catch (e) {
      print(e.toString());
      return null;
    }
  }

  Future<void> _createDataUser(email, uid, phone) async {
    Firestore.instance.collection('users').document(uid).setData({
      'email': email,
      'id': uid,
      'username': email.toString().substring(0, email.toString().length - 10),
      'publishAt': DateTime.now(),
      'phone': phone,
      'image': '',
      'address': '',
      'orders': '',
    });
  }

  void _createListUserGoogle(email, uid) {
    Firestore.instance.collection('usersGoogle').document(uid).setData({
      'email': email,
    });
  }

  void _updateDataUserGoogle(email, phone, uid, url, displayName) {
    DocumentReference documentReference =
        Firestore.instance.collection('usersGoogle').document(uid);

    Firestore.instance.runTransaction((Transaction transaction) async {
      DocumentSnapshot snapshot = await transaction.get(documentReference);
      if (snapshot.exists) {
        print("USING NOW");
      } else {
        //create nor data
        _createDataUser(email, uid, phone);
      }
    });
  }
}
