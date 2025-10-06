import 'package:flutter/material.dart';
import '../models/sport_activity.dart';
import '../services/sport_service.dart';

class SportsActivitiesPage extends StatefulWidget {
  const SportsActivitiesPage({super.key});

  @override
  State<SportsActivitiesPage> createState() => _SportsActivitiesPageState();
}

class _SportsActivitiesPageState extends State<SportsActivitiesPage> {
  late Future<List<SportActivity>> _futureDeportivas;
  List<SportActivity> _actividadesInfantiles = [];
  List<SportActivity> _actividadesAdultos = [];

  @override
  void initState() {
    super.initState();
    _futureDeportivas = _loadActividadesDeportivas();
  }

  Future<List<SportActivity>> _loadActividadesDeportivas() async {
    final actividades = await SportService.getActividadesDeportivas();
    
    _actividadesInfantiles = actividades.where((a) => a.isInfantil).toList();
    _actividadesAdultos = actividades.where((a) => a.isAdulto).toList();
    
    return actividades;
  }

  void _refreshData() {
    setState(() {
      _futureDeportivas = _loadActividadesDeportivas();
    });
  }

  // Función para manejar el pago
  void _handlePago(SportActivity actividad) {
    // Aquí puedes implementar la lógica de pago
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          "Procesar Pago",
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        content: Text(
          "¿Desea proceder con el pago para:\n\n${actividad.nombreActividad}?",
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancelar",
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aquí iría la navegación a la pantalla de pago
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Redirigiendo al pago: ${actividad.nombreActividad}",
                    style: const TextStyle(fontFamily: 'Montserrat'),
                  ),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(13, 71, 161, 1),
            ),
            child: const Text(
              "Continuar",
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Actividades Deportivas",
          style: TextStyle(fontFamily: 'Montserrat', fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
            tooltip: "Actualizar",
          ),
        ],
      ),
      body: FutureBuilder<List<SportActivity>>(
        future: _futureDeportivas,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString());
          }

          return _buildContent();
        },
      ),
    );
  }

  Widget _buildContent() {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _getColorWithOpacity(Colors.black, 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const TabBar(
              labelColor: Color.fromRGBO(13, 71, 161, 1),
              unselectedLabelColor: Colors.grey,
              indicatorColor: Color.fromRGBO(13, 71, 161, 1),
              labelStyle: TextStyle(
                fontFamily: 'Montserrat',
                fontWeight: FontWeight.bold,
              ),
              tabs: [
                Tab(
                  icon: Icon(Icons.child_care),
                  text: 'INFANTILES',
                ),
                Tab(
                  icon: Icon(Icons.person),
                  text: 'ADULTOS',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildListaActividades(_actividadesInfantiles, Colors.blue),
                _buildListaActividades(_actividadesAdultos, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaActividades(List<SportActivity> actividades, Color color) {
    if (actividades.isEmpty) {
      return _buildEmptyState("No hay actividades disponibles");
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadActividadesDeportivas();
        setState(() {});
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: actividades.length,
        itemBuilder: (context, index) {
          return _buildTarjetaActividad(actividades[index], color);
        },
      ),
    );
  }

  Widget _buildTarjetaActividad(SportActivity actividad, Color color) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    actividad.nombreActividad,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getColorWithOpacity(color, 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    actividad.categoria.toUpperCase(),
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Información básica
            _buildInfoRow(Icons.person, actividad.nombreProfesor),
            _buildInfoRow(Icons.place, actividad.lugar),
            _buildInfoRow(Icons.people, actividad.edad),
            
            // Días y Horarios - JUNTOS
            _buildDiasYHorarios(actividad),
            
            // Grupos (si existen)
            if (actividad.grupos.isNotEmpty && actividad.grupos.length > 1) 
              _buildGrupos(actividad),
            
            // Costos
            if (actividad.costosMensuales.isNotEmpty) ..._buildCostos(actividad),
            
            // Avisos
            if (actividad.avisos.isNotEmpty) _buildAvisos(actividad),
            
            // BOTÓN DE PAGAR - AGREGADO AQUÍ
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 45,
              child: ElevatedButton.icon(
                onPressed: () => _handlePago(actividad),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromRGBO(13, 71, 161, 1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.payment, size: 20),
                label: const Text(
                  "PAGAR ACTIVIDAD",
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiasYHorarios(SportActivity actividad) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.schedule, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Días - usa diasFormateados que usa dia1-dia7
                if (actividad.tieneDias)
                  Text(
                    actividad.diasFormateados,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                // Horarios
                if (actividad.horarios.isNotEmpty)
                  ...actividad.horarios.map((horario) => Text(
                    horario,
                    style: const TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  )),
                // Si no hay información de días ni horarios
                if (!actividad.tieneDias && actividad.horarios.isEmpty)
                  const Text(
                    'Horario por confirmar',
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 13,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrupos(SportActivity actividad) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text(
          "Grupos Disponibles:",
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: actividad.grupos.map((grupo) {
            return Chip(
              label: Text(
                grupo,
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontSize: 11,
                ),
              ),
              backgroundColor: _getColorWithOpacity(Colors.blue, 0.1),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildCostos(SportActivity actividad) {
    return [
      const SizedBox(height: 8),
      const Text(
        "Costos Mensuales:",
        style: TextStyle(
          fontFamily: 'Montserrat',
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      const SizedBox(height: 4),
      Wrap(
        spacing: 8,
        runSpacing: 4,
        children: actividad.costosMensuales.map((costo) {
          return Chip(
            label: Text(
              costo,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 12,
              ),
            ),
            backgroundColor: _getColorWithOpacity(Colors.green, 0.1),
            visualDensity: VisualDensity.compact,
          );
        }).toList(),
      ),
    ];
  }

  Widget _buildAvisos(SportActivity actividad) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getColorWithOpacity(Colors.orange, 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.info, size: 16, color: Colors.orange),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  actividad.avisos,
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 12,
                    color: _getMaterialColor(Colors.orange, 800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    if (text.isEmpty) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.sports_soccer, size: 64, color: _getMaterialColor(Colors.grey, 300)),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text(
            "Error al cargar actividades",
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refreshData,
            child: const Text(
              "Reintentar",
              style: TextStyle(fontFamily: 'Montserrat'),
            ),
          ),
        ],
      ),
    );
  }

  // Método auxiliar para reemplazar .withOpacity() deprecado
  Color _getColorWithOpacity(Color color, double opacity) {
    return Color.alphaBlend(color.withAlpha((opacity * 255).round()), Colors.transparent);
  }

  // Método auxiliar para obtener colores de Material design sin usar el operador []
  Color _getMaterialColor(MaterialColor color, int shade) {
    switch (shade) {
      case 50: return color.shade50;
      case 100: return color.shade100;
      case 200: return color.shade200;
      case 300: return color.shade300;
      case 400: return color.shade400;
      case 500: return color.shade500;
      case 600: return color.shade600;
      case 700: return color.shade700;
      case 800: return color.shade800;
      case 900: return color.shade900;
      default: return color;
    }
  }
}