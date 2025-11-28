import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/profile_panel.dart';
import 'login_page.dart';
import 'edit_profil_page.dart';
import 'konten_detail_admin_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class KelolaKontenPage extends StatefulWidget {
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  final Future<void> Function(int)? uploadAvatarWeb;

  const KelolaKontenPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    this.uploadAvatarWeb,
  });

  @override
  _KelolaKontenPageState createState() => _KelolaKontenPageState();
}

class _KelolaKontenPageState extends State<KelolaKontenPage> {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic>? data;

  int selectedIndex = 1;

  List<dynamic> draftList = [];
  bool isLoadingDraft = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
    loadDraftContents();
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
        avatarUrl = (fetchedData['avatar'] != null && fetchedData['avatar'] != "")
          ? ApiService.avatarBaseUrl + fetchedData['avatar']
          : null;
        email = fetchedData['email'] ?? '';
      });
    }
  }

  Future<void> loadDraftContents() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';

    setState(() => isLoadingDraft = true);

    final drafts = await ApiService.getDraftContents();

    setState(() {
      draftList = drafts;
      isLoadingDraft = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AdminAppBar(
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

      drawer: AdminDrawer(
        currentMenu: 'konten',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) {
          setState(() => selectedIndex = i);
        },
      ),

      body: isLoadingDraft
          ? const Center(child: CircularProgressIndicator())
          : draftList.isEmpty
              ? const Center(child: Text("Tidak ada konten draft."))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: draftList.length,
                  itemBuilder: (context, index) {
                    final item = draftList[index];

                    final title = item["title"] ?? "-";
                    final user = item["username"] ?? "-";

                    final images = item["images"] ?? [];
                    String? thumb;

                    if (images.isNotEmpty && images[0] is Map) {
                      thumb = images[0]["image_url"];
                    }

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: thumb != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  "http://192.168.6.16/flutterapi_app/uploads/artworks/$thumb",
                                  width: 70,
                                  height: 70,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Container(
                                width: 70,
                                height: 70,
                                color: Colors.grey.shade300,
                                child: const Icon(Icons.image_not_supported),
                              ),

                        title: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        subtitle: Text("By: $user"),
                        trailing:
                            const Icon(Icons.arrow_forward_ios, size: 16),

                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => KontenDetailPage(
                                konten: item,
                                username: username,
                                avatarUrl: avatarUrl,
                                selectedIndex: 1,
                                currentMenu: "konten",
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
