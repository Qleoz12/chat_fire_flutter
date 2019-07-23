import 'package:cached_network_image/cached_network_image.dart';
import 'package:chat_fire_flutter/ui/chat_ui.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../main.dart';

class MainUI extends StatefulWidget {
  final String currentUserId;

  MainUI({this.currentUserId});

  @override
  _MainUIState createState() => _MainUIState(currentUserId: currentUserId);
}

class _MainUIState extends State<MainUI> {
  final String currentUserId;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  bool _isLoading = false;

  _MainUIState({@required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Chat Firestore - Login"),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(24),
        child: Container(
          child: StreamBuilder(
            stream: Firestore.instance.collection("users").snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Colors.blueAccent),
                  ),
                );
              } else {
                return ListView.builder(
                  padding: EdgeInsets.all(0),
                  itemBuilder: (context, index) =>
                      buildItem(context, snapshot.data.documents[index]),
                  itemCount: snapshot.data.documents.length,
                );
              }
            },
          ),
        ),
      ),
    );
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if (document['id'] == currentUserId) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: document['photoUrl'] != null
                    ? CachedNetworkImage(
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.0,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blueAccent),
                          ),
                          width: 50,
                          height: 50,
                          padding: EdgeInsets.all(15),
                        ),
                        imageUrl: document['photoUrl'],
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.account_circle,
                        size: 50.0,
                        color: Colors.grey,
                      ),
                borderRadius: BorderRadius.all(Radius.circular(25)),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          'Nickname: ${document['nickname']}',
                          style: TextStyle(color: Colors.black26),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                      ),
                      Container(
                        child: Text(
                          'About me: ${document['aboutMe'] ?? 'Not available'}',
                          style: TextStyle(color: Colors.black26),
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      )
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatUI(
                          peerId: document.documentID,
                          peerAvatar: document['photoUrl'],
                        )));
          },
          color: Colors.blueGrey,
          padding: EdgeInsets.fromLTRB(25, 10, 25, 10),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        margin: EdgeInsets.only(bottom: 10, left: 5, right: 5),
      );
    }
  }

  void _logout() async {
    this.setState(() => _isLoading = true);

    await FirebaseAuth.instance.signOut();
    await _googleSignIn.disconnect();
    await _googleSignIn.signOut();

    this.setState(() => _isLoading = false);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => MyApp()),
      (Route<dynamic> route) => false,
    );
  }
}
