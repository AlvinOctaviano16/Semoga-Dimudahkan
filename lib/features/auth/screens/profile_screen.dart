import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/auth_controller.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Controller untuk input field
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  bool _isInit = true;
  bool _obscureOld = true;
  bool _obscureNew = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _oldPassController.dispose();
    _newPassController.dispose();
    super.dispose();
  }

  // Fungsi untuk mengisi data awal ke controller
  void _initializeData(Map<String, dynamic> data) {
    if (_isInit) {
      _nameController.text = data['name'] ?? '';
      _emailController.text = data['email'] ?? '';
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(userProfileProvider);
    final isLoading = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Edit Profile", style: TextStyle(color: Colors.white, fontSize: 18)),
        centerTitle: true,
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (snapshot) {
          final data = snapshot.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text("User data not found"));

          // Isi controller sekali saja saat data pertama kali dimuat
          _initializeData(data);

          final uid = data['uid'] ?? 'Unknown UID';
          // Email asli (untuk keperluan re-auth jika user ganti email/password)
          final originalEmail = data['email'] ?? ''; 

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // 1. AVATAR (Visual Only) - SUDAH DIKEMBALIKAN KE AppColors.primary
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary, // ✨ KEMBALI KE WARNA BIRU/PRIMARY
                      child: Text(
                        _nameController.text.isNotEmpty ? _nameController.text[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AppColors.surface, 
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 30),

                // 2. MAIN PROFILE FORM (Card Style)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 4),
                    child: Text("Your profile", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // UID (Read Only + Copy)
                      _buildReadOnlyRow(
                        label: "UID", 
                        value: uid, 
                        icon: Icons.copy,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: uid));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("UID Copied!"), duration: Duration(seconds: 1)));
                        }
                      ),
                      _buildDivider(),

                      // Fullname (Editable)
                      _buildEditableRow(
                        label: "Full Name", 
                        controller: _nameController, 
                        icon: Icons.edit
                      ),
                      _buildDivider(),

                      // Email (Editable/Readonly)
                      _buildEditableRow(
                        label: "Email", 
                        controller: _emailController, 
                        icon: Icons.edit,
                        readOnly: false // Ubah ke false jika logic update email sudah siap
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 3. SECURITY SECTION (Card Style)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10, left: 4),
                    child: Text("Security (Change Password)", style: TextStyle(color: Colors.grey[400], fontSize: 14)),
                  ),
                ),

                Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      // Current Password
                      _buildEditableRow(
                        label: "Current Pass", 
                        controller: _oldPassController, 
                        icon: _obscureOld ? Icons.visibility_off : Icons.visibility,
                        isPassword: true,
                        obscureText: _obscureOld,
                        onIconTap: () => setState(() => _obscureOld = !_obscureOld),
                        hint: "Required to save changes",
                      ),
                      _buildDivider(),

                      // New Password
                      _buildEditableRow(
                        label: "New Pass", 
                        controller: _newPassController, 
                        icon: _obscureNew ? Icons.visibility_off : Icons.visibility,
                        isPassword: true,
                        obscureText: _obscureNew,
                        onIconTap: () => setState(() => _obscureNew = !_obscureNew),
                        hint: "Leave blank to keep current",
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // 4. SAVE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      // Tutup keyboard
                      FocusScope.of(context).unfocus();
                      
                      await ref.read(authControllerProvider.notifier).updateProfile(
                        newName: _nameController.text,
                        email: originalEmail,
                        newEmail: _emailController.text != originalEmail ? _emailController.text : null,
                        oldPassword: _oldPassController.text.isNotEmpty ? _oldPassController.text : null,
                        newPassword: _newPassController.text.isNotEmpty ? _newPassController.text : null,
                      );
                      
                      // Bersihkan field password setelah save sukses/gagal
                      _oldPassController.clear();
                      _newPassController.clear();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save Changes", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),

                const SizedBox(height: 16),

                // 5. LOGOUT BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) Navigator.of(context).popUntil((route) => route.isFirst);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text("Log Out", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      color: Colors.black26, 
      height: 1, 
      thickness: 1, 
      indent: 16, 
      endIndent: 16
    );
  }

  // Widget Row yang BISA DIEDIT (TextField)
  Widget _buildEditableRow({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    bool readOnly = false,
    String? hint,
    VoidCallback? onIconTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), 
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              readOnly: readOnly,
              textAlign: TextAlign.right,
              style: TextStyle(color: readOnly ? Colors.grey : Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 13),
                border: InputBorder.none, 
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onIconTap, 
            child: Icon(icon, color: Colors.grey[600], size: 18),
          ),
        ],
      ),
    );
  }

  // Widget Row Khusus Read Only (UID)
  Widget _buildReadOnlyRow({
    required String label, 
    required String value, 
    required IconData icon, 
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(color: Colors.grey[400], fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Icon(icon, color: Colors.grey[600], size: 18),
          ],
        ),
      ),
    );
  }
}