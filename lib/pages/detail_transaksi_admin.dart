import 'package:flutter/material.dart';
import '../widgets/admin_drawer.dart';
import '../widgets/admin_appbar.dart';
import '../widgets/profile_panel.dart';
import 'edit_profil_page.dart';
import 'login_page.dart';
import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

  String formatRupiah(dynamic value) {
      if (value == null) return "0";

      // ubah ke string, buang semua selain angka
      final cleaned = value.toString().replaceAll(RegExp(r'[^0-9]'), '');

      return cleaned;
    }

class DetailTransaksiAdminPage extends StatefulWidget {
  final Map<String, dynamic> order; // ← menerima data Order langsung
  final String? username;
  final String? avatarUrl;
  final Map<String, dynamic>? data;
  final Future<void> Function()? reloadData;
  //final Future<void> Function(int)? uploadAvatarWeb;
  // final Future<void> Function(int) uploadAvatarMobile;
  final int idOrder;

  const DetailTransaksiAdminPage({
    super.key,
    required this.order,
    this.username,
    this.avatarUrl,
    this.data,
    this.reloadData,
    //this.uploadAvatarWeb,
    // required this.uploadAvatarMobile,
    required this.idOrder,
  });

  @override
  _DetailTransaksiAdminPageState createState() =>
      _DetailTransaksiAdminPageState();
}

