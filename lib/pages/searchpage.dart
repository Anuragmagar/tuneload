import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
// import 'package:tuneload/models/song.dart';
import 'dart:convert'; // required to encode/decode json data
import 'package:http/http.dart' as http;
import 'package:shimmer/shimmer.dart';
import 'package:tuneload/pages/explicit.dart';
import 'package:tuneload/pages/songdetailpage.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  // VideoSearchList? results;
  List<dynamic> results = [];

  bool isSearching = false;
  bool isSearchTap = false;
  bool hasError = false;
  String errorMsg = ' ';
  int totalSongs = 0;
  final YoutubeExplode yt = YoutubeExplode();

  TextEditingController searchTextController = TextEditingController();

  String token =
      "BQDLuvGbG2ls8qNNkvml15ekfDrjUJrtby67LLYsgn5gyHgCen32-5SbDWKT_AfTUcKrgDoCTPOfQVbubd9mbYlK5MQ1_MH3XNaKupBONoW6LxXXG0A";

  void getSongs() async {
    // final ass = await getAccessToken();
    setState(() {
      hasError = false;
      errorMsg = ' ';
      isSearching = true;
      isSearchTap = true;
    });
    try {
      final response = await http.post(
        Uri.parse("https://tuneload.anuragmagar.com.np/"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "song": searchTextController.text,
        },
      );
      final value = json.decode(response.body);
      setState(() {
        isSearching = false;
        isSearchTap = false;
        results = value;
        totalSongs = results.length;
        // print(results);
      });
      // print(results);
      // print(value);

      // CxcIZL4Tajg
      // var video =
      //     await yt.videos.get('https://youtube.com/watch?v=by0lRnN7Cp0');
      // print(video);

      // final List<Video> searchResults =
      //     await yt.search(searchTextController.text).then(
      //   (value) {
      //     setState(() {
      //       isSearching = false;
      //       isSearchTap = false;
      //       results = value;
      //       totalSongs = results.length;
      //       // print(results);
      //     });
      //     print(value);
      //     return value;
      //   },
      // );

      // final StreamManifest manifest =
      //     await yt.videos.streamsClient.getManifest("CxcIZL4Tajg");
      // final List<AudioOnlyStreamInfo> sortedStreamInfo =
      //     manifest.audioOnly.sortByBitrate();

      // print(sortedStreamInfo);

      // print(sortedStreamInfo.first.url.toString());
      // print(sortedStreamInfo.last.url.toString());

      // print(searchResults);
      // var video = await yt.videos.get(
      //     'https://www.youtube.com/watch?v=u_yIGGhubZs'); // Returns a Video instance.
      // // print(video);
      // var title = video.title;
      // var author = video.author;
      // var duration = video.duration;
      // print(title);
      // print(author);
      // print(duration);
      // final response = await http.get(
      //   Uri.parse(
      //       "https://api.spotify.com/v1/search?q=${searchTextController.text}&type=track"),
      //   headers: {
      //     "Content-Type": "application/json",
      //     "authorization": "Bearer $token"
      //   },
      // );
      // final body = json.decode(response.body);
      // final errorstat = body['error'];
      // if (errorstat != null) {
      //   setState(() {
      //     hasError = true;
      //     errorMsg = body['error']['message'];
      //     print(errorMsg);
      //   });
      //   int errorCode = body['error']['status'];
      //   if (errorCode == 401) {
      //     getAccessToken();
      //   }
      // }
      // setState(() {
      //   isSearching = false;
      //   isSearchTap = false;
      //   results = body;
      //   totalSongs = results['tracks']['total'];
      //   print(results);
      //   print(results['tracks']['items'][0]['album']['images'][0]['url']);
      // });
    } catch (e) {
      print(e);
    }
  }

  // Future<List<Song>> songsFuture = getSongs();
  @override
  void initState() {
    super.initState();
    // getSongs();
  }

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
        child: Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10),
            child: Container(
              color: Colors.black.withOpacity(
                  0.3), // You can adjust the opacity to your liking
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Theme(
                        data: Theme.of(context).copyWith(
                          textSelectionTheme: const TextSelectionThemeData(
                            selectionColor: Color.fromARGB(122, 255, 255, 255),
                          ),
                        ),
                        child: TextField(
                          controller: searchTextController,
                          style: const TextStyle(color: Colors.white),
                          autofocus: true,
                          cursorColor: Colors.white,
                          onSubmitted: (_) => getSongs(),
                          decoration: InputDecoration(
                            isCollapsed: true,
                            filled: true,
                            enabled: true,
                            fillColor: const Color.fromRGBO(217, 107, 107, 0.1),
                            border: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                color: Color.fromRGBO(217, 104, 104, 1),
                                width: 1,
                              ),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                color: Color.fromRGBO(217, 104, 104, 1),
                                width: 1,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                              borderSide: BorderSide(
                                color: Color.fromRGBO(217, 104, 104, 1),
                                width: 1,
                              ),
                            ),
                            hintText: 'Enter music title to download',
                            contentPadding: const EdgeInsets.fromLTRB(
                                20.0, 10.0, 20.0, 10.0),
                            prefixIcon: IconButton(
                              icon: const Icon(
                                PhosphorIconsBold.arrowLeft,
                              ),
                              color: Colors.white,
                              onPressed: () {
                                Get.back();
                              },
                            ),
                            suffixIcon: Row(
                              // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    PhosphorIconsBold.x,
                                  ),
                                  color: Colors.white,
                                  onPressed: () {
                                    print("cross");
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(
                                    PhosphorIconsBold.magnifyingGlass,
                                  ),
                                  color: Colors.white,
                                  onPressed: () {
                                    getSongs();
                                  },
                                ),
                              ],
                            ),
                            hintStyle: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      //End of search text box

                      const SizedBox(
                        height: 15,
                      ),

                      isSearchTap
                          ? const Text(
                              "0 results",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            )
                          : const SizedBox.shrink(),

                      isSearching
                          ? SizedBox(
                              height: 1000,
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey.shade500,
                                highlightColor:
                                    const Color.fromRGBO(147, 65, 78, 1),
                                enabled: true,
                                period: const Duration(seconds: 1),
                                child: ListView.builder(
                                  itemCount: 7,
                                  itemBuilder: (build, context) => Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.max,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 60,
                                          height: 60,
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12.0),
                                            color: const Color.fromRGBO(
                                                147, 65, 78, 1),
                                          ),
                                        ),
                                        const SizedBox(width: 12.0),
                                        Expanded(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                height: 10.0,
                                                color: const Color.fromRGBO(
                                                    147, 65, 78, 1),
                                                margin: const EdgeInsets.only(
                                                    bottom: 8.0),
                                              ),
                                              Container(
                                                width: 100.0,
                                                height: 10.0,
                                                color: const Color.fromRGBO(
                                                    147, 65, 78, 1),
                                              )
                                            ],
                                          ),
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),

                      hasError
                          ? Padding(
                              padding: const EdgeInsets.only(top: 120.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color:
                                      const Color.fromRGBO(217, 107, 107, 0.1),
                                  border: Border.all(
                                    color:
                                        const Color.fromRGBO(217, 104, 104, 1),
                                  ),
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                child: Column(
                                  children: [
                                    const SizedBox(height: 20.0),
                                    const SizedBox(
                                      height: 150,
                                      child: Center(
                                        child: Image(
                                          image: AssetImage(
                                              'assets/images/search.png'),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 20,
                                    ),
                                    Text(
                                      errorMsg,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(
                                      height: 10,
                                    )
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),

                      Expanded(
                        child: totalSongs > 0
                            ? ListView.builder(
                                itemCount: results.length,
                                itemBuilder: (context, index) {
                                  final item = results[index];
                                  print(item);
                                  // print(item.thumbnails);
                                  // final item =
                                  //     results?.items[index];

                                  // List<String, dynamic> artistNames = item
                                  //     .map((artist) => item['artists'])
                                  //     .toList();
                                  List<dynamic> artistNames =
                                      item['artists'] != null
                                          ? item['artists']
                                              .map((artist) =>
                                                  artist['name'] ?? 'N/A')
                                              .toList()
                                          : [];
                                  String combinedArtistNames =
                                      artistNames.join(', ');

                                  //to get the highest resolution image url
                                  // Use regular expression to find 'w' followed by digits and '-'
                                  final widthRegex = RegExp(r'w\d+-');
                                  // Replace 'w' followed by digits and '-' with 'w540-'
                                  String highResImageUrl = item['thumbnails']
                                      .last['url']
                                      .replaceAll(widthRegex, 'w540-');

                                  // Use regular expression to find 'h' followed by digits and '-'
                                  final heightRegex = RegExp(r'h\d+-');
                                  // Replace 'h' followed by digits and '-' with 'h540-'
                                  highResImageUrl = highResImageUrl.replaceAll(
                                      heightRegex, 'h540-');

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 15),
                                    child: GestureDetector(
                                      onTap: () {
                                        Get.to(
                                          () => SongDetailPage(
                                              item,
                                              combinedArtistNames,
                                              highResImageUrl),
                                          transition: Transition.rightToLeft,
                                          duration:
                                              const Duration(milliseconds: 300),
                                        );
                                      },
                                      child: Row(
                                        mainAxisSize: MainAxisSize.max,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(12.0),
                                              color: const Color.fromRGBO(
                                                  147, 65, 78, 1),
                                            ),
                                            child:
                                                // SizedBox.shrink(),
                                                Image(
                                              image: NetworkImage(
                                                item['thumbnails'].last['url'],
                                              ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                          const SizedBox(width: 12.0),
                                          Expanded(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  // item.title,
                                                  item['title'] ?? 'N/A',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w900),
                                                ),
                                                Row(
                                                  children: [
                                                    item['isExplicit']
                                                        ? const Row(
                                                            children: [
                                                              ExplicitPage(),
                                                              SizedBox(
                                                                width: 4.0,
                                                              ),
                                                            ],
                                                          )
                                                        : const SizedBox
                                                            .shrink(),
                                                    Flexible(
                                                      child: Text(
                                                        '${combinedArtistNames?.isEmpty ?? true ? 'Unknown Artist' : combinedArtistNames} • ${item['duration']}',
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          color: Colors.white70,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
