import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
// import 'package:background_downloader/background_downloader.dart';

import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
// import 'package:flutter_downloader/flutter_downloader.dart';

import 'package:al_downloader/al_downloader.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:metadata_god/metadata_god.dart';
// import 'package:metadata_god/metadata_god.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:text_scroll/text_scroll.dart';
// import 'package:marquee/marquee.dart';

class SongDetailPage extends StatefulWidget {
  const SongDetailPage(this.item, this.artists, {super.key});
  final dynamic item;
  final dynamic artists;

  @override
  State<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends State<SongDetailPage> {
  List<Color> colors = [
    const Color(0xFF101115),
    Colors.black,
  ];

  Color vibrantColor = const Color.fromRGBO(116, 0, 0, 1);
  Color lightMutedColor = Colors.white;

  void generateColors() async {
    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      NetworkImage(
        widget.item['album']['images'][0]['url'],
      ),
      size: const Size(640, 640),
      region: const Rect.fromLTRB(0, 0, 640, 640),
    );
    setState(() {
      colors = [
        const Color(0xFF101115),
        paletteGenerator.vibrantColor?.color ?? const Color(0xFF101115),
      ];

      vibrantColor =
          paletteGenerator.vibrantColor?.color ?? const Color(0xFF101115);
      lightMutedColor =
          paletteGenerator.lightMutedColor?.color ?? const Color(0xFF101115);
    });
  }

  String formatDuration(int milliseconds) {
    int seconds = milliseconds ~/ 1000;
    int minutes = seconds ~/ 60;
    int hours = minutes ~/ 60;

    String hoursStr = hours.toString().padLeft(2, '0');
    String minutesStr = (minutes % 60).toString().padLeft(2, '0');
    String secondsStr = (seconds % 60).toString().padLeft(2, '0');

    if (hours > 0) {
      return '$hoursStr:$minutesStr:$secondsStr';
    } else {
      return '$minutesStr:$secondsStr';
    }
  }

