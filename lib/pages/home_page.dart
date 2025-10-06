import 'package:flutter/material.dart';
import 'profile_page.dart';
import 'payments_page.dart';
import '../utils/session_manager.dart';
import 'welcome_page.dart';
import 'settings_page.dart';
import 'sports_activities_page.dart';
import 'cultural_activities_page.dart';
import 'events_page.dart'; // ✅ IMPORTACIÓN AGREGADA

class HomePage extends StatelessWidget {
  final Map<String, dynamic> user;

  const HomePage({super.key, required this.user});

  Future<void> _logout(BuildContext context) async {
    await SessionManager.logout();
    
    if (!context.mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const WelcomePage()),
      (Route<dynamic> route) => false,
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            "Cerrar Sesión",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "¿Estás seguro de que quieres cerrar sesión?",
            style: TextStyle(fontFamily: 'Montserrat'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                "Cancelar",
                style: TextStyle(fontFamily: 'Montserrat'),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _logout(context);
              },
              child: const Text(
                "Cerrar Sesión",
                style: TextStyle(fontFamily: 'Montserrat', color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
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
              "Hola, ${user['primer_nombre'] ?? ''}",
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "Usuario: ${user['numero_usuario'] ?? ''}",
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
            onPressed: () => _showLogoutConfirmation(context),
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
              () => _navigateToPage(
                context,
                const SportsActivitiesPage(),
              ),
            ),
            _buildSectionButton(
              context,
              "Actividades Culturales",
              Icons.music_note,
              () => _navigateToPage(
                context,
                const CulturalActivitiesPage(),
              ),
            ),
            _buildSectionButton(
              context,
              "Eventos",
              Icons.event,
              () => _navigateToPage(context, const EventsPage()), // ✅ CORREGIDO
            ),
            _buildSectionButton(
              context,
              "Noticias",
              Icons.article,
              () => _navigateToPage(context, _PlaceholderPage(title: "Noticias")),
            ),
            _buildSectionButton(
              context,
              "Torneos",
              Icons.emoji_events,
              () => _navigateToPage(context, _PlaceholderPage(title: "Torneos")),
            ),
            _buildSectionButton(
              context,
              "Entrenadores",
              Icons.fitness_center,
              () => _navigateToPage(
                context,
                _PlaceholderPage(title: "Entrenadores"),
              ),
            ),
            _buildSectionButton(
              context,
              "Mi membresía",
              Icons.verified_user,
              () => _navigateToPage(context, const PaymentsPage()),
            ),
            _buildSectionButton(
              context,
              "Beneficios",
              Icons.card_giftcard,
              () => _navigateToPage(
                context,
                _PlaceholderPage(title: "Beneficios"),
              ),
            ),
            _buildSectionButton(
              context,
              "Contacto",
              Icons.contact_mail,
              () => _navigateToPage(context, _PlaceholderPage(title: "Contacto")),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
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
        currentIndex: 0,
        selectedItemColor: const Color.fromRGBO(25, 118, 210, 1),
        unselectedItemColor: Colors.grey,
        onTap: (index) => _onBottomNavTap(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Inicio"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Config."),
        ],
      ),
    );
  }

  void _onBottomNavTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfilePage(email: user['email'] ?? ''),
          ),
        );
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SettingsPage(user: user)),
        );
        break;
    }
  }

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
          backgroundColor: const Color.fromRGBO(227, 242, 253, 1),
          foregroundColor: const Color.fromRGBO(13, 71, 161, 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, size: 28, color: const Color.fromRGBO(13, 71, 161, 1)),
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

class _PlaceholderPage extends StatelessWidget {
  final String title;
  const _PlaceholderPage({required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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