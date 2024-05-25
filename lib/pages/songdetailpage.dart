import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
// import 'package:background_downloader/background_downloader.dart';

import 'package:background_downloader/background_downloader.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/return_code.dart';
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
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

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

  static Future<String> getExternalDocumentPath() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      await Permission.storage.request();
    }
    Directory directory = Directory("dir");
    if (Platform.isAndroid) {
      directory = Directory("/storage/emulated/0/Download/TuneLoad");
    } else {
      directory = await getApplicationDocumentsDirectory();
    }

    final exPath = directory.path;
    print("Saved Path: $exPath");
    await Directory(exPath).create(recursive: true);
    return exPath;
  }

  static Future<String> get _localPath async {
    final String directory = await getExternalDocumentPath();
    return directory;
  }

  void attachMetadata(String inputFile) async {
    DateTime dateTime = DateTime.parse(widget.item['album']['release_date']);
    String year = DateFormat('yyyy').format(dateTime);

    var imageUrl = widget.item['album']['images'][0]['url'];
    var imageBytes = await downloadImage(imageUrl);

    // var inputFile = "/storage/emulated/0/Download/TuneLoad/finaltry.webm";
    String filePath = await _localPath;
    var outputFile = "$filePath/finalrender.mp3";

    await FFmpegKit.execute(
            '-i $inputFile -vn -c:a libmp3lame -ar 44100 -ac 2 -b:a 192k $outputFile')
        .then((session) async {
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        print("Ffmpeg process completed with rc $returnCode");
        await File(inputFile).delete();

        await MetadataGod.writeMetadata(
          file: outputFile,
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
          ),
        );
        await File(outputFile).rename("$filePath/${widget.item['name']}.mp3");
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
      String fileName = widget.item['id'];
      String filePath = await _localPath;
      File file = File(filePath);
      print('File is : $file');
      print('file path is : $filePath');

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
      final task = DownloadTask(
        url:
            // "https://rr5---sn-qi4pcxgoxu-3uhe.googlevideo.com/videoplayback?expire=1716620230&ei=ZjdRZur0GanljuMP_eqJ-Aw&ip=2405%3Aacc0%3A1306%3A39d9%3A8490%3Ab33%3Ac981%3Aa868&id=o-AM0hHFts1E6aL2rh2SLmux70238cy_x2C9J-fm8uo0rx&itag=251&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&mh=Bw&mm=31%2C29&mn=sn-qi4pcxgoxu-3uhe%2Csn-h557sns7&ms=au%2Crdu&mv=m&mvi=5&pl=52&gcr=np&initcwndbps=883750&bui=AWRWj2QJtVEuUV35qpyDaHHjVodOb3acQc-I97t-JAyHWj22KUK_i6O97CMKBJLrZl3CUlWMdxwN0Jv5&spc=UWF9fzRqSzOhh8gXeGkxqmai3Z-xxOvYRYZEHcdjNeBq4esbCSNCTm8znMzy&vprv=1&svpuc=1&mime=audio%2Fwebm&ns=Oa7ODbie-J2vs2_juCf2aokQ&rqh=1&gir=yes&clen=4534399&dur=261.121&lmt=1714591386939203&mt=1716598365&fvip=3&keepalive=yes&c=WEB&sefc=1&txp=2318224&n=xHu-1A_OwPXnNg&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cxpc%2Cgcr%2Cbui%2Cspc%2Cvprv%2Csvpuc%2Cmime%2Cns%2Crqh%2Cgir%2Cclen%2Cdur%2Clmt&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHWaYeowRQIhAJPucL751RtsO8SW2mRFa82PxbOeOeBLmKfT8_nC2-AEAiAeXQh8ZusbaKw8b6kYtUlg1sE6bh1pSREtNxZn8woVew%3D%3D&sig=AJfQdSswRgIhAMrIA3SQG0yDdN-j2etgyoyY-xlZ0AKSzYLhWhALO1g3AiEA6qqocyc7TLju60N66bGkS6ArsgCQDuW4cgi6CXk9kpM%3D",
            "https://rr1---sn-qi4pcxgoxu-3uhe.googlevideo.com/videoplayback?expire=1716625813&ei=NU1RZob0D-KOjuMPi6O1-A0&ip=2405%3Aacc0%3A1306%3A39d9%3A8490%3Ab33%3Ac981%3Aa868&id=o-AF0LJrc_IqeMGBqBqwhO8laa3l78WIEMIKwce7GnPqdy&itag=251&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&mh=Bs&mm=31%2C29&mn=sn-qi4pcxgoxu-3uhe%2Csn-h5576n7r&ms=au%2Crdu&mv=m&mvi=1&pl=52&gcr=np&initcwndbps=1058750&bui=AWRWj2QvcKAcEueA_pYYd_0CStFzlpq49m4X-TU_H_5xVFD9yS2S7N0oDhZtao7yXUe1ke6ZKVIwABif&spc=UWF9f_iZgh9NzNRwXxyKnEWpEUZLK9aRr7xRBDY6QPUApSOrVPP06clJGTGo&vprv=1&svpuc=1&mime=audio%2Fwebm&ns=HzWKYnyhwzO4oGPNMdWc49oQ&rqh=1&gir=yes&clen=3132573&dur=169.861&lmt=1714866357452919&mt=1716603898&fvip=4&keepalive=yes&c=WEB&sefc=1&txp=2318224&n=sbZ7EN6yu339lA&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cxpc%2Cgcr%2Cbui%2Cspc%2Cvprv%2Csvpuc%2Cmime%2Cns%2Crqh%2Cgir%2Cclen%2Cdur%2Clmt&lsparams=mh%2Cmm%2Cmn%2Cms%2Cmv%2Cmvi%2Cpl%2Cinitcwndbps&lsig=AHWaYeowRQIhANsujF6eKu4Upu5nNzq5uXS0ylUxWYj0tHjZntCrtICfAiB3xDgK7aNEUtC0hl-aAyrqttBj8w3rIFxbq4gcteODMA%3D%3D&sig=AJfQdSswRAIgBOYA4w_cQTHWukOLqI98MCyHjwfiEO6rEu-RAZC9EWICIHctQ1-nVnPi0Nj-D6y_EBbA4s8fu28DeQVWXglrxn6n",
        filename: "$fileName.webm",
        displayName: widget.item['name'],
        directory: filePath,
        updates:
            Updates.statusAndProgress, // request status and progress updates
        requiresWiFi: true,
        // retries: 5,
        allowPause: true,
      );

      final result = await FileDownloader().download(task,
          onProgress: (progress) => print('Progress: ${progress * 100}%'),
          onStatus: (status) => print('Status: $status'));

      switch (result.status) {
        case TaskStatus.complete:
        case TaskStatus.canceled:
          print('Download was canceled');

        case TaskStatus.paused:
          print('Download was paused');

        default:
          print('Download not successful');
      }

      final ddpath = await FileDownloader()
          .moveToSharedStorage(task, SharedStorage.downloads,
              directory: "TuneLoad")
          .then(
        (value) async {
          print(value);
          print("Moved successufllly");

          attachMetadata(value!);
        },
      );
      // try {
      //   if (ddpath != null) {
      //     await File(ddpath).rename('$filePath.webm');
      //   }
      // } catch (e) {}

      debugPrint(
          'Android path to dog picture in .images = ${ddpath ?? "permission denied"}');
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    generateColors();

    // Registering a callback and configure notifications
    FileDownloader().configureNotification(
      // for the 'Download & Open' dog picture
      // which uses 'download' which is not the .defaultGroup
      // but the .await group so won't use the above config
      running:
          const TaskNotification('Downloading', 'file: {filename} {progress}'),
      complete:
          const TaskNotification('Download {filename}', 'Download complete'),
      error: const TaskNotification('Error', '{numFailed}/{numTotal} failed'),
      progressBar: true,
    ); // dog can also open directly from tap
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
