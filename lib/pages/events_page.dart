import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({super.key});

  @override
  State<EventsPage> createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Map<String, dynamic>> eventos = [];
  bool loading = true;
  bool error = false;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadEventos();
  }

  Future<void> _loadEventos() async {
    setState(() {
      loading = true;
      error = false;
    });

    try {
      final url = "https://clubfrance.org.mx/api/get_eventos.php";
      debugPrint('🔍 Cargando eventos desde: $url');
      
      final response = await http.get(
        Uri.parse(url),
      ).timeout(const Duration(seconds: 15));

      debugPrint('📡 Response status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('📡 JSON decodificado: $data');
        
        if (data['success'] == true && data['eventos'] != null) {
          debugPrint('✅ Eventos cargados exitosamente');
          final eventosProcesados = _procesarEventos(
            List<Map<String, dynamic>>.from(data['eventos'])
          );
          setState(() {
            eventos = eventosProcesados;
            error = false;
          });
        } else {
          debugPrint('❌ API respondió: ${data['message']}');
          _useMockEventos();
        }
      } else {
        debugPrint('❌ Error HTTP: ${response.statusCode}');
        _useMockEventos();
      }
    } catch (e) {
      debugPrint('❌ Error: $e');
      _useMockEventos();
    } finally {
      setState(() => loading = false);
    }
  }

  void _useMockEventos() {
    setState(() {
      eventos = [
        {
          'id': 1,
          'evento': 'Torneo de Tenis Interclubes',
          'nombre': 'Campeonato Anual',
          'organizador': 'Club France',
          'fecha': '2024-12-15',
          'lugar': 'Canchas de Tenis',
          'horario': '09:00 - 18:00',
          'celular': '555-123-4567',
          'avisos': 'Traer raqueta y ropa deportiva. Inscripción previa requerida.',
          'es_mock': true,
        },
        {
          'id': 2,
          'evento': 'Noche de Gala Navideña',
          'nombre': 'Cena de Fin de Año',
          'organizador': 'Comité Social',
          'fecha': '2024-12-20',
          'lugar': 'Salón Principal',
          'horario': '20:00 - 02:00',
          'celular': '555-987-6543',
          'avisos': 'Vestimenta formal. Confirmar asistencia antes del 10/12.',
          'es_mock': true,
        },
        {
          'id': 3,
          'evento': 'Clase de Yoga al Aire Libre',
          'nombre': 'Yoga Matutino',
          'organizador': 'Departamento de Wellness',
          'fecha': '2024-12-08',
          'lugar': 'Jardín Principal',
          'horario': '07:00 - 08:30',
          'celular': '555-456-7890',
          'avisos': 'Traer tapete propio. Clase gratuita para miembros.',
          'es_mock': true,
        },
      ];
      error = true;
      errorMessage = 'Usando datos de ejemplo';
    });
  }

  List<Map<String, dynamic>> _procesarEventos(List<Map<String, dynamic>> eventosRaw) {
    return eventosRaw.map((evento) {
      return {
        'id': evento['id'],
        'evento': evento['evento'] ?? 'Evento sin nombre',
        'nombre': evento['nombre'] ?? '',
        'organizador': evento['organizador'] ?? 'Club France',
        'fecha': evento['fecha'] ?? '',
        'lugar': evento['lugar'] ?? 'Por confirmar',
        'horario': evento['horario'] ?? 'Por confirmar',
        'celular': evento['celular'] ?? '',
        'avisos': evento['avisos'] ?? '',
        'es_mock': false,
      };
    }).toList();
  }

  String _formatearFecha(String fecha) {
    try {
      if (fecha.isEmpty) return 'Fecha por confirmar';
      
      // Intentar diferentes formatos de fecha
      final formats = [
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('MM/dd/yyyy'),
      ];
      
      DateTime? parsedDate;
      for (var format in formats) {
        try {
          parsedDate = format.parse(fecha);
          break;
        } catch (e) {
          continue;
        }
      }
      
      if (parsedDate != null) {
        return DateFormat('EEEE, d MMMM yyyy', 'es_ES').format(parsedDate);
      }
      
      return fecha;
    } catch (e) {
      return fecha;
    }
  }

  String _formatearDiaMes(String fecha) {
    try {
      if (fecha.isEmpty) return '--';
      
      final formats = [
        DateFormat('yyyy-MM-dd'),
        DateFormat('dd/MM/yyyy'),
        DateFormat('MM/dd/yyyy'),
      ];
      
      DateTime? parsedDate;
      for (var format in formats) {
        try {
          parsedDate = format.parse(fecha);
          break;
        } catch (e) {
          continue;
        }
      }
      
      if (parsedDate != null) {
        return DateFormat('d MMM', 'es_ES').format(parsedDate);
      }
      
      return '--';
    } catch (e) {
      return '--';
    }
  }

  Color _getColorEvento(int index) {
    final colors = [
      const Color.fromRGBO(25, 118, 210, 1),
      Colors.purple,
      Colors.green,
      Colors.orange,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  Widget _buildEventoCard(Map<String, dynamic> evento, int index) {
    final color = _getColorEvento(index);
    final esMock = evento['es_mock'] == true;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: esMock ? Colors.orange : color.withAlpha(100),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y badge de mock
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fecha en círculo
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: color.withAlpha(30),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: color, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _formatearDiaMes(evento['fecha']),
                          style: TextStyle(
                            fontFamily: 'Montserrat',
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                evento['evento'],
                                style: const TextStyle(
                                  fontFamily: 'Montserrat',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (esMock) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'EJEMPLO',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Montserrat',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (evento['nombre'].isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            evento['nombre'],
                            style: const TextStyle(
                              fontFamily: 'Montserrat',
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Información del evento
              _buildInfoItem(Icons.calendar_today, _formatearFecha(evento['fecha'])),
              _buildInfoItem(Icons.schedule, evento['horario']),
              _buildInfoItem(Icons.location_on, evento['lugar']),
              _buildInfoItem(Icons.person, 'Organiza: ${evento['organizador']}'),
              
              if (evento['celular'].isNotEmpty) ...[
                _buildInfoItem(Icons.phone, evento['celular']),
              ],
              
              if (evento['avisos'].isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700], size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Avisos Importantes:',
                            style: TextStyle(
                              fontFamily: 'Montserrat',
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        evento['avisos'],
                        style: const TextStyle(
                          fontFamily: 'Montserrat',
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 8),
              
              // Botones de acción
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _mostrarConfirmacionAsistencia(evento);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: color,
                        side: BorderSide(color: color),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text(
                        'CONFIRMAR ASISTENCIA',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _compartirEvento(evento);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text(
                        'COMPARTIR',
                        style: TextStyle(
                          fontFamily: 'Montserrat',
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.black87,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarConfirmacionAsistencia(Map<String, dynamic> evento) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Confirmar Asistencia',
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '¿Confirmas tu asistencia al evento "${evento['evento']}"?',
          style: const TextStyle(
            fontFamily: 'Montserrat',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'CANCELAR',
              style: TextStyle(
                fontFamily: 'Montserrat',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _mostrarMensajeExito('Asistencia confirmada para ${evento['evento']}');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromRGBO(25, 118, 210, 1),
            ),
            child: const Text(
              'CONFIRMAR',
              style: TextStyle(
                fontFamily: 'Montserrat',
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _compartirEvento(Map<String, dynamic> evento) {
    _mostrarMensajeExito('Evento "${evento['evento']}" compartido');
  }

  void _mostrarMensajeExito(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          mensaje,
          style: const TextStyle(fontFamily: 'Montserrat'),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          "Eventos y Actividades",
          style: TextStyle(
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadEventos,
            tooltip: 'Recargar',
          ),
        ],
      ),
      body: loading
          ? _buildLoadingState()
          : error
              ? _buildErrorState()
              : eventos.isEmpty
                  ? _buildEmptyState()
                  : _buildEventosList(),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 20),
          Text(
            'Cargando eventos...',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline,
          size: 64,
          color: Colors.orange,
        ),
        const SizedBox(height: 16),
        Text(
          errorMessage,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Mostrando eventos de ejemplo',
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: Colors.black38,
          ),
        ),
        const SizedBox(height: 20),
        ElevatedButton(
          onPressed: _loadEventos,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromRGBO(25, 118, 210, 1),
            foregroundColor: Colors.white,
          ),
          child: const Text(
            'REINTENTAR',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_busy,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No hay eventos programados',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vuelve pronto para ver nuevas actividades',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 14,
              color: Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventosList() {
    return Column(
      children: [
        // Header informativo
        if (error)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      color: Colors.orange[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Contador de eventos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.event, color: Color.fromRGBO(25, 118, 210, 1)),
              const SizedBox(width: 8),
              Text(
                '${eventos.length} evento${eventos.length != 1 ? 's' : ''} encontrado${eventos.length != 1 ? 's' : ''}',
                style: const TextStyle(
                  fontFamily: 'Montserrat',
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        
        // Lista de eventos
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: eventos.length,
            itemBuilder: (context, index) {
              return _buildEventoCard(eventos[index], index);
            },
          ),
        ),
      ],
    );
  }
}