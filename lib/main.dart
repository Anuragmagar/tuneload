import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:tuneload/pages/homepage.dart';
import 'package:tuneload/pages/topbar.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Color.fromARGB(255, 35, 37, 46),
      // systemNavigationBarDividerColor: Colors.white,
      // statusBarColor: Colors.pink, // status bar color
      // systemNavigationBarIconBrightness: Brightness.light,
    ));
    return GetMaterialApp(
      theme: ThemeData(
        fontFamily: 'Circular',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var _currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        // height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            stops: [0.6, 1],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xFF101115), Color(0xFF832F47)],
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10),
          child: Container(
            color: Colors.black
                .withOpacity(0.3), // You can adjust the opacity to your liking
            child: SafeArea(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: ListView(
                  children: [
                    // App bar
                    const Topbar(),

                    if (_currentIndex == 0) const Homepage(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      // bottomNavigationBar: ,
      bottomNavigationBar: SalomonBottomBar(
        unselectedItemColor: Colors.white,
        backgroundColor: Color.fromARGB(255, 35, 37, 46),
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: [
          /// Home
          SalomonBottomBarItem(
            icon: Icon(
              PhosphorIconsBold.house,
              // size: 18,
              color: Colors.white,
            ),
            title: Text("Home"),
            selectedColor: Color.fromARGB(255, 224, 224, 224),
          ),

          /// Likes
          SalomonBottomBarItem(
            icon: Icon(Icons.favorite_border),
            title: Text("Likes"),
            selectedColor: Colors.pink,
          ),

          /// Search
          SalomonBottomBarItem(
            icon: Icon(Icons.search),
            title: Text("Search"),
            selectedColor: Colors.orange,
          ),

          /// Profile
          SalomonBottomBarItem(
            icon: Icon(Icons.person),
            title: Text("Profile"),
            selectedColor: Colors.teal,
          ),
        ],
      ),
      // ),
    );
  }
}
