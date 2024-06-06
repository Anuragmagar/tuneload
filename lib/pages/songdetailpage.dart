import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:animated_digit/animated_digit.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuneload/local_notifications.dart';
import 'package:tuneload/pages/explicit.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:device_info_plus/device_info_plus.dart';

class SongDetailPage extends ConsumerStatefulWidget {
  SongDetailPage(this.item, this.artists, this.highResImageUrl, {super.key});
  final dynamic item;
  String artists;
  final String highResImageUrl;

  @override
  ConsumerState<SongDetailPage> createState() => _SongDetailPageState();
}

class _SongDetailPageState extends ConsumerState<SongDetailPage> {
  final YoutubeExplode yt = YoutubeExplode();
  Video? currentSong;
  String likes = "0";
  String views = "0";
  String year = "0000";
  String author = "Unknown Artist";
  bool isOnFavourite = false;
  dynamic favouriteKey = '';

  List<Color> colors = [
    const Color(0xFF101115),
    Colors.black,
  ];

  Color vibrantColor = const Color.fromRGBO(116, 0, 0, 1);
  Color lightMutedColor = Colors.white;

  void generateColors() async {
    final thumbnail = widget.item['thumbnails'].last;

    final paletteGenerator = await PaletteGenerator.fromImageProvider(
      NetworkImage(
        thumbnail['url'],
      ),
      size: const Size(540, 540),
      region: const Rect.fromLTRB(0, 0, 540, 540),
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

  static Future<String> getExternalDocumentPath() async {
    final DeviceInfoPlugin info = DeviceInfoPlugin();
    final AndroidDeviceInfo androidInfo = await info.androidInfo;
    final int androidVersion = int.parse(androidInfo.version.release);

    if (androidVersion < 13) {
      var status = await Permission.storage.status;

      if (!status.isGranted) {
        await Permission.storage.request();
      }
    } else {
      var status = await Permission.audio.status;
      var notistatus = await Permission.notification.status;
      if (!status.isGranted) {
        await Permission.audio.request();
      }
      if (!notistatus.isGranted) {
        await Permission.notification.request();
      }
    }

    Directory directory = Directory("dir");
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/Download/TuneLoad");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final exPath = directory.path;
    await Directory(exPath).create(recursive: true);
    return exPath;
  }

  static Future<String> get _localPath async {
    final String directory = await getExternalDocumentPath();
    return directory;
  }

  void attachMetadata(String inputFile) async {
    var imageBytes = await downloadImage(widget.highResImageUrl);

    // var inputFile = "/storage/emulated/0/Download/TuneLoad/finaltry.webm";
    String filePath = await _localPath;
    var outputFile = "$filePath/${widget.item['videoId']}.mp3";

    await FFmpegKit.execute(
            '-i $inputFile -vn -c:a libmp3lame -ar 44100 -ac 2 -b:a 192k $outputFile')
        .then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        await File(inputFile).delete();

        await MetadataGod.writeMetadata(
          file: outputFile,
          metadata: Metadata(
            title: widget.item['title'],
            artist: widget.artists,
            album: widget.item['album']['name'],
            albumArtist: widget.artists,
            // trackNumber: widget.item['track_number'],
            // trackTotal: widget.item['album']['total_tracks'],
            // discNumber: widget.item['disc_number'],
            durationMs:
                double.parse(widget.item['duration_seconds'].toString()) * 1000,
            year: int.parse(year),
            picture: Picture(
              data: imageBytes,
              mimeType: "image/jpg",
            ),
          ),
        );
        await File(outputFile).rename(
            "$filePath/${widget.item['title']} - ${widget.artists}.mp3");

        LocalNotification.cancelNotification(
            int.parse(widget.item['duration_seconds'].toString()) + 1);

        final loadmsg = await MediaScanner.loadMedia(
          path: "$filePath/${widget.item['title']} - ${widget.artists}.mp3",
        );

        LocalNotification.showSimpleNotification(
            title: "Download complete!",
            body: "${widget.item['title']} - ${widget.artists}.mp3",
            payload: "thisi s simple data");
      } else if (ReturnCode.isCancel(returnCode)) {
        // CANCEL
      } else {
        FFmpegKitConfig.enableLogCallback((log) {
          // final message = log.getMessage();
        });
      }
    });
  }

  downloadSong() async {
    try {
      String fileName = widget.item['videoId'];
      String filePath = await _localPath;

      LocalNotification.showIndeterminateProgressNotification(
        id: int.parse(widget.item['duration_seconds'].toString()),
        title: "Downloading started ...",
        body: "Preparing link",
      );

      final StreamManifest manifest =
          await yt.videos.streamsClient.getManifest(widget.item['videoId']);
      final List<AudioOnlyStreamInfo> sortedStreamInfo =
          manifest.audioOnly.sortByBitrate();

      // print(sortedStreamInfo.first.url.toString());

      LocalNotification.cancelNotification(
          int.parse(widget.item['duration_seconds'].toString()));

      final task = DownloadTask(
        url: sortedStreamInfo.first.url.toString(),
        filename: "$fileName.webm",
        displayName: widget.item['title'],
        directory: filePath,
        updates:
            Updates.statusAndProgress, // request status and progress updates
        requiresWiFi: true,
        // retries: 5,
        allowPause: true,
      );

      final TaskStatusUpdate result = await FileDownloader()
          .download(task, onProgress: (progress) {}, onStatus: (status) {});

      switch (result.status) {
        case TaskStatus.complete:
          final ddpath = await FileDownloader()
              .moveToSharedStorage(task, SharedStorage.downloads,
                  directory: "TuneLoad")
              .then(
            (value) async {
              LocalNotification.showIndeterminateProgressNotification(
                id: int.parse(widget.item['duration_seconds'].toString()) + 1,
                title: "Converting & embedding metadata ...",
                body: "This may take a few seconds",
              );
              print("ddpath value $value");

              attachMetadata(value!);
            },
          );
        case TaskStatus.canceled:
          print('Download was canceled');

        case TaskStatus.paused:
          print('Download was paused');

        default:
          print('Download not successful');
      }
    } catch (e) {
      debugPrint("$e");
    }
  }

  String convertImageToHighRes(String url) {
    // Use regular expression to find 'w' followed by digits and '-'
    final widthRegex = RegExp(r'w\d+-');
    // Replace 'w' followed by digits and '-' with 'w540-'
    url = url.replaceAll(widthRegex, 'w540-');

    // Use regular expression to find 'h' followed by digits and '-'
    final heightRegex = RegExp(r'h\d+-');
    // Replace 'h' followed by digits and '-' with 'h540-'
    url = url.replaceAll(heightRegex, 'h540-');

    return url;
  }

  getYtMetadata() async {
    Video video = await yt.videos
        .get('https://youtube.com/watch?v=${widget.item['videoId']}');
    var f = NumberFormat.compact(locale: "en_US");
    setState(() {
      currentSong = video;
      likes = f.format(video.engagement.likeCount);
      views = f.format(video.engagement.viewCount);
      year = video.publishDate?.year.toString() ?? '0';
      widget.artists = widget.item['artists'].isEmpty ?? true
          ? video.author
          : widget.artists;
    });
  }

  Future<void> addFavourite(Map<String, dynamic> newItem) async {
    final favouritesBox = Hive.box('favourites');
    await favouritesBox.add(newItem);
    setState(() {
      isOnFavourite = true;
    });
  }

  void removeFavourite(dynamic removeKey) async {
    final favouritesBox = Hive.box('favourites');
    favouritesBox.delete(removeKey);
    setState(() {
      isOnFavourite = false;
      favouriteKey = '';
    });
  }

  void isFavourite() {
    final favouritesBox = Hive.box('favourites');
    final data = favouritesBox.keys.map((key) {
      final item = favouritesBox.get(key);
      if (item['title'] == widget.item['title']) {
        setState(() {
          isOnFavourite = true;
          favouriteKey = key;
        });
      }
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    generateColors();
    getYtMetadata();
    isFavourite();

    // Registering a callback and configure notifications
    FileDownloader().configureNotification(
      // for the 'Download & Open' dog picture
      // which uses 'download' which is not the .defaultGroup
      // but the .await group so won't use the above config
      running:
          const TaskNotification('Downloading {displayName}.mp3', '{progress}'),
      // complete:
      //     const TaskNotification('Download {filename}', 'Download complete'),
      error: const TaskNotification('Error', '{numFailed}/{numTotal} failed'),
      progressBar: true,
    ); // dog can also open directly from tap

    FileDownloader().trackTasks();
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
                                  // border: Border.all(
                                  //   color:
                                  //       const Color.fromRGBO(139, 139, 139, 1),
                                  //   width: 1,
                                  // ),
                                  borderRadius: BorderRadius.circular(10),
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
                        Container(
                          color: vibrantColor,
                          width: 300,
                          height: 300,
                          child: Image(
                            image: NetworkImage(
                              widget.highResImageUrl,
                            ),
                            fit: BoxFit.contain,
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

                        if (widget.item['title'].length < 35)
                          Text(
                            widget.item['title'],
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
                        if (widget.item['title'].length >= 35)
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxHeight: 30,
                              minHeight: 30,
                              maxWidth: double.infinity,
                              minWidth: double.infinity,
                            ),
                            child: TextScroll(
                              widget.item['title'],
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
                          ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            widget.item['isExplicit']
                                ? const Row(
                                    children: [
                                      ExplicitPage(),
                                      SizedBox(
                                        width: 4.0,
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                            Flexible(
                              child: Text(
                                widget.artists?.isEmpty ?? true
                                    ? 'Unknown Artist'
                                    : widget.artists,
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
                            ),
                          ],
                        ),

                        const SizedBox(
                          height: 10,
                        ),

                        //buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            isOnFavourite
                                ? IconButton(
                                    onPressed: () async {
                                      removeFavourite(favouriteKey);
                                    },
                                    icon: const Icon(PhosphorIconsFill.heart),
                                    color: Colors.white,
                                  )
                                : IconButton(
                                    onPressed: () async {
                                      addFavourite({
                                        "title": widget.item['title'],
                                        "artist": widget.artists,
                                        "duration": widget.item['duration'],
                                        "image": widget.highResImageUrl,
                                        "year": year,
                                        "likes": likes,
                                      });
                                    },
                                    icon: const Icon(PhosphorIconsBold.heart),
                                    color: Colors.white,
                                  ),
                            FilledButton.icon(
                              onPressed: () {
                                downloadSong();
                              },
                              icon:
                                  const Icon(PhosphorIconsBold.downloadSimple),
                              label: const Text("Download Now"),
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
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
                                        "Year",
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
                                      AnimatedDigitWidget(
                                        value: int.parse(year),
                                        textStyle: const TextStyle(
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
                                        widget.item['duration'],
                                        // formatDuration(
                                        //     widget.item['duration_ms']),
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
                                        "Likes",
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
                                        likes,
                                        // widget.item['disc_number'].toString(),
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
                                        "Views",
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
                                        // widget.item['album']['total_tracks']
                                        //     .toString(),
                                        views,
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
