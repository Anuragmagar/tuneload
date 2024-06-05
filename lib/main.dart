import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';
import 'package:tuneload/local_notifications.dart';
import 'package:tuneload/pages/downloadspage.dart';
import 'package:tuneload/pages/favouritespage.dart';
import 'package:tuneload/pages/homepage.dart';
import 'package:tuneload/pages/topbar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MetadataGod.initialize();
  await LocalNotification.init();
  await Hive.initFlutter();
  await Hive.openBox('favourites');

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
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
                    if (_currentIndex == 1) const Favouritespage(),
                    if (_currentIndex == 2) const Downloadspage(),
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
            icon: const Icon(
              PhosphorIconsBold.house,
              // size: 18,
              color: Colors.white,
            ),
            title: const Text("Home"),
            selectedColor: const Color.fromARGB(255, 224, 224, 224),
          ),

          /// Search
          SalomonBottomBarItem(
            icon: const Icon(PhosphorIconsBold.heart),
            title: const Text("Favourites"),
            selectedColor: Colors.white,
          ),

          /// Profile
          SalomonBottomBarItem(
            icon: const Icon(PhosphorIconsBold.downloadSimple),
            title: const Text("Downloads"),
            selectedColor: Colors.white,
          ),

          /// Profile
          SalomonBottomBarItem(
            icon: const Icon(PhosphorIconsBold.user),
            title: const Text("Profile"),
            selectedColor: Colors.white,
          ),
        ],
      ),
      // ),
    );
  }
}
