import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/sport_activity.dart';

class SportService {
  static const String baseUrl = 'https://clubfrance.org.mx';
  static const String mainEndpoint = '$baseUrl/api/deportes_endpoint.php';

  static Future<List<SportActivity>> getActividadesDeportivas() async {
    try {
      print('🚀 Conectando a: $mainEndpoint');
      
      final response = await http.get(
        Uri.parse(mainEndpoint),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      print('📡 Status Code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(utf8.decode(response.bodyBytes));
        
        print('✅ Conexión exitosa con el servidor');
        print('📊 Total de actividades: ${jsonResponse['total']}');
        print('📋 Success: ${jsonResponse['success']}');
        
        if (jsonResponse['success'] == true) {
          final List<dynamic> data = jsonResponse['data'];
          print('🎯 Número de actividades en data: ${data.length}');
          
          // Debug: mostrar información del primer elemento
          if (data.isNotEmpty) {
            final primerElemento = data[0];
            print('🔍 Primer elemento del JSON:');
            print('   ID: ${primerElemento['id']}');
            print('   Nombre: ${primerElemento['nombre_actividad']}');
            print('   Categoría: ${primerElemento['categoria']}');
            
            // Mostrar información de días del primer elemento
            print('   Días encontrados (dia1-dia7):');
            for (int i = 1; i <= 7; i++) {
              final dia = primerElemento['dia$i']?.toString();
              print('     dia$i: "$dia" (tipo: ${dia?.runtimeType})');
            }
          }
          
          final actividades = data.map((json) {
            try {
              return SportActivity.fromJson(json);
            } catch (e) {
              print('❌ Error parseando actividad: $e');
              print('   JSON problemático: $json');
              // Retornar una actividad por defecto en caso de error
              return SportActivity(
                id: 0,
                nombreActividad: 'Error cargando actividad',
                lugar: '',
                edad: '',
                nombreProfesor: '',
                categoria: '',
                status: '',
                avisos: '',
                grupos: [],
                horarios: [],
                costosMensuales: [],
                diasSemana: [],
              );
            }
          }).toList();
          
          // Filtrar actividades válidas (excluyendo las que tuvieron error)
          final actividadesValidas = actividades.where((a) => a.id != 0).toList();
          
          // Log para debugging de días
          print('📅 RESUMEN DE DÍAS:');
          for (int i = 0; i < actividadesValidas.length && i < 3; i++) {
            final actividad = actividadesValidas[i];
            print('   ${actividad.nombreActividad}:');
            print('     - Días procesados: ${actividad.diasSemana}');
            print('     - Días formateados: "${actividad.diasFormateados}"');
          }
          
          // Estadísticas
          final infantiles = actividadesValidas.where((a) => a.isInfantil).length;
          final adultos = actividadesValidas.where((a) => a.isAdulto).length;
          final conDias = actividadesValidas.where((a) => a.tieneDias).length;
          
          print('👶 Actividades Infantiles: $infantiles');
          print('👨 Actividades Adultos: $adultos');
          print('📅 Actividades con días: $conDias');
          print('🎯 Total de actividades cargadas: ${actividadesValidas.length}');
          
          return actividadesValidas;
        } else {
          throw Exception('Error del servidor: ${jsonResponse['error']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error conectando al servidor: $e');
      print('🔄 Usando datos de ejemplo...');
      return await _getDatosEjemplo();
    }
  }

  static Future<List<SportActivity>> _getDatosEjemplo() async {
    await Future.delayed(const Duration(seconds: 1));
    
    return [
      SportActivity(
        id: 1,
        nombreActividad: "Fútbol Infantil (Modo Demo)",
        lugar: "Cancha Principal",
        edad: "Niños 6-12 años",
        nombreProfesor: "Prof. Juan Pérez",
        categoria: "Infantiles",
        status: "activo",
        avisos: "Traer ropa deportiva y agua",
        grupos: ["Grupo A: 6-8 años", "Grupo B: 9-12 años"],
        horarios: ["16:00-17:30", "17:30-19:00"],
        costosMensuales: ["\$500", "\$450"],
        diasSemana: ["Lunes", "Miércoles", "Viernes"],
      ),
      SportActivity(
        id: 2,
        nombreActividad: "Natación Adultos (Modo Demo)",
        lugar: "Alberca Olímpica",
        edad: "Adultos 18+ años",
        nombreProfesor: "Prof. María García",
        categoria: "Adultos",
        status: "activo",
        avisos: "Traer traje de baño y toalla",
        grupos: ["Principiantes", "Intermedios", "Avanzados"],
        horarios: ["07:00-08:30", "19:00-20:30", "20:30-22:00"],
        costosMensuales: ["\$600", "\$550", "\$700"],
        diasSemana: ["Martes", "Jueves"],
      ),
    ];
  }
}