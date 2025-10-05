import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _platosRef = FirebaseDatabase.instance.ref('platos');
  final DatabaseReference _empleadosRef = FirebaseDatabase.instance.ref('empleados');
  final DatabaseReference _proveedoresRef = FirebaseDatabase.instance.ref('proveedores');

  int totalPlatos = 0;
  int platosDisponibles = 0;
  int platosNoDisponibles = 0;
  Map<String, int> platosPorCategoria = {};
  double precioPromedio = 0.0;
  double precioMasAlto = 0.0;
  double precioMasBajo = 0.0;

  int totalEmpleados = 0;
  int empleadosActivos = 0;
  int empleadosInactivos = 0;
  Map<String, int> empleadosPorArea = {};

  int totalProveedores = 0;
  Map<String, int> proveedoresPorCategoria = {};

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  void _cargarEstadisticas() {
    // Escuchar cambios en platos
    _platosRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> platos = event.snapshot.value as Map;
        _procesarPlatos(platos);
      }
    });

    // Escuchar cambios en empleados
    _empleadosRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> empleados = event.snapshot.value as Map;
        _procesarEmpleados(empleados);
      }
    });

    // Escuchar cambios en proveedores
    _proveedoresRef.onValue.listen((event) {
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> proveedores = event.snapshot.value as Map;
        _procesarProveedores(proveedores);
      }
    });
  }

  void _procesarPlatos(Map<dynamic, dynamic> platos) {
    int disponibles = 0;
    int noDisponibles = 0;
    Map<String, int> categorias = {};
    List<double> precios = [];

    platos.forEach((key, value) {
      // Disponibilidad
      if (value['disponible'] == true) {
        disponibles++;
      } else {
        noDisponibles++;
      }

      // Categorías
      String categoria = value['categoria'] ?? 'Sin categoría';
      categorias[categoria] = (categorias[categoria] ?? 0) + 1;

      // Precios
      double precio = (value['precio'] ?? 0).toDouble();
      precios.add(precio);
    });

    setState(() {
      totalPlatos = platos.length;
      platosDisponibles = disponibles;
      platosNoDisponibles = noDisponibles;
      platosPorCategoria = categorias;

      if (precios.isNotEmpty) {
        precioPromedio = precios.reduce((a, b) => a + b) / precios.length;
        precioMasAlto = precios.reduce((a, b) => a > b ? a : b);
        precioMasBajo = precios.reduce((a, b) => a < b ? a : b);
      }
    });
  }

  void _procesarEmpleados(Map<dynamic, dynamic> empleados) {
    int activos = 0;
    int inactivos = 0;
    Map<String, int> areas = {};

    empleados.forEach((key, value) {
      // Estado
      if (value['activo'] == true) {
        activos++;
      } else {
        inactivos++;
      }

      // Áreas
      String area = value['area'] ?? 'Sin área';
      areas[area] = (areas[area] ?? 0) + 1;
    });

    setState(() {
      totalEmpleados = empleados.length;
      empleadosActivos = activos;
      empleadosInactivos = inactivos;
      empleadosPorArea = areas;
    });
  }

  void _procesarProveedores(Map<dynamic, dynamic> proveedores) {
    Map<String, int> categorias = {};

    proveedores.forEach((key, value) {
      String categoria = value['categoria'] ?? 'Sin categoría';
      categorias[categoria] = (categorias[categoria] ?? 0) + 1;
    });

    setState(() {
      totalProveedores = proveedores.length;
      proveedoresPorCategoria = categorias;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard - Don Pollo'),
        backgroundColor: Colors.orange[700],
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _cargarEstadisticas();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjetas de resumen
              _buildResumenGeneral(),
              const SizedBox(height: 20),

              // Sección Platos
              _buildSeccionTitulo('📋 Platos', Icons.restaurant_menu),
              const SizedBox(height: 10),
              _buildEstadisticasPlatos(),
              const SizedBox(height: 20),

              // Sección Empleados
              _buildSeccionTitulo('👥 Empleados', Icons.people),
              const SizedBox(height: 10),
              _buildEstadisticasEmpleados(),
              const SizedBox(height: 20),

              // Sección Proveedores
              _buildSeccionTitulo('🚚 Proveedores', Icons.local_shipping),
              const SizedBox(height: 10),
              _buildEstadisticasProveedores(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenGeneral() {
    return Row(
      children: [
        Expanded(
          child: _buildTarjetaResumen(
            'Platos',
            totalPlatos.toString(),
            Icons.restaurant,
            Colors.orange,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTarjetaResumen(
            'Empleados',
            totalEmpleados.toString(),
            Icons.people,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildTarjetaResumen(
            'Proveedores',
            totalProveedores.toString(),
            Icons.local_shipping,
            Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildTarjetaResumen(String titulo, String valor, IconData icono, Color color) {
    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icono, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeccionTitulo(String titulo, IconData icono) {
    return Row(
      children: [
        Icon(icono, color: Colors.orange[700]),
        const SizedBox(width: 8),
        Text(
          titulo,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.orange[700],
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasPlatos() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCardInfo(
                'Disponibles',
                platosDisponibles.toString(),
                Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCardInfo(
                'No Disponibles',
                platosNoDisponibles.toString(),
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _buildCardInfo(
                'Precio Promedio',
                'S/ ${precioPromedio.toStringAsFixed(2)}',
                Colors.blue,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCardInfo(
                'Precio Más Alto',
                'S/ ${precioMasAlto.toStringAsFixed(2)}',
                Colors.purple,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Platos por Categoría',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ...platosPorCategoria.entries.map((entry) {
                  double porcentaje = (entry.value / totalPlatos) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: entry.value / totalPlatos,
                            backgroundColor: Colors.grey[300],
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${entry.value} (${porcentaje.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasEmpleados() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildCardInfo(
                'Activos',
                empleadosActivos.toString(),
                Colors.green,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildCardInfo(
                'Inactivos',
                empleadosInactivos.toString(),
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Empleados por Área',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 10),
                ...empleadosPorArea.entries.map((entry) {
                  double porcentaje = (entry.value / totalEmpleados) * 100;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(entry.key),
                        ),
                        Expanded(
                          flex: 3,
                          child: LinearProgressIndicator(
                            value: entry.value / totalEmpleados,
                            backgroundColor: Colors.grey[300],
                            valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${entry.value} (${porcentaje.toStringAsFixed(0)}%)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstadisticasProveedores() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Proveedores por Categoría',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            ...proveedoresPorCategoria.entries.map((entry) {
              double porcentaje = (entry.value / totalProveedores) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(entry.key),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: entry.value / totalProveedores,
                        backgroundColor: Colors.grey[300],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${entry.value} (${porcentaje.toStringAsFixed(0)}%)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCardInfo(String titulo, String valor, Color color) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              titulo,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              valor,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}