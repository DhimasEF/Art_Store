import 'package:flutter/material.dart';
import '../widgets/creator_drawer.dart';
import '../widgets/creator_appbar.dart';

class KontenDetailPage extends StatelessWidget {
  final Map<String, dynamic> konten;
  final String username;
  final String? avatarUrl;
  final int selectedIndex;
  final String currentMenu;

  const KontenDetailPage({
    super.key,
    required this.konten,
    required this.username,
    required this.avatarUrl,
    required this.selectedIndex,
    required this.currentMenu,
  });

  @override
  Widget build(BuildContext context) {
    List<dynamic> images = [];

    if (konten["images"] is List) {
      images = konten["images"]
          .map((e) => "http://192.168.6.15/project_api/uploads/artworks/${e['image_url']}")
          .toList();
    }

    return Scaffold(
      drawer: CreatorDrawer(
        currentMenu: currentMenu,
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (_) {},
      ),

      appBar: CreatorAppBar(
        title: "Detail Konten",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () {},
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // JUDUL
            Text(
              konten['title'] ?? "Untitled Content",
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            // DESKRIPSI
            Text(
              konten['description'] ?? "-",
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),

            const SizedBox(height: 20),

            // GRID GAMBAR
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
