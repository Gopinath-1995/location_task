import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:map_view_taskproject/screens/drawerScreen.dart';
import 'package:map_view_taskproject/screens/locationList_Screen.dart';
import 'package:map_view_taskproject/screens/loginScreen.dart';
import 'package:map_view_taskproject/services/firebase_auth_services.dart';

void main() {
  runApp(MaterialApp(home: Homescreen()));
}

class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

class _HomescreenState extends State<Homescreen> {
  String? userId;
  String? email;

  @override
  void initState() {
    super.initState();
    fetchCurrentUser();
  }

  void fetchCurrentUser() {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    User? user = _auth.currentUser;

    if (user != null) {
      setState(() {
        userId = user.uid;
        email = user.email;
        print(' user.email ' + user.email.toString());
      });
    }
  }

  FirebaseAuthService _authService = FirebaseAuthService();

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    double width = size.width;
    double height = size.height;
    return SafeArea(
      child: Scaffold(
        drawer: DrawerPage(),
        appBar: AppBar(
          title: Text(
            "Home Screen",
            style: TextStyle(
              color: Colors.white,
              fontSize: height * 0.024,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        backgroundColor: Colors.white,
        body: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            //crossAxisAlignment: CrossAxisAlignment.center,
            //mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: height * 0.024,
              ),
              Center(
                  child: Column(
                children: [
                  Text(
                    "Hello $email",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: height * 0.024,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(
                    height: height * 0.005,
                  ),
                  Text(
                    "GOOD MORNING",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black,
                        fontSize: height * 0.024,
                        fontWeight: FontWeight.w700),
                  ),
                  SizedBox(
                    height: height * 0.015,
                  ),
                  userId != null
                      ? Text('Logged in User ID: $userId')
                      : Text('No user logged in.'),
                ],
              )),
              SizedBox(
                height: height * 0.024,
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LocationListScreen()),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    //Color(0xFF000066),
                    Colors.teal,
                  ),
                  minimumSize: MaterialStateProperty.all(Size(300, 50)),
                ),
                child: Text(
                  "Show Location Lists",
                  style:
                      TextStyle(color: Colors.white, fontSize: height * 0.022),
                ),
              ),
              SizedBox(
                height: height * 0.024,
              ),
              ElevatedButton(
                onPressed: () {
                  // _auth.signOut();
                  FirebaseAuth.instance.signOut();
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                    (route) => false,
                  );

                  print(' Users are Successfully Logged out');
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  minimumSize: MaterialStateProperty.all(Size(300, 50)),
                ),
                child: Text(
                  "Log Out",
                  style:
                      TextStyle(color: Colors.white, fontSize: height * 0.022),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
