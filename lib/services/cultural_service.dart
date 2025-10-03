import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/cultural_activity.dart';

class CulturalService {
  static const String baseUrl = 'https://clubfrance.org.mx';
  static const String mainEndpoint = '$baseUrl/api/cultural_endpoint.php';

  static Future<List<CulturalActivity>> getActividadesCulturales() async {
    try {
      print('🎭 === INICIANDO CARGA ACTIVIDADES CULTURALES ===');
      print('🎭 Conectando a: $mainEndpoint');
      
      final response = await http.get(
        Uri.parse(mainEndpoint),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('🎭 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        
        print('🎭 ✅ Conexión exitosa con el servidor');
        print('🎭 📊 Total de actividades: ${jsonResponse['total']}');
        print('🎭 📋 Success: ${jsonResponse['success']}');
        
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          print('🎭 🎯 Número de actividades culturales en data: ${data.length}');
          
          // Debug: mostrar información detallada del primer elemento
          if (data.isNotEmpty) {
            final primerElemento = data[0];
            print('🎭 🔍 Primer elemento cultural del JSON:');
            print('🎭    ID: ${primerElemento['id']}');
            print('🎭    Nombre: ${primerElemento['nombre_actividad']}');
            print('🎭    Categoría: ${primerElemento['categoria']}');
            print('🎭    Lugar: ${primerElemento['lugar']}');
            print('🎭    Profesor: ${primerElemento['profesor']}');
            print('🎭    Status: ${primerElemento['status']}');
            
            // Mostrar información de días del primer elemento
            print('🎭    Días encontrados (dia1-dia7):');
            for (int i = 1; i <= 7; i++) {
              final dia = primerElemento['dia$i']?.toString();
              print('🎭      dia$i: "$dia"');
            }
            
            // Mostrar información de horarios del primer elemento
            print('🎭    Horarios encontrados:');
            for (int i = 1; i <= 5; i++) {
              final horario = primerElemento['horario_grupo$i']?.toString();
              if (horario != null && horario.isNotEmpty && horario != 'null') {
                print('🎭      horario_grupo$i: "$horario"');
              }
            }
          } else {
            print('🎭 ⚠️  No hay actividades culturales en la base de datos');
          }
          
          final actividades = data.map((json) {
            try {
              return CulturalActivity.fromJson(json);
            } catch (e) {
              print('🎭 ❌ Error parseando actividad cultural: $e');
              print('🎭    JSON problemático: $json');
              // Retornar una actividad por defecto en caso de error
              return CulturalActivity(
                id: 0,
                nombreActividad: 'Error cargando actividad cultural',
                lugar: '',
                profesor: '',
                celular: '',
                horario: '',
                avisos: '',
                facebook: '',
                categoria: '',
                status: '',
                grupos: [],
                horarios: [],
                diasSemana: [],
              );
            }
          }).toList();
          
          // Filtrar actividades válidas (excluyendo las que tuvieron error)
          final actividadesValidas = actividades.where((a) => a.id != 0).toList();
          
          // Log para debugging de días
          print('🎭 📅 RESUMEN DE ACTIVIDADES CULTURALES:');
          for (int i = 0; i < actividadesValidas.length && i < 3; i++) {
            final actividad = actividadesValidas[i];
            print('🎭    ${i + 1}. ${actividad.nombreActividad}');
            print('🎭       - Categoría: ${actividad.categoria}');
            print('🎭       - Días procesados: ${actividad.diasSemana}');
            print('🎭       - Días formateados: "${actividad.diasFormateados}"');
            print('🎭       - Horarios: ${actividad.horarios}');
            print('🎭       - Tiene días: ${actividad.tieneDias}');
            print('🎭       - Tiene horarios: ${actividad.tieneHorarios}');
          }
          
          // Estadísticas
          final infantiles = actividadesValidas.where((a) => a.isInfantil).length;
          final adultos = actividadesValidas.where((a) => a.isAdulto).length;
          final conDias = actividadesValidas.where((a) => a.tieneDias).length;
          final conHorarios = actividadesValidas.where((a) => a.tieneHorarios).length;
          
          print('🎭 📊 ESTADÍSTICAS CULTURALES:');
          print('🎭    👶 Infantiles: $infantiles');
          print('🎭    👨 Adultos: $adultos');
          print('🎭    📅 Con días: $conDias');
          print('🎭    ⏰ Con horarios: $conHorarios');
          print('🎭    🎯 Total cargadas: ${actividadesValidas.length}');
          print('🎭 === CARGA CULTURAL COMPLETADA ===');
          
          return actividadesValidas;
        } else {
          print('🎭 ❌ Error del servidor: ${jsonResponse['error']}');
          throw Exception('Error del servidor: ${jsonResponse['error']}');
        }
      } else {
        print('🎭 ❌ Error HTTP: ${response.statusCode}');
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('🎭 ❌ Error crítico conectando al servidor: $e');
      print('🎭 🔄 Usando datos de ejemplo culturales...');
      return await _getDatosEjemplo();
    }
  }

  static Future<List<CulturalActivity>> _getDatosEjemplo() async {
    await Future.delayed(const Duration(seconds: 1));
    
    print('🎭 🎨 Cargando datos de ejemplo culturales...');
    
    return [
      CulturalActivity(
        id: 1,
        nombreActividad: "Pintura Infantil (Modo Demo)",
        lugar: "Sala de Arte",
        profesor: "Prof. Ana Martínez",
        celular: "555-1234",
        horario: "16:00-18:00",
        avisos: "Traer material de pintura",
        facebook: "ArteClubFrance",
        categoria: "Infantiles",
        status: "activo",
        grupos: ["Grupo A: 6-9 años", "Grupo B: 10-12 años"],
        horarios: ["16:00-17:00", "17:00-18:00"],
        diasSemana: ["Lunes", "Miércoles"],
      ),
      CulturalActivity(
        id: 2,
        nombreActividad: "Teatro Adultos (Modo Demo)",
        lugar: "Auditorio Principal",
        profesor: "Prof. Carlos López",
        celular: "555-5678",
        horario: "19:00-21:00",
        avisos: "Vestimenta cómoda",
        facebook: "TeatroCF",
        categoria: "Adultos",
        status: "activo",
        grupos: ["Principiantes", "Avanzados"],
        horarios: ["19:00-20:00", "20:00-21:00"],
        diasSemana: ["Martes", "Jueves"],
      ),
    ];
  }
}