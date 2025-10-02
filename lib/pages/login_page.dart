import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:local_auth/local_auth.dart';
import '../utils/session_manager.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;
  bool _canUseBiometric = false;

  final LocalAuthentication auth = LocalAuthentication();

  late AnimationController _shineController;
  late Animation<double> _shineAnimation;

  // Sistema de logging mejorado
  void _logInfo(String message) {
    if (kDebugMode) {
      // Solo se ejecuta en modo debug
      debugPrint('ℹ️ LOGIN: $message');
    }
  }

  void _logError(String message, [dynamic error]) {
    if (kDebugMode) {
      // Solo se ejecuta en modo debug
      if (error != null) {
        debugPrint('❌ LOGIN ERROR: $message - $error');
      } else {
        debugPrint('❌ LOGIN ERROR: $message');
      }
    }
  }

  void _logSuccess(String message) {
    if (kDebugMode) {
      // Solo se ejecuta en modo debug
      debugPrint('✅ LOGIN SUCCESS: $message');
    }
  }

  @override
  void initState() {
    super.initState();

    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _shineAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(parent: _shineController, curve: Curves.linear));

    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    _shineController.dispose();
    super.dispose();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool biometricEnabled = await SessionManager.isBiometricEnabled();
      final bool canUseBiometric = await SessionManager.canUseBiometricLogin();

      if (!mounted) return;
      setState(() {
        _canUseBiometric = biometricEnabled && canUseBiometric;
      });

      _logInfo('Biometría disponible: $_canUseBiometric');
    } catch (e) {
      _logError('Error verificando biometría', e);
      if (!mounted) return;
      setState(() {
        _canUseBiometric = false;
      });
    }
  }

  Future<void> _login() async {
    // Verificar campos vacíos - no necesita mounted porque es síncrono
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ingresa correo y contraseña")),
        );
      }
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse("https://clubfrance.org.mx/api/login.php"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "email": _emailController.text.trim(),
          "password": _passwordController.text.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        final user = {
          "user_id": data['user_id'],
          "numero_usuario": data['numero_usuario'],
          "email": data['email'],
          "primer_nombre": data['primer_nombre'],
          "primer_apellido": data['primer_apellido'],
          "foto": data['foto'] ?? "",
        };

        await SessionManager.saveUser(user);

        // VERIFICAR SI LA BIOMETRÍA ESTÁ HABILITADA PARA GUARDAR CREDENCIALES
        final bool biometricEnabled = await SessionManager.isBiometricEnabled();
        if (biometricEnabled) {
          await SessionManager.saveUserForBiometric(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
            userData: user,
          );
          _logSuccess('Credenciales guardadas para biometría');
        }

        _logSuccess('Login exitoso para: ${user['email']}');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage(user: user)),
        );
      } else {
        final message = data['message'] ?? "Error al iniciar sesión";
        _logError('Error en login API: $message');

        if (!mounted) return;
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(message)));
        }
      }
    } catch (e) {
      _logError('Error de conexión en login', e);

      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error de conexión: ${e.toString()}")),
        );
      }
    }

    if (!mounted) return;
    setState(() => _loading = false);
  }

  /// 🔑 Login con huella/rostro - CORREGIDO
  Future<void> _loginBiometric() async {
    try {
      // VERIFICAR SI PUEDE USAR BIOMETRÍA
      if (!_canUseBiometric) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Primero inicia sesión con correo/contraseña para habilitar el login biométrico",
              ),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      // VERIFICAR SI EL BIOMÉTRICO ESTÁ HABILITADO EN CONFIGURACIÓN
      final bool biometricEnabled = await SessionManager.isBiometricEnabled();
      if (!biometricEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "El login biométrico está desactivado en la configuración",
              ),
            ),
          );
        }
        return;
      }

      bool canCheck = await auth.canCheckBiometrics;
      bool authenticated = false;

      if (canCheck) {
        _logInfo('Iniciando autenticación biométrica');
        authenticated = await auth.authenticate(
          localizedReason: 'Usa tu huella o rostro para iniciar sesión',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
      } else {
        _logError('Biometría no disponible en este dispositivo');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Biometría no disponible en este dispositivo"),
            ),
          );
        }
        return;
      }

      if (authenticated) {
        if (!mounted) return;
        setState(() => _loading = true);

        // OBTENER CREDENCIALES GUARDADAS
        final String? email = await SessionManager.getBiometricEmail();
        final String? password = await SessionManager.getBiometricPassword();

        if (email == null || password == null) {
          _logError('No se encontraron credenciales guardadas para biometría');
          if (!mounted) return;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("No se encontraron credenciales guardadas"),
              ),
            );
          }
          setState(() => _loading = false);
          return;
        }

        _logInfo('Credenciales biométricas obtenidas, procediendo con login');

        // HACER LOGIN CON LAS CREDENCIALES GUARDADAS
        try {
          final response = await http.post(
            Uri.parse("https://clubfrance.org.mx/api/login.php"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"email": email, "password": password}),
          );

          final data = jsonDecode(response.body);

          if (data['success'] == true) {
            final user = {
              "user_id": data['user_id'],
              "numero_usuario": data['numero_usuario'],
              "email": data['email'],
              "primer_nombre": data['primer_nombre'],
              "primer_apellido": data['primer_apellido'],
              "foto": data['foto'] ?? "",
            };

            await SessionManager.saveUser(user);

            _logSuccess('Login biométrico exitoso para: $email');

            if (!mounted) return;
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => HomePage(user: user)),
            );
          } else {
            final message =
                data['message'] ?? "Error al iniciar sesión biométrica";
            _logError('Error en login biométrico API: $message');

            if (!mounted) return;
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(message)));
            }

            // SI FALLA EL LOGIN, LIMPIAR DATOS BIOMÉTRICOS
            _logInfo('Limpiando datos biométricos por fallo de autenticación');
            await SessionManager.clearBiometricData();
            await _checkBiometricAvailability();
          }
        } catch (e) {
          _logError('Error de conexión en login biométrico', e);

          if (!mounted) return;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Error de conexión: ${e.toString()}")),
            );
          }
        }

        if (!mounted) return;
        setState(() => _loading = false);
      } else {
        _logInfo('Autenticación biométrica cancelada por el usuario');
      }
    } catch (e) {
      _logError('Error en proceso biométrico', e);

      if (!mounted) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error biométrico: ${e.toString()}")),
        );
      }
      setState(() => _loading = false);
    }
  }

  Widget _shineButton({
    required String text,
    required Gradient gradient,
    required VoidCallback onPressed,
    Color textColor = Colors.white,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled
                ? gradient
                : LinearGradient(
                    colors: [Colors.grey.shade600, Colors.grey.shade400],
                  ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: enabled ? onPressed : null,
            child: Stack(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Montserrat',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: enabled ? textColor : Colors.grey.shade300,
                    ),
                  ),
                ),
                if (enabled)
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _shineAnimation,
                      builder: (context, child) {
                        return FractionalTranslation(
                          translation: Offset(_shineAnimation.value, 0),
                          child: child,
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color.fromRGBO(255, 255, 255, 0.0),
                              const Color.fromRGBO(255, 255, 255, 0.15),
                              const Color.fromRGBO(255, 255, 255, 0.0),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset("assets/images/1.jpg", fit: BoxFit.cover),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Image.asset(
              "assets/images/logoblanco.png",
              width: 160,
              height: 70,
              fit: BoxFit.contain,
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.email,
                              color: Colors.white70,
                            ),
                            labelText: "Correo electrónico",
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.yellow,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'Montserrat',
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: Colors.white70,
                            ),
                            labelText: "Contraseña",
                            labelStyle: const TextStyle(color: Colors.white70),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.white54,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Colors.yellow,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _loading
                            ? const CircularProgressIndicator(
                                color: Colors.yellow,
                              )
                            : _shineButton(
                                text: "Ingresar",
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFFFD700),
                                    Color(0xFFFFC107),
                                  ],
                                ),
                                textColor: Colors.black,
                                onPressed: _login,
                              ),
                        const SizedBox(height: 12),
                        _shineButton(
                          text: "Login biométrico",
                          gradient: const LinearGradient(
                            colors: [Colors.blueAccent, Colors.lightBlue],
                          ),
                          textColor: Colors.white,
                          onPressed: _loginBiometric,
                          enabled: _canUseBiometric,
                        ),
                        if (!_canUseBiometric)
                          const Padding(
                            padding: EdgeInsets.only(top: 8.0),
                            child: Text(
                              "Habilita la biometría después del primer login",
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                                fontFamily: 'Montserrat',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            "¿Olvidaste tu contraseña?",
                            style: TextStyle(
                              color: Colors.white70,
                              fontFamily: 'Montserrat',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
