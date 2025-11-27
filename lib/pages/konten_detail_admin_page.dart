import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_appbar.dart';

import '../widgets/profile_panel.dart';
import 'login_page.dart';
import 'edit_profil_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class KontenDetailPage extends StatefulWidget {
  final Map<String, dynamic> konten;
  final String currentMenu;
  final int selectedIndex;
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  final Future<void> Function(int)? uploadAvatarWeb;

  const KontenDetailPage({
    Key? key,
    required this.konten,
    required this.currentMenu,
    required this.selectedIndex,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    this.uploadAvatarWeb,
  }) : super(key: key);

  @override
  State<KontenDetailPage> createState() => _KontenDetailPage();
}

class _KontenDetailPage extends State<KontenDetailPage> {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic>? data;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;
    role = prefs.getString('role') ?? '';

    if (role != 'admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);
    if (!mounted) return;

    if (result['status'] == true && result['data'] != null) {
      final fetchedData = result['data'] as Map<String, dynamic>;
      setState(() {
        data = fetchedData;
        username = fetchedData['username'] ?? '';
        avatarUrl = fetchedData['avatar'];
        email = fetchedData['email'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final konten = widget.konten;

    List<dynamic> images = [];
    if (konten["images"] is List) {
      images = konten["images"]
          .map((e) =>
              "http://192.168.6.15/project_api/uploads/artworks/${e['image_url']}")
          .toList();
    }

    return Scaffold(
      drawer: AdminDrawer(
        currentMenu: widget.currentMenu,
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: widget.selectedIndex,
        onItemSelected: (_) {},
      ),

      appBar: AdminAppBar(
        title: "Detail Konten",
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

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// TITLE
            Text(
              konten['title'] ?? "Untitled Content",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            /// DESCRIPTION
            Text(
              konten['description'] ?? "-",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            /// IMAGES GRID
            Expanded(
              child: GridView.builder(
                padding: EdgeInsets.zero,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: images.length,
                itemBuilder: (context, index) {
                  final img = images[index];

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            img,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        Positioned(
                          left: 8,
                          bottom: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              "Image ${index + 1}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
