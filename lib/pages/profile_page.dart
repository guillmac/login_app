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

  // Controladores de texto - TODOS LOS CAMPOS
  final TextEditingController _primerNombreController = TextEditingController();
  final TextEditingController _segundoNombreController = TextEditingController();
  final TextEditingController _primerApellidoController = TextEditingController();
  final TextEditingController _segundoApellidoController = TextEditingController();
  final TextEditingController _fechaNacimientoController = TextEditingController();
  final TextEditingController _generoController = TextEditingController();
  final TextEditingController _telefonoController = TextEditingController();
  final TextEditingController _calleController = TextEditingController();
  final TextEditingController _numeroController = TextEditingController();
  final TextEditingController _coloniaController = TextEditingController();
  final TextEditingController _alcaldiaController = TextEditingController();
  final TextEditingController _cpController = TextEditingController();
  final TextEditingController _ciudadController = TextEditingController();
  final TextEditingController _emergenciaNombreController = TextEditingController();
  final TextEditingController _emergenciaTelefonoController = TextEditingController();
  final TextEditingController _emergenciaParentescoController = TextEditingController();
  final TextEditingController _tipoSangreController = TextEditingController();
  final TextEditingController _alergiasController = TextEditingController();
  final TextEditingController _enfermedadesCronicasController = TextEditingController();

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

          // Inicializar TODOS los controladores
          _primerNombreController.text = user!['primer_nombre'] ?? "";
          _segundoNombreController.text = user!['segundo_nombre'] ?? "";
          _primerApellidoController.text = user!['primer_apellido'] ?? "";
          _segundoApellidoController.text = user!['segundo_apellido'] ?? "";
          _fechaNacimientoController.text = user!['fecha_nacimiento'] ?? "";
          _generoController.text = _getGeneroDisplay(user!['genero']);
          _telefonoController.text = _getValorLimpio(user!['telefono']);
          _calleController.text = user!['calle'] ?? "";
          _numeroController.text = user!['numero'] ?? "";
          _coloniaController.text = user!['colonia'] ?? "";
          _alcaldiaController.text = user!['alcaldia'] ?? "";
          _cpController.text = _getValorLimpio(user!['cp']);
          _ciudadController.text = user!['ciudad'] ?? "";
          _emergenciaNombreController.text = user!['emergencia_nombre'] ?? "";
          _emergenciaTelefonoController.text = _getValorLimpio(user!['emergencia_telefono']);
          _emergenciaParentescoController.text = user!['emergencia_parentesco'] ?? "";
          _tipoSangreController.text = user!['tipo_sangre'] ?? "";
          _alergiasController.text = user!['alergias'] ?? "";
          _enfermedadesCronicasController.text = user!['enfermedades_cronicas'] ?? "";
        });
      } else {
        setState(() => loading = false);
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

  // Función mejorada para limpiar valores
  String _getValorLimpio(dynamic valor) {
    if (valor == null) {
      return "";
    }
    
    final stringValor = valor.toString().trim();
    
    if (stringValor.isEmpty) {
      return "";
    }
    
    // Casos especiales que deben tratarse como vacío
    if (stringValor.toLowerCase() == 'null' || 
        stringValor == 'NULL' ||
        stringValor == 'Null' ||
        stringValor == 'n/a' ||
        stringValor == 'N/A' ||
        stringValor == 'no especificado') {
      return "";
    }
    
    return stringValor;
  }

  // Función para mostrar el género de forma amigable
  String _getGeneroDisplay(String? genero) {
    if (genero == null || genero.isEmpty) return "";
    switch (genero) {
      case 'M': return 'Masculino';
      case 'F': return 'Femenino';
      case 'O': return 'Otro';
      default: return genero;
    }
  }

  // Función inversa para guardar el género
  String _getGeneroValue(String display) {
    switch (display) {
      case 'Masculino': return 'M';
      case 'Femenino': return 'F';
      case 'Otro': return 'O';
      default: return 'O';
    }
  }

  Future<void> _guardarCambios() async {
    try {
      String? fotoUrl = user!['foto'];

      if (_newImage != null) {
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

      // Preparar datos para enviar
      final Map<String, dynamic> updateData = {
        "email": widget.email.trim(),
        "numero_usuario": user!['numero_usuario'],
        "primer_nombre": _primerNombreController.text.trim(),
        "segundo_nombre": _segundoNombreController.text.trim(),
        "primer_apellido": _primerApellidoController.text.trim(),
        "segundo_apellido": _segundoApellidoController.text.trim(),
        "fecha_nacimiento": _fechaNacimientoController.text.trim(),
        "genero": _getGeneroValue(_generoController.text),
        "telefono": _telefonoController.text.trim(),
        "calle": _calleController.text.trim(),
        "numero": _numeroController.text.trim(),
        "colonia": _coloniaController.text.trim(),
        "alcaldia": _alcaldiaController.text.trim(),
        "cp": _cpController.text.trim(),
        "ciudad": _ciudadController.text.trim(),
        "emergencia_nombre": _emergenciaNombreController.text.trim(),
        "emergencia_telefono": _emergenciaTelefonoController.text.trim(),
        "emergencia_parentesco": _emergenciaParentescoController.text.trim(),
        "tipo_sangre": _tipoSangreController.text.trim(),
        "alergias": _alergiasController.text.trim(),
        "enfermedades_cronicas": _enfermedadesCronicasController.text.trim(),
        "foto": fotoUrl,
      };

      final response = await http.post(
        Uri.parse("https://clubfrance.org.mx/api/update_user.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(updateData),
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
        _fetchUser(); // Recargar datos para verificar
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

  Future<File> _corregirOrientacionImagen(File imageFile) async {
    return imageFile;
  }

  void _navigateToPage(int index) {
    if (index == _selectedIndex) return;

    if (index == 0) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => HomePage(user: user!)),
        (route) => false,
      );
    } else if (index == 2) {
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
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() => _newImage = File(pickedFile.path));
    }
  }

  Widget _buildProfileImage() {
    if (_newImage != null) {
      return Image.file(_newImage!, fit: BoxFit.cover, width: 120, height: 120);
    } else if (user!['foto'] != null && user!['foto']!.isNotEmpty) {
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
      return const Icon(Icons.person, size: 60, color: Colors.grey);
    }
  }

  // Calcular edad a partir de la fecha de nacimiento
  String? _calcularEdad() {
    final fechaNacimiento = _fechaNacimientoController.text;
    if (fechaNacimiento.isEmpty) return null;
    
    try {
      final nacimiento = DateTime.parse(fechaNacimiento);
      final ahora = DateTime.now();
      final edad = ahora.year - nacimiento.year;
      final mesCumple = ahora.month > nacimiento.month || 
                        (ahora.month == nacimiento.month && ahora.day >= nacimiento.day);
      return mesCumple ? edad.toString() : (edad - 1).toString();
    } catch (e) {
      return null;
    }
  }

  // Concatenar calle y número para mostrar en modo lectura
  String _getDireccionCompleta() {
    final calle = _calleController.text;
    final numero = _numeroController.text;
    
    if (calle.isEmpty && numero.isEmpty) return "No especificada";
    if (calle.isEmpty) return numero;
    if (numero.isEmpty) return calle;
    
    return "$calle $numero";
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
            // Foto de perfil
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
            
            // Información principal
            Text(
              "${_primerNombreController.text} ${_primerApellidoController.text}",
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
            
            // Información de membresía
            _buildInfoCard(
              "Membresía",
              Icons.card_membership,
              [
                _buildInfoItem("Número de Usuario", user!['numero_usuario']?.toString() ?? ''),
                _buildInfoItem("Tipo de Membresía", user!['tipo_membresia'] ?? "Individual"),
                _buildInfoItem("Estado", user!['estatus_membresia'] ?? "Activo"),
                if (user!['fecha_inicio_membresia'] != null)
                  _buildInfoItem("Fecha Inicio", user!['fecha_inicio_membresia'] ?? ""),
                if (user!['fecha_fin_membresia'] != null)
                  _buildInfoItem("Fecha Fin", user!['fecha_fin_membresia'] ?? ""),
                if (user!['saldo_pendiente'] != null && user!['saldo_pendiente'] != "0.00")
                  _buildInfoItem("Saldo Pendiente", "\$${user!['saldo_pendiente']}"),
              ],
            ),

            const SizedBox(height: 24),

            // SECCIÓN: INFORMACIÓN PERSONAL
            _buildSectionHeader("Información Personal"),
            if (editing) _buildField("Primer Nombre", _primerNombreController, editing, Icons.person),
            if (editing) _buildField("Segundo Nombre", _segundoNombreController, editing, Icons.person_outline),
            if (editing) _buildField("Primer Apellido", _primerApellidoController, editing, Icons.person),
            if (editing) _buildField("Segundo Apellido", _segundoApellidoController, editing, Icons.person_outline),
            
            _buildField("Fecha de Nacimiento", _fechaNacimientoController, editing, Icons.cake),
            if (!editing && _fechaNacimientoController.text.isNotEmpty) 
              _buildStaticInfo("Edad", _calcularEdad() ?? "No especificada", Icons.emoji_people),
            
            if (editing) 
              _buildDropdownField("Género", _generoController, editing, Icons.person_outline, 
                ['Masculino', 'Femenino', 'Otro']),
            if (!editing && _generoController.text.isNotEmpty)
              _buildStaticInfo("Género", _generoController.text, Icons.person_outline),
            
            _buildField("Celular", _telefonoController, editing, Icons.phone_android),

            const SizedBox(height: 24),

            // SECCIÓN: DIRECCIÓN
            _buildSectionHeader("Dirección"),
            if (editing) ...[
              _buildField("Calle", _calleController, editing, Icons.signpost),
              _buildField("Número", _numeroController, editing, Icons.numbers),
            ] else
              _buildStaticInfo("Calle y Número", _getDireccionCompleta(), Icons.location_on),
            
            _buildField("Colonia", _coloniaController, editing, Icons.home),
            _buildField("Alcaldía/Municipio", _alcaldiaController, editing, Icons.account_balance),
            _buildField("Código Postal", _cpController, editing, Icons.markunread_mailbox),
            _buildField("Ciudad", _ciudadController, editing, Icons.location_city),

            const SizedBox(height: 24),

            // SECCIÓN: CONTACTO DE EMERGENCIA
            _buildSectionHeader("Contacto de Emergencia"),
            _buildField("Nombre Completo", _emergenciaNombreController, editing, Icons.emergency),
            _buildField("Celular", _emergenciaTelefonoController, editing, Icons.phone_android),
            _buildField("Parentesco", _emergenciaParentescoController, editing, Icons.family_restroom),

            const SizedBox(height: 24),

            // SECCIÓN: INFORMACIÓN MÉDICA
            _buildSectionHeader("Información Médica"),
            _buildField("Tipo de Sangre", _tipoSangreController, editing, Icons.bloodtype),
            _buildField("Alergias", _alergiasController, editing, Icons.health_and_safety),
            _buildField("Enfermedades Crónicas", _enfermedadesCronicasController, editing, Icons.medical_services),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildDropdownField(
    String label,
    TextEditingController controller,
    bool editable,
    IconData icon,
    List<String> options,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: editable
          ? DropdownButtonFormField<String>(
              // CORREGIDO: Cambiado 'value' por 'initialValue'
              initialValue: controller.text.isEmpty ? null : controller.text,
              decoration: InputDecoration(
                labelText: label,
                prefixIcon: Icon(icon),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              items: options.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  controller.text = newValue ?? '';
                });
              },
            )
          : _buildStaticInfo(label, controller.text.isNotEmpty ? controller.text : "No especificado", icon),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(color: Colors.grey.shade300),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(25, 118, 210, 1),
              ),
            ),
          ),
          Expanded(
            child: Divider(color: Colors.grey.shade300),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color.fromRGBO(25, 118, 210, 1)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value.isNotEmpty ? value : "No especificado",
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaticInfo(String label, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
                  value.isNotEmpty ? value : "No especificado",
                  style: const TextStyle(fontFamily: "Montserrat"),
                ),
              ],
            ),
          ),
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
          : _buildStaticInfo(label, controller.text.isNotEmpty ? controller.text : "No especificado", icon),
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
            color: Colors.black.withValues(alpha: 0.05),
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
}