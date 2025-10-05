import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/platos_screen.dart';
import 'screens/empleados_screen.dart';
import 'screens/proveedores_screen.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔵 [MAIN] Iniciando aplicación...');
  
  try {
    print('🔵 [FIREBASE] Intentando inicializar Firebase...');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    print('✅ [FIREBASE] Firebase inicializado correctamente');
  } catch (e, stackTrace) {
    print('❌ [FIREBASE ERROR] Error al inicializar Firebase:');
    print('Error: $e');
    print('StackTrace: $stackTrace');
  }
  
  print('🔵 [MAIN] Ejecutando runApp...');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('🔵 [BUILD] Construyendo MyApp...');
    
    return MaterialApp(
      title: 'Pollería Don Pollo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.orange,
        useMaterial3: true,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.orange[700],
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

// Pantalla de carga que verifica Firebase
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _status = 'Iniciando...';
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    print('🔵 [SPLASH] Iniciando SplashScreen...');
    _inicializarApp();
  }

  Future<void> _inicializarApp() async {
    try {
      setState(() {
        _status = 'Verificando Firebase...';
      });
      
      print('🔵 [SPLASH] Verificando Firebase...');
      
      // Verificar que Firebase esté inicializado
      final app = Firebase.app();
      print('✅ [SPLASH] Firebase App: ${app.name}');
      
      setState(() {
        _status = 'Conexión exitosa';
      });
      
      // Esperar un momento antes de navegar
      await Future.delayed(const Duration(seconds: 1));
      
      print('🔵 [SPLASH] Navegando a HomeScreen...');
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
      
    } catch (e, stackTrace) {
      print('❌ [SPLASH ERROR] Error: $e');
      print('StackTrace: $stackTrace');
      
      setState(() {
        _hasError = true;
        _errorMessage = e.toString();
        _status = 'Error de conexión';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 [SPLASH BUILD] Construyendo Splash...');
    
    return Scaffold(
      backgroundColor: Colors.orange[700],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo o icono
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                Icons.restaurant,
                size: 60,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 30),
            
            // Título
            const Text(
              'Pollería Don Pollo',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            
            // Estado
            Text(
              _status,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 30),
            
            // Indicador de carga o error
            if (!_hasError)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              )
            else
              Column(
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 50,
                  ),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      _errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _status = 'Reintentando...';
                      });
                      _inicializarApp();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.orange[700],
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

// Pantalla principal con navegación
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PlatosScreen(),
    const EmpleadosScreen(),
    const ProveedoresScreen(),
  ];

  @override
  void initState() {
    super.initState();
    print('🔵 [HOME] HomeScreen iniciado');
  }

  @override
  Widget build(BuildContext context) {
    print('🔵 [HOME BUILD] Construyendo HomeScreen, index: $_currentIndex');
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          print('🔵 [HOME] Navegando a índice: $index');
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Platos',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Empleados',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping),
            label: 'Proveedores',
          ),
        ],
      ),
    );
  }
}