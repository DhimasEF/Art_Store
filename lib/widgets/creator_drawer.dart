import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../pages/dashboard_creator.dart';
import '../pages/upload_konten_page.dart';
import '../pages/creator_transaksi_page.dart';
import '../pages/login_page.dart';

class CreatorDrawer extends StatelessWidget {
  final String username;
  final String? avatarUrl;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String currentMenu;

  const CreatorDrawer({
    Key? key,
    required this.currentMenu,
    required this.username,
    required this.avatarUrl,
    required this.selectedIndex,
    required this.onItemSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: avatarUrl != null
                      ? NetworkImage(avatarUrl!)
                      : AssetImage('assets/default.jpg') as ImageProvider,
                ),
                SizedBox(height: 10),
                Text(username, style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Creator'),
              ],
            ),
          ),
          _drawerItem(
            context: context,
            index: 0,
            selectedIndex: selectedIndex,
            icon: Icons.space_dashboard,
            title: "Dashboard",
            page: CreatorDashboardPage(),
            onItemSelected: onItemSelected,
          ),
          _drawerItem(
            context: context,
            index: 1,
            selectedIndex: selectedIndex,
            icon: Icons.library_add_check,
            title: "Upload Konten",
            page: UploadKontenPage(),
            onItemSelected: onItemSelected,
          ),
          _drawerItem(
            context: context,
            index: 2,
            selectedIndex: selectedIndex,
            icon: Icons.people,
            title: "Order Transaksi",
            page: CreatorTransaksiPage(), // param tidak perlu, tiap page load sendiri
            onItemSelected: onItemSelected,
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text("Logout", style: TextStyle(color: Colors.red)),
            onTap: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => LoginPage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required BuildContext context,
    required int index,
    required int selectedIndex,
    required IconData icon,
    required String title,
    required Widget page,
    required Function(int) onItemSelected,
  }) {
    bool active = selectedIndex == index;
    return Container(
      color: active ? Colors.blue.withOpacity(0.15) : Colors.transparent,
      child: ListTile(
        leading: Icon(icon, color: active ? Colors.blue : Colors.grey[700]),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? Colors.blue : Colors.black87,
          ),
        ),
        onTap: () {
          onItemSelected(index);
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => page));
        },
      ),
    );
  }
}
