import 'package:flutter/material.dart';

class EventosPage extends StatefulWidget {
  const EventosPage({super.key});

  @override
  State<EventosPage> createState() => _EventosPageState();
}

class _EventosPageState extends State<EventosPage> {
  // Ejemplo de eventos por mes
  final Map<String, List<String>> eventosPorMes = {
    'Enero': ['Torneo de Fútbol', 'Clases de Natación'],
    'Febrero': ['Maratón Anual', 'Taller de Dibujo'],
    'Marzo': ['Torneo de Tenis', 'Concierto de Música'],
    'Abril': ['Competencia de Natación', 'Teatro Infantil'],
    'Mayo': ['Clases de Yoga', 'Torneo de Basquetbol'],
    'Junio': ['Festival Deportivo', 'Taller de Pintura'],
    'Julio': ['Torneo de Fútbol', 'Exposición de Arte'],
    'Agosto': ['Clases de Danza', 'Competencia de Natación'],
    'Septiembre': ['Torneo de Tenis', 'Concierto de Música'],
    'Octubre': ['Carrera 5K', 'Taller de Teatro'],
    'Noviembre': ['Torneo de Basquetbol', 'Festival Cultural'],
    'Diciembre': ['Exhibición de Arte', 'Torneo de Fútbol'],
  };

  final Map<String, bool> expandedMonths = {};

  @override
  void initState() {
    super.initState();
    // Inicializar todos los meses como colapsados
    for (var mes in eventosPorMes.keys) {
      expandedMonths[mes] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eventos del Año')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: eventosPorMes.keys.map((mes) {
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            color: Colors.grey[900],
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: const Icon(
                Icons.calendar_month,
                color: Colors.blueAccent,
              ),
              title: Text(
                mes,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              initiallyExpanded: expandedMonths[mes]!,
              onExpansionChanged: (expanded) {
                setState(() {
                  expandedMonths[mes] = expanded;
                });
              },
              children: eventosPorMes[mes]!
                  .map(
                    (evento) => ListTile(
                      title: Text(
                        evento,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      leading: const Icon(
                        Icons.event,
                        color: Colors.orangeAccent,
                      ),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Evento seleccionado: $evento'),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
          );
        }).toList(),
      ),
      backgroundColor: Colors.black,
    );
  }
}
