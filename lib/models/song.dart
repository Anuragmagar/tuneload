class Song {
  Tracks tracks;

  Song({
    required this.tracks,
  });
}

class Tracks {
  String href;
  List<Item> items;
  int limit;
  String next;
  int offset;
  dynamic previous;
  int total;

  Tracks({
    required this.href,
    required this.items,
    required this.limit,
    required this.next,
    required this.offset,
    required this.previous,
    required this.total,
  });
}

class Item {
  Album album;
  List<Artist> artists;
  List<String> availableMarkets;
  int discNumber;
  int durationMs;
  bool explicit;
  ExternalIds externalIds;
  ExternalUrls externalUrls;
  String href;
  String id;
  bool isLocal;
  String name;
  int popularity;
  String? previewUrl;
  int trackNumber;
  ItemType type;
  String uri;

  Item({
    required this.album,
    required this.artists,
    required this.availableMarkets,
    required this.discNumber,
    required this.durationMs,
    required this.explicit,
    required this.externalIds,
    required this.externalUrls,
    required this.href,
    required this.id,
    required this.isLocal,
    required this.name,
    required this.popularity,
    required this.previewUrl,
    required this.trackNumber,
    required this.type,
    required this.uri,
  });
}

class Album {
  AlbumTypeEnum albumType;
  List<Artist> artists;
  List<String> availableMarkets;
  ExternalUrls externalUrls;
  String href;
  String id;
  List<Image> images;
  String name;
  DateTime releaseDate;
  ReleaseDatePrecision releaseDatePrecision;
  int totalTracks;
  AlbumTypeEnum type;
  String uri;

  Album({
    required this.albumType,
    required this.artists,
    required this.availableMarkets,
    required this.externalUrls,
    required this.href,
    required this.id,
    required this.images,
    required this.name,
    required this.releaseDate,
    required this.releaseDatePrecision,
    required this.totalTracks,
    required this.type,
    required this.uri,
  });
}

enum AlbumTypeEnum { ALBUM, COMPILATION, SINGLE }

class Artist {
  ExternalUrls externalUrls;
  String href;
  Id id;
  Name name;
  ArtistType type;
  Uri uri;

  Artist({
    required this.externalUrls,
    required this.href,
    required this.id,
    required this.name,
    required this.type,
    required this.uri,
  });
}

class ExternalUrls {
  String spotify;

  ExternalUrls({
    required this.spotify,
  });
}

enum Id {
  THE_00_F_QB4_J_TYEND_Y_WA_N8_P_K0_WA,
  THE_0_LYF_QWJT6_N_XAF_LP_ZQXE9_OF,
  THE_371_JPY_GDO_CHZ_UASOIG2_ECV,
  THE_3_F_QDI_MP_AN_RV_V_VD_VR_XS_BB_YW,
  THE_53_JND1_FH_XV7_LB_X_SFJGK1_WR
}

enum Name {
  ASHLEY_MC_BRYDE,
  LANA_DEL_REY,
  LANA_LUBANY,
  RADIO_LUNA,
  VARIOUS_ARTISTS
}

enum ArtistType { ARTIST }

enum Uri {
  SPOTIFY_ARTIST_00_F_QB4_J_TYEND_Y_WA_N8_P_K0_WA,
  SPOTIFY_ARTIST_0_LYF_QWJT6_N_XAF_LP_ZQXE9_OF,
  SPOTIFY_ARTIST_371_JPY_GDO_CHZ_UASOIG2_ECV,
  SPOTIFY_ARTIST_3_F_QDI_MP_AN_RV_V_VD_VR_XS_BB_YW,
  SPOTIFY_ARTIST_53_JND1_FH_XV7_LB_X_SFJGK1_WR
}

class Image {
  int height;
  String url;
  int width;

  Image({
    required this.height,
    required this.url,
    required this.width,
  });
}

enum ReleaseDatePrecision { DAY }

class ExternalIds {
  String isrc;

  ExternalIds({
    required this.isrc,
  });
}

enum ItemType { TRACK }