  // Function to download image from URL and return bytes
  Future<Uint8List> downloadImage(String url) async {
    var response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return Uint8List.fromList(response.bodyBytes);
    } else {
      throw Exception('Failed to load image from URL');
    }
  }

  void attachMetadata() async {
    DateTime dateTime = DateTime.parse(widget.item['album']['release_date']);
    String year = DateFormat('yyyy').format(dateTime);

    var imageUrl = widget.item['album']['images'][0]['url'];
    var imageBytes = await downloadImage(imageUrl);

    var inputFile = "/storage/emulated/0/Download/TuneLoad/finaltry.webm";
    var outputFile =
        "/storage/emulated/0/Download/TuneLoad/finalconversion.mp3";

    await FFmpegKit.execute(
            '-i $inputFile -vn -c:a libmp3lame -ar 44100 -ac 2 -b:a 192k $outputFile')
        .then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print("Ffmpeg process completed with rc $returnCode");

        await MetadataGod.writeMetadata(
            file: "/storage/emulated/0/Download/TuneLoad/finalconversion.mp3",
            metadata: Metadata(
              title: widget.item['name'],
              artist: widget.artists,
              album: widget.item['album']['name'],
              albumArtist: widget.artists,
              trackNumber: widget.item['track_number'],
              trackTotal: widget.item['album']['total_tracks'],
              discNumber: widget.item['disc_number'],
              durationMs: double.parse(widget.item['duration_ms'].toString()),
              year: int.parse(year),
              picture: Picture(
                data: imageBytes,
                mimeType: "image/jpg",
              ),
            ));
      } else if (ReturnCode.isCancel(returnCode)) {
        // CANCEL
      } else {
        print("Error on codec");
        FFmpegKitConfig.enableLogCallback((log) {
          final message = log.getMessage();
          print(message);
        });
      }
    });
  }

  downloadSong() async {
    try {
      var status = await Permission.storage.status;
      if (status.isDenied) {
        await Permission.storage.request();
      }
      try {
        // final response = await http.post(
        //   Uri.parse(
        //       "https://c524-2405-acc0-1306-39d9-4d04-33ff-18e7-1d07.ngrok-free.app/"),
        //   headers: {
        //     "Content-Type": "application/x-www-form-urlencoded",
        //   },
        //   body: {
        //     "song_url": widget.item['external_urls']['spotify'],
        //   },
        // );
        // print(response.body);

        final path = Directory("/storage/emulated/0/Download/TuneLoad");
        if ((await path.exists())) {
          print('exists');
        } else {
          print('creating');
          path.create();
        }

        try {
          ALDownloader.download(
              "https://file-examples.com/storage/fe83e1f11c664c2259506f1/2017/11/file_example_MP3_700KB.mp3",
              directoryPath: "/storage/emulated/0/Download/TuneLoad/",
              fileName: "finaltry.webm",
              handlerInterface:
                  ALDownloaderHandlerInterface(progressHandler: (progress) {
                debugPrint(
                    'ALDownloader | download progress = $progress, url \n');
              }, succeededHandler: () {
                debugPrint('ALDownloader | download succeeded, url = \n');
                attachMetadata();
              }, failedHandler: () {
                debugPrint('ALDownloader | download failed, url = \n');
              }, pausedHandler: () {
                debugPrint('ALDownloader | download paused, url = \n');
              }));
        } catch (e) {
          print(e);
        }

        // try {
        //   final id = await FlutterDownloader.enqueue(
        //     url: response.body,
        //     savedDir: '/storage/emulated/0/Download/TuneLoad/',
        //     fileName: "finaltry.webm",
        //     showNotification: true,
        //     openFileFromNotification: true,
        //   );

        //   print("this is id of downloader $id");
        // } catch (e) {
        //   print(e);
        // }

        //   try {
        //     final task = DownloadTask(
        //         url: response.body,
        //         filename: "finaltry.webm",
        //         directory: '/storage/emulated/0/Download/TuneLoad/',
        //         updates: Updates
        //             .statusAndProgress, // request status and progress updates
        //         requiresWiFi: true,
        //         retries: 5,
        //         allowPause: true);

        //     final result = await FileDownloader().download(task,
        //         onProgress: (progress) => print('Progress: ${progress * 100}%'),
        //         onStatus: (status) => print('Status: $status'));

        //     switch (result.status) {
        //       case TaskStatus.complete:
        //         print('Success!');

        //       case TaskStatus.canceled:
        //         print('Download was canceled');

        //       case TaskStatus.paused:
        //         print('Download was paused');

        //       default:
        //         print('Download not successful');
        //     }
        //   } catch (e) {}
      } catch (e) {
        print(e);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    generateColors();

    ALDownloader.initialize();
    ALDownloader.configurePrint(true, frequentEnabled: false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            stops: const [0.6, 1],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: colors,
          ),
        ),
        child: Center(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10),
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.3),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // title start
                        SizedBox(
                          width: double.infinity,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        const Color.fromRGBO(139, 139, 139, 1),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                  color:
                                      const Color.fromRGBO(217, 217, 217, 0.25),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    Get.back();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      PhosphorIconsBold.arrowLeft,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Column(
                                      children: [
                                        const Text(
                                          "From Album",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontFamily: 'Circular',
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        if (widget
                                                .item['album']['name'].length <
                                            35)
                                          Text(
                                            widget.item['album']['name'],
                                            style: const TextStyle(
                                              fontFamily: 'CircularStd',
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        if (widget
                                                .item['album']['name'].length >=
                                            35)
                                          ConstrainedBox(
                                            constraints: const BoxConstraints(
                                              maxHeight: 20,
                                              maxWidth: 300,
                                              minWidth: 300,
                                              minHeight: 20,
                                            ),
                                            child: TextScroll(
                                              widget.item['album']['name'],
                                              mode: TextScrollMode.endless,
                                              velocity: const Velocity(
                                                  pixelsPerSecond:
                                                      Offset(50, 0)),
                                              delayBefore: const Duration(
                                                  milliseconds: 800),
                                              pauseBetween: const Duration(
                                                  milliseconds: 1000),
                                              style: const TextStyle(
                                                fontFamily: 'CircularStd',
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w900,
                                              ),
                                              textAlign: TextAlign.right,
                                              selectable: true,
                                            ),
                                            //  Marquee(
                                            //   text: widget.item['album']
                                            //       ['name'],
                                            //   style: const TextStyle(
                                            //     fontFamily: 'CircularStd',
                                            //     fontSize: 12,
                                            //     color: Colors.white,
                                            //     fontWeight: FontWeight.w900,
                                            //   ),
                                            //   scrollAxis: Axis.horizontal,
                                            //   crossAxisAlignment:
                                            //       CrossAxisAlignment.start,
                                            //   blankSpace: 20.0,
                                            //   velocity: 25.0,
                                            //   pauseAfterRound:
                                            //       const Duration(seconds: 1),
                                            //   decelerationCurve: Curves.easeOut,
                                            //   startAfter:
                                            //       const Duration(seconds: 3),
                                            // ),
                                          )
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        //title end

                        const SizedBox(
                          height: 30,
                        ),
                        SizedBox(
                          width: 300,
                          child: Image(
                            image: NetworkImage(
                              widget.item['album']['images'][0]['url'],
                            ),
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (BuildContext context,
                                Object exception, StackTrace? stackTrace) {
                              return const Text('Failed to load image');
                            },
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        if (widget.item['name'].length < 35)
                          Text(
                            widget.item['name'],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontFamily: 'Circular',
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        if (widget.item['name'].length >= 35)
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 30,
                              minHeight: 30,
                              maxWidth: double.infinity,
                              minWidth: double.infinity,
                            ),
                            child: TextScroll(
                              widget.item['name'],
                              mode: TextScrollMode.endless,
                              velocity: const Velocity(
                                  pixelsPerSecond: Offset(60, 0)),
                              delayBefore: const Duration(milliseconds: 500),
                              pauseBetween: const Duration(milliseconds: 1000),
                              style: const TextStyle(
                                fontFamily: 'CircularStd',
                                fontSize: 20,
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                              textAlign: TextAlign.right,
                              selectable: true,
                            ),
                            // Marquee(
                            //   text: widget.item['name'],
                            //   style: const TextStyle(
                            //     fontFamily: 'CircularStd',
                            //     fontSize: 20,
                            //     color: Colors.white,
                            //     fontWeight: FontWeight.w900,
                            //   ),
                            //   scrollAxis: Axis.horizontal,
                            //   crossAxisAlignment: CrossAxisAlignment.start,
                            //   blankSpace: 20.0,
                            //   velocity: 25.0,
                            //   pauseAfterRound: const Duration(seconds: 1),
                            //   decelerationCurve: Curves.easeOut,
                            //   startAfter: const Duration(seconds: 3),
                            // ),
                          ),

                        Text(
                          widget.artists,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 15,
                            fontFamily: 'Circular',
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        //buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(PhosphorIconsBold.heart),
                              color: lightMutedColor,
                            ),
                            FilledButton.icon(
                              onPressed: () {
                                downloadSong();
                              },
                              icon:
                                  const Icon(PhosphorIconsBold.downloadSimple),
                              label: const Text("Download Now"),
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all<Color>(
                                        vibrantColor),
                              ),
                            ),
                          ],
                        ),
                        //buttons end

                        const SizedBox(
                          height: 30,
                        ),
                        //metadata
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20.0,
                                    horizontal: 0,
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Popularity",
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Circular',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        widget.item['popularity'].toString(),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 35,
                                          fontFamily: 'Circular',
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20.0,
                                    horizontal: 0,
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Duration",
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Circular',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        formatDuration(
                                            widget.item['duration_ms']),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 35,
                                          fontFamily: 'Circular',
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        //second meta data
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20.0,
                                    horizontal: 0,
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Disc Number",
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Circular',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        widget.item['disc_number'].toString(),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 35,
                                          fontFamily: 'Circular',
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 20,
                            ),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 20.0,
                                    horizontal: 0,
                                  ),
                                  child: Column(
                                    children: [
                                      const Text(
                                        "Total Tracks",
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontFamily: 'Circular',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 20,
                                      ),
                                      Text(
                                        widget.item['album']['total_tracks']
                                            .toString(),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 35,
                                          fontFamily: 'Circular',
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                        //metadata end
                      ],
                    ),
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
