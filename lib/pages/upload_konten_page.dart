import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/creator_drawer.dart';
import '../widgets/creator_appbar.dart';
import '../widgets/profile_panel.dart';
import '../widgets/upload_bottom_sheet.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import 'konten_detail_page.dart';


// ============================================================
//  IMAGE SLIDESHOW (FADE ANIMATION)
// ============================================================
class ImageSlideshow extends StatefulWidget {
  final List<String> images;

  const ImageSlideshow({required this.images});

  @override
  _ImageSlideshowState createState() => _ImageSlideshowState();
}

class _ImageSlideshowState extends State<ImageSlideshow> {
  int index = 0;

  @override
  void initState() {
    super.initState();

    if (widget.images.length > 1) {
      Future.doWhile(() async {
        await Future.delayed(const Duration(seconds: 3));

        if (!mounted) return false;

        setState(() => index = (index + 1) % widget.images.length);
        return true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      child: Image.network(
        widget.images[index],
        fit: BoxFit.cover,
        key: ValueKey(index),
        errorBuilder: (_, __, ___) => Container(
          color: Colors.grey.shade300,
        ),
      ),
    );
  }
}



// ============================================================
//  MAIN PAGE
// ============================================================
class UploadKontenPage extends StatefulWidget {
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  final Future<void> Function(int)? uploadAvatarWeb;

  const UploadKontenPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    this.uploadAvatarWeb,
  });

  @override
  State<UploadKontenPage> createState() => _UploadKontenPageState();
}


// ============================================================
//  STATE
// ============================================================
class _UploadKontenPageState extends State<UploadKontenPage> {
  String username = "";
  String email = "";
  String role = "";
  String? avatarUrl;
  Map<String, dynamic>? data;

  int selectedIndex = 1;

  List<dynamic> allContent = [];
  List<dynamic> myContent = [];
  bool loading = true;

  String filter = "all";


  // ------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    loadUserData();
    loadContent();
  }


  // ------------------------------------------------------------
  Future<void> loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (!mounted) return;

    if (role != 'creator') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);

    if (!mounted) return;

    if (result['status'] == true) {
      final d = result['data'] ?? {};
      setState(() {
        username = d['username'] ?? '';
        avatarUrl = d['avatar'];
        email = d['email'] ?? '';
        data = Map<String, dynamic>.from(d);
      });
    }
  }


  // ------------------------------------------------------------
  Future<void> loadContent() async {
    if (!mounted) return;
    setState(() => loading = true);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('id_user') ?? 0;

    try {
      final listAll = await ApiService.getAllArtwork();
      final listMine = await ApiService.getMyArtwork(userId);

      if (!mounted) return;

      setState(() {
        allContent = (listAll is List) ? listAll : [];
        myContent = (listMine is List) ? listMine : [];
        loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        loading = false;
      });
    }
  }


  // ------------------------------------------------------------
  void openUploadModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return UploadBottomSheet(
          onUploaded: () => loadContent(),
        );
      },
    );
  }



  // ============================================================
  //  CONTENT ITEM CARD — WITH DETAIL BUTTON
  // ============================================================
  Widget buildContentItem(Map item) {
    List<String> images = [];

    if (item["images"] != null && item["images"] is List) {
      images = (item["images"] as List)
          .map((e) =>
              "http://192.168.6.15/project_api/uploads/artworks/${e['image_url']}")
          .toList();
    }

    double elevation = 4;

    return StatefulBuilder(
      builder: (context, setHover) {
        return MouseRegion(
          onEnter: (_) => setHover(() => elevation = 12),
          onExit: (_) => setHover(() => elevation = 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.2),
                  blurRadius: elevation,
                  spreadRadius: elevation / 6,
                )
              ],
            ),
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => KontenDetailPage(
                      konten: Map<String, dynamic>.from(item),   // FIX UTAMA
                      username: username,
                      selectedIndex: 1,
                      currentMenu: "Upload Konten",
                      avatarUrl: avatarUrl,
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Column(
                  children: [
                    // -------------------------------------------
                    // GAMBAR + OVERLAY + TEXT
                    // -------------------------------------------
                    SizedBox(
                      height: 210,
                      width: double.infinity,
                      child: Stack(
                        children: [
                          images.isNotEmpty
                              ? ImageSlideshow(images: images)
                              : Container(color: Colors.grey.shade300),

                          Container(
                            color: Colors.black.withOpacity(0.35),
                          ),

                          Positioned(
                            left: 14,
                            bottom: 14,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["title"] ?? "(tanpa judul)",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  "${images.length} images",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.open_in_new,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          )
                        ],
                      ),
                    ),

                    // -------------------------------------------
                    // INFO BAWAH
                    // -------------------------------------------
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item['status'] ?? "-"),
                          Text(
                            item['created_at']?.toString() ?? "",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }



  // ============================================================
  //  LIST VIEW
  // ============================================================
  Widget buildContentList() {
    final list = filter == "mine" ? myContent : allContent;

    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (list.isEmpty) {
      return const Center(child: Text("Belum ada konten"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (_, i) => buildContentItem(list[i]),
    );
  }



  // ============================================================
  //  PAGE BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CreatorAppBar(
        title: "Kelola Konten",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () => showProfilePanel(
          context,
          avatarUrl: avatarUrl,
          data: data ?? {},
          reloadData: loadUserData,
          uploadAvatarWeb: widget.uploadAvatarWeb,
          editPageBuilder: (d) => EditProfilePage(userData: d),
        ),
      ),

      drawer: CreatorDrawer(
        currentMenu: 'konten',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) => setState(() => selectedIndex = i),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: openUploadModal,
        child: const Icon(Icons.add),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                FilterChip(
                  label: const Text("Semua Konten"),
                  selected: filter == "all",
                  onSelected: (_) => setState(() => filter = "all"),
                ),
                FilterChip(
                  label: const Text("Konten Saya"),
                  selected: filter == "mine",
                  onSelected: (_) => setState(() => filter = "mine"),
                ),
              ],
            ),
          ),
          Expanded(child: buildContentList()),
        ],
      ),
    );
  }
}
