import 'package:chat_fire_flutter/ui/main_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginUI extends StatefulWidget {
  @override
  _LoginUIState createState() => _LoginUIState();
}

class _LoginUIState extends State<LoginUI> {
  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool isLoading = false;
  bool isLoggedIn = false;

  SharedPreferences prefs;
  FirebaseUser currentUser;

  @override
  void initState() {
    super.initState();
    _isSignedIn();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Firestore - Login"),
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: ListView(
          children: <Widget>[
            Align(
              alignment: Alignment.center,
              child: Text(
                "Bienvenido al chat \nIniciar Sesión",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, color: Colors.blueAccent),
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                hintText: "Ingrese su correo electrónico",
                labelText: "Correo",
              ),
            ),
            SizedBox(height: 24),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: "Ingrese su contraseña",
                labelText: "Contraseña",
              ),
            ),
            SizedBox(height: 24),
            RaisedButton(
              onPressed: _signedIn,
              color: Colors.lightBlue,
              splashColor: Colors.white,
              textColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.only(top: 15, bottom: 15),
                child: Text("Ingresar"),
              ),
            ),
            SizedBox(height: 24),
            FlatButton(
              onPressed: _signedUp,
              child: Padding(
                padding: EdgeInsets.only(top: 15, bottom: 15),
                child: Text("Crear cuenta"),
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(left: 10, right: 10),
                  child: Text("ó"),
                ),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            RaisedButton(
              onPressed: _signedInGoogle,
              color: Colors.red,
              splashColor: Colors.white,
              textColor: Colors.white,
              child: Padding(
                padding: EdgeInsets.only(top: 15, bottom: 15),
                child: Text("Iniciar sesión con Google"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _isSignedIn() async {
    this.setState(() => isLoading = true);

    prefs = await SharedPreferences.getInstance();
    isLoggedIn = await googleSignIn.isSignedIn();

    if (isLoggedIn) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainUI(currentUserId: prefs.getString('id')),
        ),
      );
    }

    this.setState(() => isLoading = false);
  }

  void _signedIn() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() => isLoading = true);

    FirebaseUser firebaseUser = await firebaseAuth.signInWithEmailAndPassword(
        email: _emailController.text, password: _passwordController.text);

    await _saveUser(firebaseUser);
  }

  void _signedUp() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() => isLoading = true);

    FirebaseUser firebaseUser =
        await firebaseAuth.createUserWithEmailAndPassword(
            email: _emailController.text, password: _passwordController.text);

    await _saveUser(firebaseUser);
  }

  void _signedInGoogle() async {
    prefs = await SharedPreferences.getInstance();

    this.setState(() => isLoading = true);

    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;

    final AuthCredential credential = GoogleAuthProvider.getCredential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    FirebaseUser firebaseUser =
        await firebaseAuth.signInWithCredential(credential);

    await _saveUser(firebaseUser);
  }

  Future _saveUser(FirebaseUser firebaseUser) async {
    if (firebaseUser != null) {
      final QuerySnapshot result = await Firestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .getDocuments();

      final List<DocumentSnapshot> documents = result.documents;

      if (documents.length == 0) {
        Firestore.instance
            .collection('users')
            .document(firebaseUser.uid)
            .setData({
          'nickname': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoUrl,
          'id': firebaseUser.uid,
          'createdAt': DateTime.now().millisecondsSinceEpoch.toString(),
          'chattingWith': null
        });

        currentUser = firebaseUser;

        await prefs.setString('id', currentUser.uid);
        await prefs.setString('nickname', currentUser.displayName);
        await prefs.setString('photoUrl', currentUser.photoUrl);
      } else {
        await prefs.setString('id', documents[0]['id']);
        await prefs.setString('nickname', documents[0]['nickname']);
        await prefs.setString('photoUrl', documents[0]['photoUrl']);
        await prefs.setString('aboutMe', documents[0]['aboutMe']);
      }

      this.setState(() => isLoading = false);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MainUI(currentUserId: firebaseUser.uid),
        ),
      );
    } else {
      this.setState(() => isLoading = false);
    }
  }
}
