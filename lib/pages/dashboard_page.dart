import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';
import 'dart:io';
import 'dart:html' as html;
import 'dart:convert';
import 'package:http/http.dart' as http;


class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String username = '';
  String email = '';
  String? avatarUrl;
  Map<String, dynamic> data = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String token = prefs.getString('token') ?? '';
    int userId = prefs.getInt('id_user') ?? 0;

    if (token.isEmpty || userId == 0) {
      print("⚠️ Token atau userId kosong");
      return;
    }

    final result = await ApiService.getDashboardData(token, userId: userId);

    if (result['status'] == true && result['data'] != null) {
      setState(() {
        data = result['data'];
        username = data['username'] ?? '';
        email = data['email'] ?? '';
        isLoading = false;
      });

      // Simpan ulang data terbaru
      await prefs.setString('username', username);
      await prefs.setString('email', email);
    } else {
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: loadUserData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header selamat datang
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage("${avatarUrl}?v=${DateTime.now().millisecondsSinceEpoch}")
                                    : (data['avatar'] != null
                                        ? NetworkImage("${data['avatar']}?v=${DateTime.now().millisecondsSinceEpoch}")
                                        : AssetImage('assets/default.jpg') as ImageProvider),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () async {
                                    SharedPreferences prefs = await SharedPreferences.getInstance();
                                    int userId = prefs.getInt('id_user') ?? 0;
                                    uploadAvatarWeb(userId); // ⬅️ panggil fungsi upload
                                  },
                                ),
                              ),
                            ],
                          ),

                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome, ${data['name'] ?? username} 👋',
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                              ),
                              Text(email, style: TextStyle(color: Colors.grey[700])),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 24),

                      // Card data user
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Profil Anda',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  IconButton(
                                    icon: Icon(Icons.edit, color: Colors.blue),
                                    onPressed: () async {
                                      final updated = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => EditProfilePage(
                                            userData: data,
                                          ),
                                        ),
                                      );
                                      if (updated == true) loadUserData();
                                    },
                                  ),
                                ],
                              ),
                              Divider(),
                              infoRow('User ID', data['id_user']),
                              infoRow('Username', data['username']),
                              infoRow('Email', data['email']),
                              infoRow('Nama', data['name']),
                              infoRow('Role', data['role']),
                              infoRow('Bio', data['bio']),
                              infoRow('Terakhir Login', data['last_login']),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 40),

                      // Tombol logout
                      Center(
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.logout),
                          label: Text('Logout'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            padding: EdgeInsets.symmetric(
                                horizontal: 40, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            SharedPreferences prefs =
                                await SharedPreferences.getInstance();
                            await prefs.clear();
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LoginPage(),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          Expanded(
            child: Text(
              value != null && value.toString().isNotEmpty
                  ? value.toString()
                  : '-',
              textAlign: TextAlign.right,
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }
  
  // ⬇️ Tambahkan di bawah sini!
  Future<void> uploadAvatarWeb(int userId) async {
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.click();

    await input.onChange.first;

    if (input.files!.isEmpty) return;

    final file = input.files!.first;
    final reader = html.FileReader();
    reader.readAsDataUrl(file);

    await reader.onLoad.first;

    final base64Image = reader.result as String;

    // 🔹 Panggil API backend
    final response = await http.post(
      Uri.parse('http://192.168.6.15/project_api/profil/upload_avatar_web'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id_user': userId,
        'avatar_base64': base64Image,
      }),
    );

    if (response.statusCode == 200) {
      final resData = jsonDecode(response.body);
      if (resData['status'] == true) {
        setState(() {
          avatarUrl = resData['avatar'];
          data['avatar'] = resData['avatar']; // ✅ update data state
        });

        print('Avatar berhasil diperbarui!');
        await loadUserData(); // ✅ refresh data dashboard dari server
      } else {
        print('Gagal upload avatar: ${resData['message']}');
      }
    } else {
      print('Error server: ${response.statusCode}');
    }
  }
}

