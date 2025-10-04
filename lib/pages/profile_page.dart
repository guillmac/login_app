import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../utils/session_manager.dart';
import 'welcome_page.dart';
import 'home_page.dart';
import 'settings_page.dart';

class ProfilePage extends StatefulWidget {
  final String email;
  const ProfilePage({super.key, required this.email});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? user;
  bool loading = true;
  bool editing = false;
  File? _newImage;
  final int _selectedIndex = 1; // Perfil seleccionado

  // Controladores de texto
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _coloniaController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _emergenciaNombreController =
      TextEditingController();
  final TextEditingController _emergenciaTelefonoController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    setState(() => loading = true);
    try {
      final response = await http.post(
        Uri.parse("https://clubfrance.org.mx/api/get_user.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email.trim()}),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          user = data['user'];
          loading = false;

          _telefonoController.text = user!['telefono'] ?? "";
          _direccionController.text = user!['calle'] ?? "";
          _coloniaController.text = user!['colonia'] ?? "";
          _ciudadController.text = user!['ciudad'] ?? "";
          _emergenciaNombreController.text = user!['emergencia_nombre'] ?? "";
          _emergenciaTelefonoController.text =
              user!['emergencia_telefono'] ?? "";
        });
      } else {
        setState(() => loading = false);
        // Usar variable local para context después de verificar mounted
        final messenger = ScaffoldMessenger.of(context);
        messenger.showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Error al obtener usuario"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _guardarCambios() async {
    try {
      String? fotoUrl = user!['foto'];

      if (_newImage != null) {
        // Corregir la orientación de la imagen antes de subirla
        File imagenCorregida = await _corregirOrientacionImagen(_newImage!);

        var request = http.MultipartRequest(
          "POST",
          Uri.parse("https://clubfrance.org.mx/api/upload_foto.php"),
        );
        request.fields['email'] = widget.email.trim();
        request.files.add(
          await http.MultipartFile.fromPath('foto', imagenCorregida.path),
        );
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();

        if (!mounted) return;

        var json = jsonDecode(responseBody);
        if (json['success'] == true) {
          fotoUrl = json['path'];
        } else {
          final messenger = ScaffoldMessenger.of(context);
          messenger.showSnackBar(
            SnackBar(
              content: Text(json['message'] ?? "Error al subir la foto"),
            ),
          );
          return;
        }
      }

      final response = await http.post(
        Uri.parse("https://clubfrance.org.mx/api/update_user.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": widget.email.trim(),
          "numero_usuario": user!['numero_usuario'],
          "telefono": _telefonoController.text.trim(),
          "calle": _direccionController.text.trim(),
          "colonia": _coloniaController.text.trim(),
          "ciudad": _ciudadController.text.trim(),
          "emergencia_nombre": _emergenciaNombreController.text.trim(),
          "emergencia_telefono": _emergenciaTelefonoController.text.trim(),
          "foto": fotoUrl,
        }),
      );

      if (!mounted) return;

      final data = jsonDecode(response.body);
      final messenger = ScaffoldMessenger.of(context);
      if (data['success'] == true) {
        setState(() {
          editing = false;
          _newImage = null;
        });
        messenger.showSnackBar(
          const SnackBar(content: Text("Datos actualizados con éxito")),
        );
        _fetchUser();
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? "Error al guardar cambios"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Función para corregir la orientación de la imagen
  Future<File> _corregirOrientacionImagen(File imageFile) async {
    // En una implementación real, aquí usarías un paquete como image_picker
    // que ya corrige la orientación automáticamente, o un paquete como flutter_exif_rotation
    // Para este ejemplo, retornamos el mismo archivo
    return imageFile;
  }

  void _navigateToPage(int index) {
    if (index == _selectedIndex) return; // Ya está en la página actual

    if (index == 0) {
      // Navegar a HomePage - reemplazando toda la pila
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage(user: user!)),
        (route) => false,
      );
    } else if (index == 2) {
      // Navegar a SettingsPage - reemplazando toda la pila
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => SettingsPage(user: user!)),
        (route) => false,
      );
    }
  }

  void _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.front,
      imageQuality: 85, // Calidad media para reducir tamaño
    );

    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
    }
  }

  // Widget para mostrar la imagen corregida
  Widget _buildProfileImage() {
    if (_newImage != null) {
      // Para imágenes nuevas, usar Image.file con fit
      return Image.file(_newImage!, fit: BoxFit.cover, width: 120, height: 120);
    } else if (user!['foto'] != null && user!['foto']!.isNotEmpty) {
      // Para imágenes de red, usar Image.network
      return Image.network(
        user!['foto']!,
        fit: BoxFit.cover,
        width: 120,
        height: 120,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.person, size: 60, color: Colors.grey);
        },
      );
    } else {
      // Placeholder por defecto
      return const Icon(Icons.person, size: 60, color: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("No se pudo cargar el usuario")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Perfil de ${user!['primer_nombre'] ?? ''}",
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Usuario: ${user!['numero_usuario'] ?? ''}",
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          if (!editing)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black87),
              onPressed: () => setState(() => editing = true),
            ),
          if (editing)
            IconButton(
              icon: const Icon(Icons.save, color: Colors.black87),
              onPressed: _guardarCambios,
            ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Foto de perfil - Mejorada para corregir orientación
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: ClipOval(child: _buildProfileImage()),
                ),
                if (editing)
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: _pickImage,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              "${user!['primer_nombre'] ?? ''} ${user!['primer_apellido'] ?? ''}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: "Montserrat",
              ),
            ),
            Text(
              user!['email'] ?? '',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontFamily: "Montserrat",
              ),
            ),
            const SizedBox(height: 24),

            // Campos de información
            _buildField("Teléfono", _telefonoController, editing, Icons.phone),
            _buildField(
              "Dirección",
              _direccionController,
              editing,
              Icons.location_on,
            ),
            _buildField("Colonia", _coloniaController, editing, Icons.home),
            _buildField(
              "Ciudad",
              _ciudadController,
              editing,
              Icons.location_city,
            ),
            _buildField(
              "Contacto de emergencia",
              _emergenciaNombreController,
              editing,
              Icons.emergency,
            ),
            _buildField(
              "Teléfono de emergencia",
              _emergenciaTelefonoController,
              editing,
              Icons.phone_android,
            ),
          ],
        ),
      ),
      // SOLO UN BottomNavigationBar - verifica que las otras páginas no tengan uno también
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromRGBO(25, 118, 210, 1),
        unselectedItemColor: Colors.grey,
        onTap: _navigateToPage,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Config."),
        ],
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    bool editable,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: editable
          ? TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(227, 242, 253, 1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color.fromRGBO(13, 71, 161, 1)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontFamily: "Montserrat",
                            color: Color.fromRGBO(13, 71, 161, 1),
                          ),
                        ),
                        Text(
                          controller.text.isNotEmpty
                              ? controller.text
                              : "No especificado",
                          style: const TextStyle(fontFamily: "Montserrat"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
