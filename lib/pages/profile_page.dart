import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../utils/session_manager.dart';
import 'welcome_page.dart';

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

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        if (!mounted) return;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  Future<void> _guardarCambios() async {
    try {
      String? fotoUrl = user!['foto'];

      // Subir nueva foto si existe
      if (_newImage != null) {
        var request = http.MultipartRequest(
          "POST",
          Uri.parse("https://clubfrance.org.mx/api/upload_foto.php"),
        );
        request.fields['email'] = widget.email.trim();
        request.files.add(
          await http.MultipartFile.fromPath('foto', _newImage!.path),
        );
        var response = await request.send();
        var responseBody = await response.stream.bytesToString();
        var json = jsonDecode(responseBody);
        if (json['success'] == true) {
          fotoUrl = json['path'];
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(json['message'] ?? "Error al subir la foto"),
            ),
          );
          return;
        }
      }

      // Enviar datos al update_user.php
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

      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        setState(() {
          editing = false;
          _newImage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Datos actualizados con éxito")),
        );
        _fetchUser(); // refresca los datos
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data['message'])));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void _logout() async {
    await SessionManager.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (Route<dynamic> route) => false,
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
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
      appBar: AppBar(
        title: const Text("Perfil"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          if (!editing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => editing = true),
            ),
          if (editing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardarCambios,
            ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _newImage != null
                      ? FileImage(_newImage!)
                      : (user!['foto'] != null
                                ? NetworkImage(user!['foto'])
                                : null)
                            as ImageProvider<Object>?,
                  child: (_newImage == null && user!['foto'] == null)
                      ? const Icon(Icons.person, size: 60)
                      : null,
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
              "${user!['primer_nombre']} ${user!['primer_apellido']}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                fontFamily: "Montserrat",
              ),
            ),
            const SizedBox(height: 24),
            _buildField("Teléfono", _telefonoController, editing),
            _buildField("Calle", _direccionController, editing),
            _buildField("Colonia", _coloniaController, editing),
            _buildField("Ciudad", _ciudadController, editing),
            _buildField(
              "Contacto emergencia",
              _emergenciaNombreController,
              editing,
            ),
            _buildField(
              "Teléfono emergencia",
              _emergenciaTelefonoController,
              editing,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController controller,
    bool editable,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: editable
          ? TextFormField(
              controller: controller,
              decoration: InputDecoration(
                labelText: label,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            )
          : ListTile(
              title: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: "Montserrat",
                ),
              ),
              subtitle: Text(
                controller.text,
                style: const TextStyle(fontFamily: "Montserrat"),
              ),
            ),
    );
  }
}