class _DetailTransaksiAdminPageState
    extends State<DetailTransaksiAdminPage> {
    String username = '';
    String email = '';
    String role = '';
    String? avatarUrl;
    Map<String, dynamic>? data;

    int selectedIndex = 2;

    @override
    void initState() {
      super.initState();
      loadUserData();
    }

    void showPaymentProofModal(
      BuildContext context, {
      required String imageUrl,
      required int idOrder,
      required bool isProcessed,
    }) {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: "payment-proof",
        barrierColor: Colors.black.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) {
          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Stack(
                  children: [
                    // ❌ CLOSE ICON
                    Positioned(
                      right: 0,
                      top: 0,
                      child: InkWell(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.close, size: 24),
                      ),
                    ),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 10),
                        const Text(
                          "Bukti Pembayaran",
                          style:
                              TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // IMAGE
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  height: 230,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    height: 230,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.broken_image, size: 60),
                                  ),
                                )
                              : Container(
                                  height: 230,
                                  alignment: Alignment.center,
                                  color: Colors.grey.shade100,
                                  child: const Text(
                                    "Bukti pembayaran belum tersedia",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                        ),

                        const SizedBox(height: 20),

                        // BUTTON
                        if (!isProcessed && imageUrl.isNotEmpty)
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    minimumSize: const Size(0, 45),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await handleRejectPayment(idOrder);
                                  },
                                  child: const Text("Tolak"),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    minimumSize: const Size(0, 45),
                                  ),
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await handleAcceptPayment(idOrder);
                                  },
                                  child: const Text("ACC"),
                                ),
                              ),
                            ],
                          )
                        else
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Tutup"),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        transitionBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: ScaleTransition(
              scale: Tween(begin: 0.9, end: 1.0).animate(anim),
              child: child,
            ),
          );
        },
      );
    }


    Future<void> handleAcceptPayment(int idOrder) async {
    final res = await ApiService.acceptPayment(idOrder);

    if (res['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran di-ACC")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Gagal ACC")),
      );
    }
  }

  Future<void> handleRejectPayment(int idOrder) async {
    final res = await ApiService.rejectPayment(idOrder);

    if (res['status'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pembayaran ditolak")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? "Gagal menolak")),
      );
    }
  }

  // ======================================================
  // LOAD USER DATA
  // ======================================================
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

    if (result['status'] == true) {
      final d = result['data'];

      setState(() {
        data = d;
        username = d['username'] ?? '';
        email = d['email'] ?? '';
        avatarUrl = (d['avatar'] != null && d['avatar'] != "")
            ? ApiService.avatarBaseUrl + d['avatar']
            : null;
      });
    }
  }

  // ======================================================
  // UI
  // ======================================================
  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final items = order["items"] as List;

    final totalPrice = items.fold(0, (sum, item) {
      final p = item["price"];

      // Kalau null → jadikan 0
      if (p == null) return sum;

      // Konversi ke string untuk dibersihkan
      final s = p.toString().replaceAll(RegExp(r'[^0-9]'), '');

      // coba parse → kalau gagal jadi 0
      final value = int.tryParse(s) ?? 0;

      return sum + value;
    });

    final note = widget.order['note'];
    final paymentStatus = widget.order['payment_status']; 
    // contoh: pending | paid | rejected

    final isPaymentUploaded =
        note != null && note.toString().isNotEmpty;

    final isTransactionClear =
        paymentStatus == 'paid' || paymentStatus == 'rejected';
    
    return Scaffold(
      appBar: AdminAppBar(
        title: "Detail Transaksi",
        username: username,
        avatarUrl: avatarUrl,
        onProfileTap: () => showProfilePanel(
          context,
          avatarUrl: avatarUrl,
          data: data ?? {},
          reloadData: loadUserData,
          //uploadAvatarWeb: widget.uploadAvatarWeb,
          // uploadAvatarMobile: widget.uploadAvatarMobile,
          editPageBuilder: (d) => EditProfilePage(userData: d),
        ),
      ),
      drawer: AdminDrawer(
        currentMenu: 'transaksi',
        username: username,
        avatarUrl: avatarUrl,
        selectedIndex: selectedIndex,
        onItemSelected: (i) => setState(() => selectedIndex = i),
      ),

      // ======================================================
      // BODY DETAIL ORDER
      // ======================================================
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 10), // ← JARAK DI SINI
                Expanded(
                  child: Text(
                    "Order #${order['id_order']}",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 6),
            Text(
              "Tanggal: ${order['created_at']}",
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            SizedBox(height: 6),

            Container(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                order["order_status"].toString().toUpperCase(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.black87,
                ),
              ),
            ),

            SizedBox(height: 20),

            // ===========================
            // PAYMENT INFORMATION
            // ===========================
            Text(
              "Status Pembayaran:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 6),

            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey.shade100,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    paymentStatus == "waiting"
                        ? "MENUNGGU KONFIRMASI"
                        : paymentStatus.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: paymentStatus == "paid"
                          ? Colors.green
                          : paymentStatus == "waiting"
                              ? Colors.orange
                              : Colors.redAccent,
                    ),
                  ),
                  Text(
                    "Rp ${order["total_paid"] ?? 0}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),
            Divider(),

            // -------------------------
            // LIST ITEM
            // -------------------------
            Text(
              "Item dalam Order",
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),

            ...items.map((art) {
              final img = art['images'].isNotEmpty
                  ? ApiService.baseUrlimage + "/uploads/artworks/preview/" + art['images'][0]
                  : null;

              return Container(
                padding: EdgeInsets.all(14),
                margin: EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: img != null
                          ? Image.network(img,
                              width: 70, height: 70, fit: BoxFit.cover)
                          : Container(
                              width: 70,
                              height: 70,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.image_not_supported),
                            ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            art["title"],
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 15),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Rp ${formatRupiah(art["price"])}",
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),

            Divider(height: 28),

            // -------------------------
            // TOTAL HARGA
            // -------------------------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Total Harga",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  "Rp ${formatRupiah(totalPrice)}",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent),
                ),
              ],
            ),

            SizedBox(height: 20),

            // -------------------------
            // ACTION BUTTON
            // -------------------------

            // 🔹 LIHAT BUKTI (hanya kalau bukti ada)
            if (isPaymentUploaded)
              ElevatedButton(
                onPressed: () {
                  showPaymentProofModal(
                    context,
                    imageUrl:
                        ApiService.baseUrlimage + "/uploads/payment/" + note,
                    idOrder: widget.idOrder,
                    isProcessed: isTransactionClear,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isTransactionClear
                      ? "Lihat Bukti Pembayaran"
                      : "Review Bukti Pembayaran",
                  style: const TextStyle(fontSize: 16),
                ),
              ),

            if (isPaymentUploaded) const SizedBox(height: 14),

            // 🔹 BATALKAN ORDER (HILANG kalau transaksi sudah clear)
            if (!isTransactionClear)
              ElevatedButton(
                onPressed: () {
                  // TODO: show confirm dialog cancel order
                  showDialog(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text("Batalkan Order?"),
                      content: Text("Order yang dibatalkan tidak dapat dikembalikan."),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text("Batal"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            // call API cancel order
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          child: Text("Ya, Batalkan"),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  "Batalkan Order",
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
