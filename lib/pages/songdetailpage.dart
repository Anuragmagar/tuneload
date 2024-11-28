import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:animated_digit/animated_digit.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:audiotagger/audiotagger.dart';
import 'package:audiotagger/models/tag.dart';
// import 'package:background_downloader/background_downloader.dart';
import 'package:flutter_file_downloader/flutter_file_downloader.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
import 'package:flip_card/flip_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:media_scanner/media_scanner.dart';
import 'package:metadata_god/metadata_god.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:text_scroll/text_scroll.dart';
import 'package:path_provider/path_provider.dart';
import 'package:tuneload/local_notifications.dart';
import 'package:tuneload/manager/audio_player_manager.dart';
import 'package:tuneload/pages/explicit.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:rxdart/rxdart.dart' as rxdart;
import 'package:flutter_lyric/lyric_ui/lyric_ui.dart';
import 'package:flutter_lyric/lyric_ui/ui_netease.dart';
import 'package:flutter_lyric/lyrics_model_builder.dart';
import 'package:flutter_lyric/lyrics_reader_widget.dart';

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
  final player = AudioPlayer();
  late Stream<DurationState> durationState;

  Video? currentSong;
  String likes = "0";
  String views = "0";
  String year = "0000";
  String author = "Unknown Artist";
  bool isOnFavourite = false;
  dynamic favouriteKey = '';

  bool playing = false;
  bool loading = true;

  bool loadingLyrics = true;
  GlobalKey<FlipCardState> flipCardKey = GlobalKey<FlipCardState>();
  Map<String, dynamic> lyrics = {};
  var lyricUI = UINetease(
    highlight: false,
    defaultSize: 20,
    // otherMainSize: 25,
    lyricAlign: LyricAlign.CENTER,
  );
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

        if (lyrics.isNotEmpty) {
          getLyrics;
        }

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

        final tagger = Audiotagger();
        if (lyrics['syncedLyrics'] != null) {
          final result = await tagger.writeTags(
            path: outputFile,
            tag: Tag(
              lyrics: utf8.decode(lyrics['syncedLyrics'].codeUnits),
            ),
          );
          print('Success $result');
        } else if (lyrics['plainLyrics'] != null) {
          final result = await tagger.writeTags(
            path: outputFile,
            tag: Tag(
              lyrics: utf8.decode(lyrics['plainLyrics'].codeUnits),
            ),
          );
          print('Success $result');
        } else {
          print('No lyrics to write');
        }

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

      LocalNotification.cancelNotification(
          int.parse(widget.item['duration_seconds'].toString()));

      getLyrics();

      FileDownloader.downloadFile(
        url: sortedStreamInfo.first.url.toString(),
        name: "$fileName.webm",
        // name: "$fileName.mp3",
        subPath: '/TuneLoad',
        onProgress: (String? fileName, double progress) {
          // setState(() {
          //   downloadedBytes = progress / 100;
          // });
          print("progress $progress");
        },
        onDownloadCompleted: (String fpath) {
          // MediaScanner.loadMedia(path: fpath);

          // setState(() {
          //   downloaded = true;
          //   path = fpath;
          // });

          // ref.read(isVersionCheckedProvider.notifier).update((state) => true);

          LocalNotification.showIndeterminateProgressNotification(
            id: int.parse(widget.item['duration_seconds'].toString()) + 1,
            title: "Converting & embedding metadata ...",
            body: "This may take a few seconds",
          );
          // print("ddpath value $value");

          attachMetadata(fpath);
        },
        onDownloadError: (String error) {},
        downloadDestination: DownloadDestinations.publicDownloads,
      );

      // final task = DownloadTask(
      //   url: sortedStreamInfo.first.url.toString(),
      //   filename: "$fileName.webm",
      //   displayName: widget.item['title'],
      //   directory: filePath,
      //   updates:
      //       Updates.statusAndProgress, // request status and progress updates
      //   requiresWiFi: true,
      //   // retries: 5,
      //   allowPause: true,
      // );

      // final TaskStatusUpdate result = await FileDownloader()
      //     .download(task, onProgress: (progress) {}, onStatus: (status) {});

      // switch (result.status) {
      //   case TaskStatus.complete:
      //     final ddpath = await FileDownloader()
      //         .moveToSharedStorage(task, SharedStorage.downloads,
      //             directory: "TuneLoad")
      //         .then(
      //       (value) async {
      //         LocalNotification.showIndeterminateProgressNotification(
      //           id: int.parse(widget.item['duration_seconds'].toString()) + 1,
      //           title: "Converting & embedding metadata ...",
      //           body: "This may take a few seconds",
      //         );
      //         print("ddpath value $value");

      //         attachMetadata(value!);
      //       },
      //     );
      //   case TaskStatus.canceled:
      //     print('Download was canceled');

      //   case TaskStatus.paused:
      //     print('Download was paused');

      //   default:
      //     print('Download not successful');
      // }
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
    final StreamManifest manifest =
        await yt.videos.streamsClient.getManifest(widget.item['videoId']);
    final List<AudioOnlyStreamInfo> sortedStreamInfo =
        manifest.audioOnly.sortByBitrate();

    print(sortedStreamInfo.first.url.toString());
    await player.setUrl(sortedStreamInfo.first.url.toString());

    setState(() {
      loading = false;
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

  void streamMusic() async {
    player.play();
    setState(() {
      playing = true;
    });
  }

  void pauseMusic() async {
    await player.pause();
    setState(() {
      playing = false;
    });
  }

  void getLyrics() async {
    try {
      final queryParameters = {
        'track_name': widget.item['title'],
        'artist_name': widget.artists,
        'album_name': widget.item['album']['name'],
        'duration': '${widget.item['duration_seconds']}',
      };
      final uri = Uri.https('lrclib.net', '/api/get', queryParameters);
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        setState(() {
          lyrics = jsonDecode(response.body);
          print("lyrics $lyrics");
          loadingLyrics = false;
        });
      } else {
        print("Tyring with multiple query");

        final queryParameters = {
          'track_name': widget.item['title'],
          'artist_name': widget.artists,
          'album_name': widget.item['album']['name'],
          'duration': '${widget.item['duration_seconds']}',
        };
        final uri = Uri.https('lrclib.net', '/api/search', queryParameters);
        final response = await http.get(uri);
        if (response.statusCode == 200) {
          setState(() {
            // print(response.body);
            if (jsonDecode(response.body).length > 0) {
              lyrics = jsonDecode(response.body)[0];
            }
            // print(jsonDecode(response.body)[0]);
            print("lyrics $lyrics");
            loadingLyrics = false;
          });
        }
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    generateColors();
    getYtMetadata();
    isFavourite();

    // Registering a callback and configure notifications
    // FileDownloader().configureNotification(
    //   // for the 'Download & Open' dog picture
    //   // which uses 'download' which is not the .defaultGroup
    //   // but the .await group so won't use the above config
    //   running:
    //       const TaskNotification('Downloading {displayName}.mp3', '{progress}'),
    //   // complete:
    //   //     const TaskNotification('Download {filename}', 'Download complete'),
    //   error: const TaskNotification('Error', '{numFailed}/{numTotal} failed'),
    //   progressBar: true,
    // );

    durationState =
        rxdart.Rx.combineLatest2<Duration, PlaybackEvent, DurationState>(
      player.positionStream,
      player.playbackEventStream,
      (position, playbackEvent) => DurationState(
        progress: position,
        buffered: playbackEvent.bufferedPosition,
        total: playbackEvent.duration,
      ),
    ).asBroadcastStream();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    player.dispose();
    durationState.drain();

    super.dispose();
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
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color:
                                        const Color.fromRGBO(139, 139, 139, 1),
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  // color:
                                  //     const Color.fromRGBO(217, 217, 217, 0.25),
                                ),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      getLyrics();
                                    });
                                    flipCardKey.currentState?.toggleCard();
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Icon(
                                      PhosphorIconsBold.musicNotes,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        //title end

                        const SizedBox(
                          height: 30,
                        ),

                        FlipCard(
                          key: flipCardKey,
                          flipOnTouch: false,
                          fill: Fill
                              .fillBack, // Fill the back side of the card to make in the same size as the front.
                          direction: FlipDirection.HORIZONTAL, // default
                          side:
                              CardSide.FRONT, // The side to initially display.
                          front: GestureDetector(
                            onTap: () async {
                              getLyrics();
                              flipCardKey.currentState?.toggleCard();
                            },
                            child: Container(
                              color: vibrantColor,
                              width: 300,
                              height: 300,
                              child: Image(
                                image: NetworkImage(
                                  widget.highResImageUrl,
                                ),
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
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
                          ),
                          back: GestureDetector(
                            onTap: () => flipCardKey.currentState?.toggleCard(),
                            child: Container(
                              child: loadingLyrics
                                  ? SizedBox(
                                      width: 300.0,
                                      height: 300.0,
                                      child: Shimmer.fromColors(
                                        baseColor: Colors.grey.shade300,
                                        highlightColor: Colors.grey.shade100,
                                        child: Container(
                                          color: Colors.white70,
                                        ),
                                      ),
                                    )
                                  : StreamBuilder<DurationState>(
                                      stream: durationState,
                                      builder: (context, snapshot) {
                                        final durationState = snapshot.data;
                                        final progress =
                                            durationState?.progress ??
                                                Duration.zero;
                                        var syncedLyrics =
                                            lyrics['syncedLyrics'];

                                        if (syncedLyrics == null) {
                                          if (lyrics.isEmpty ||
                                              lyrics['plainLyrics'] == null) {
                                            return const Center(
                                              child: Scrollbar(
                                                child: SingleChildScrollView(
                                                  child: Text(
                                                    "No lyrics found.",
                                                    style: TextStyle(
                                                      fontSize: 18,
                                                      // fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          } else {
                                            return Center(
                                              child: Scrollbar(
                                                child: SingleChildScrollView(
                                                  child: Text(
                                                    lyrics['plainLyrics'],
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      // fontWeight: FontWeight.bold,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          var lyricModel =
                                              LyricsModelBuilder.create()
                                                  .bindLyricToMain(utf8.decode(
                                                      lyrics['syncedLyrics']
                                                          .codeUnits))
                                                  .getModel();
                                          return LyricsReader(
                                            model: lyricModel,
                                            position:
                                                progress.inMilliseconds.toInt(),
                                            lyricUi: lyricUI,
                                            playing: false,
                                            emptyBuilder: () => const Center(
                                              child: Text(
                                                "No lyrics",
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                            ),
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
                            // For music streaming
                            if (loading)
                              const CircularProgressIndicator(
                                  color: Colors.white),
                            if (!loading)
                              playing
                                  ? IconButton(
                                      onPressed: pauseMusic,
                                      icon: const Icon(
                                        PhosphorIconsFill.pause,
                                        color: Colors.white,
                                      ),
                                    )
                                  : IconButton(
                                      onPressed: streamMusic,
                                      icon: const Icon(
                                        PhosphorIconsBold.play,
                                        color: Colors.white,
                                      ),
                                    ),

                            const SizedBox(width: 10),
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
                          ],
                        ),
                        //buttons end

                        const SizedBox(
                          height: 30,
                        ),

                        StreamBuilder<DurationState>(
                          stream: durationState,
                          builder: (context, snapshot) {
                            final durationState = snapshot.data;
                            final progress =
                                durationState?.progress ?? Duration.zero;
                            final buffered =
                                durationState?.buffered ?? Duration.zero;
                            final total = durationState?.total ?? Duration.zero;
                            return playing
                                ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: ProgressBar(
                                      progress: progress,
                                      buffered: buffered,
                                      total: total,
                                      onSeek: (value) {
                                        player.seek(value);
                                      },
                                      barHeight: 5,
                                      thumbRadius: 7,
                                      progressBarColor: Colors.white,
                                      thumbColor: Colors.white,
                                      bufferedBarColor: Colors.grey,
                                      baseBarColor: Colors.white24,
                                      thumbGlowRadius: 20,
                                      timeLabelTextStyle:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),

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
