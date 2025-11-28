import 'package:flutter/material.dart';
import '../widgets/user_drawer.dart';
import '../widgets/user_appbar.dart';
import '../widgets/profile_panel.dart';
import 'login_page.dart';
import 'edit_profil_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // pastikan path sesuai

class OrderTransaksiPage extends StatefulWidget {
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  final Future<void> Function(int)? uploadAvatarWeb;

  const OrderTransaksiPage({
    super.key,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    this.uploadAvatarWeb,
  });

  @override
  _OrderTransaksiPageState createState() => _OrderTransaksiPageState();
}

class _OrderTransaksiPageState extends State<OrderTransaksiPage> {
  String username = '';
  String email = '';
  String role = '';
  String? avatarUrl;
  Map<String, dynamic>? data;

  int selectedIndex = 2;  // posisi menu (Kelola Transaksi)

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

    if (role != 'user') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginPage()),
      );
      return;
    }

    // Ambil data lengkap dari API
    final result = await ApiService.getDashboardData(token, userId: userId);
    if (!mounted) return;

    if (result['status'] == true && result['data'] != null) {
      final fetchedData = result['data'] as Map<String, dynamic>; // <-- aman
      setState(() {
        data = fetchedData;                         // <-- pastikan data bukan null
        username = fetchedData['username'] ?? '';
        avatarUrl = (fetchedData['avatar'] != null && fetchedData['avatar'] != "")
          ? ApiService.avatarBaseUrl + fetchedData['avatar']
          : null;
        email = fetchedData['email'] ?? '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UserAppBar(
        title: "Order Transaksi",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () => showProfilePanel(
          context,
          avatarUrl: avatarUrl,
          data: data ?? {},                  // <-- kasih default kosong supaya aman
          reloadData: loadUserData,          // <-- pakai function dari state
          uploadAvatarWeb: widget.uploadAvatarWeb, // <-- ambil dari widget
          editPageBuilder: (d) => EditProfilePage(userData: d),
        ),
      ),
      drawer: UserDrawer(
        currentMenu: 'transaksi',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) {
          setState(() => selectedIndex = i);
        },
      ),
      body: Center(
        child: Text("Halaman order Transaksi"),
      ),
    );
  }
}
