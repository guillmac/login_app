import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'payments_page.dart';
import '../utils/session_manager.dart';

class HomePage extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  void _logout(BuildContext context) async {
    await SessionManager.logout();
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Fondo blanco minimalista
      appBar: AppBar(
        automaticallyImplyLeading: false, // ❌ Quita flecha de retroceso
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, ${widget.user['primer_nombre'] ?? ''}",
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Usuario: ${widget.user['numero_usuario'] ?? ''}",
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black87),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSectionButton(
              context,
              "Actividades Deportivas",
              Icons.sports_soccer,
              () => _navigate(
                context,
                const PlaceholderPage(title: "Actividades Deportivas"),
              ),
            ),
            _buildSectionButton(
              context,
              "Actividades Culturales",
              Icons.music_note,
              () => _navigate(
                context,
                const PlaceholderPage(title: "Actividades Culturales"),
              ),
            ),
            _buildSectionButton(
              context,
              "Eventos",
              Icons.event,
              () => _navigate(context, const PlaceholderPage(title: "Eventos")),
            ),
            _buildSectionButton(
              context,
              "Noticias",
              Icons.article,
              () =>
                  _navigate(context, const PlaceholderPage(title: "Noticias")),
            ),
            _buildSectionButton(
              context,
              "Torneos",
              Icons.emoji_events,
              () => _navigate(context, const PlaceholderPage(title: "Torneos")),
            ),
            _buildSectionButton(
              context,
              "Entrenadores",
              Icons.fitness_center,
              () => _navigate(
                context,
                const PlaceholderPage(title: "Entrenadores"),
              ),
            ),
            _buildSectionButton(
              context,
              "Mi membresía",
              Icons.verified_user,
              () => _navigate(context, const PaymentsPage()),
            ),
            _buildSectionButton(
              context,
              "Beneficios",
              Icons.card_giftcard,
              () => _navigate(
                context,
                const PlaceholderPage(title: "Beneficios"),
              ),
            ),
            _buildSectionButton(
              context,
              "Contacto",
              Icons.contact_mail,
              () =>
                  _navigate(context, const PlaceholderPage(title: "Contacto")),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
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
          selectedItemColor: Colors.blue[700],
          unselectedItemColor: Colors.grey,
          onTap: (index) {
            setState(() => _selectedIndex = index);
            if (index == 0) {
              // Inicio
            } else if (index == 1) {
              _navigate(context, ProfilePage(email: widget.user['email']));
            } else if (index == 2) {
              _navigate(context, const PlaceholderPage(title: "Configuración"));
            }
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
            BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: "Config.",
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Botón de sección plano moderno
  Widget _buildSectionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[50],
          foregroundColor: Colors.blue[800],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 28, color: Colors.blue[800]),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// PlaceholderPage moderno
class PlaceholderPage extends StatelessWidget {
  final String title;
  const PlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(title, style: const TextStyle(fontFamily: 'Montserrat')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Center(
        child: Text(
          "Aquí irá la pantalla de $title",
          style: const TextStyle(fontSize: 18, fontFamily: 'Montserrat'),
        ),
      ),
    );
  }
}
