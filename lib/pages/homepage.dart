import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tuneload/pages/greeting.dart';
import 'package:tuneload/pages/searchpage.dart';
import 'dart:convert'; // required to encode/decode json data
import 'package:http/http.dart' as http;

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  Map<String, dynamic> results = {};
  bool isSearching = true;
  bool isSearchTap = false;
  bool hasError = false;
  String errorMsg = ' ';
  int totalSongs = 0;
  String token =
      "BQDLuvGbG2ls8qNNkvml15ekfDrjUJrtby67LLYsgn5gyHgCen32-5SbDWKT_AfTUcKrgDoCTPOfQVbubd9mbYlK5MQ1_MH3XNaKupBONoW6LxXXG0A";

  getAccessToken() async {
    try {
      final response = await http
          .post(Uri.parse("https://accounts.spotify.com/api/token"), headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      }, body: {
        "grant_type": "client_credentials",
        "client_id": "5d9129c2a9224eb8903668e80796b1cf",
        "client_secret": "50a052bfbfaf4934b33537202098b3f0",
      });
      final body = json.decode(response.body);
      setState(() {
        token = body["access_token"];
      });
      getRecommendation();
    } catch (e) {
      print(e);
    }
  }

  void getRecommendation() async {
    // final ass = await getAccessToken();
    setState(() {
      hasError = false;
      errorMsg = ' ';
      isSearching = true;
      isSearchTap = true;
    });
    try {
      final response = await http.get(
        Uri.parse(
            "https://api.spotify.com/v1/recommendations?seed_artists=3sauLUNFUPvJVWIADSYTvZ&seed_genres=nepali+indie%2Cclassical%2Ccountry&seed_tracks=0c6xIDDpzE81m2q797ordA"),
        headers: {
          "Content-Type": "application/json",
          "authorization": "Bearer $token"
        },
      );
      final body = json.decode(response.body);
      final errorstat = body['error'];
      print(body);
      if (errorstat != null) {
        setState(() {
          hasError = true;
          errorMsg = body['error']['message'];
        });
        int errorCode = body['error']['status'];
        if (errorCode == 401) {
          getAccessToken();
        }
      }
      setState(() {
        isSearching = false;
        isSearchTap = false;
        results = body;
      });
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getAccessToken();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(
          height: 50,
        ),

        //Greeting
        const Greeting(),

        const SizedBox(
          height: 30,
        ),

        //Search
        const Text(
          "Search",
          style: TextStyle(
            color: Colors.white,
            fontSize: 33,
            fontFamily: 'Circular',
            fontWeight: FontWeight.w900,
          ),
        ),

        const SizedBox(
          height: 10,
        ),
        GestureDetector(
          onTap: () {
            // Navigator.push(context, MaterialPageRoute(builder: (context)=> const SearchPage()));
            Get.to(
              () => const SearchPage(),
              transition: Transition.downToUp,
              duration: const Duration(milliseconds: 100),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color.fromRGBO(217, 104, 104, 1),
              ),
              borderRadius: BorderRadius.circular(10),
              color: const Color.fromRGBO(217, 107, 107, 0.36),
            ),
            width: double.infinity,
            child: const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 8.0,
                vertical: 13,
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIconsBold.magnifyingGlass,
                    // size: 20,
                    color: Colors.white,
                  ),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Enter music title to download",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Circular',
                      fontWeight: FontWeight.w900,
                    ),
                  )
                ],
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 50,
        ),

        //Recommendation
        const Text(
          "Recommended for you",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 20),
        isSearching
            ? SizedBox(
                width: double.infinity,
                height: 250,
                child: Shimmer.fromColors(
                  baseColor: Colors.grey.shade500,
                  highlightColor: const Color.fromRGBO(147, 65, 78, 1),
                  enabled: true,
                  period: const Duration(seconds: 1),
                  child: ListView.builder(
                    itemCount: 7,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (build, context) => SizedBox(
                      width: 200,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 200,
                              width: 200,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 10,
                              width: 100,
                              color: Colors.white70,
                            ),
                            const SizedBox(height: 10),
                            Container(
                              height: 10,
                              width: 100,
                              color: Colors.white70,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),

        SizedBox(
          height: 234,
          child: !isSearching
              ? ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: results['tracks'].length,
                  itemBuilder: (context, index) {
                    final item = results['tracks'][index];

                    List<dynamic> artistNames = item['artists']
                        .map((artist) => artist['name'])
                        .toList();
                    String combinedArtistNames = artistNames.join(', ');

                    return SizedBox(
                      width: 200,
                      child: Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image(
                              image: NetworkImage(
                                item['album']['images'][0]['url'],
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              item['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900),
                            ),
                            Text(
                              combinedArtistNames,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.normal),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
        // SizedBox(
        //   height: 250,
        //   child: ListView.builder(
        //     // shrinkWrap: true,
        //     physics: const BouncingScrollPhysics(),
        //     scrollDirection: Axis.horizontal,
        //     itemCount: 10,

        //     itemBuilder: (context, innerIndex) {
        //       return const SizedBox(
        //         width: 200,
        //         child: Padding(
        //           padding: EdgeInsets.only(right: 20),
        //           child: Column(
        //             crossAxisAlignment: CrossAxisAlignment.start,
        //             children: [
        //               Image(
        //                 image: AssetImage('assets/images/lana.jpg'),
        //               ),
        //               SizedBox(height: 10),
        //               Text(
        //                 "Radio",
        //                 style: TextStyle(
        //                     color: Colors.white,
        //                     fontSize: 14,
        //                     fontWeight: FontWeight.w900),
        //               ),
        //               Text(
        //                 "Lana Del Rey",
        //                 style: TextStyle(
        //                     color: Colors.white,
        //                     fontSize: 14,
        //                     fontWeight: FontWeight.normal),
        //               ),
        //             ],
        //           ),
        //         ),
        //       );
        //     },
        //   ),
        // )
      ],
    );
  }
}
