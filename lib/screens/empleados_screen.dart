import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('empleados');
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _dniController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _cargoController = TextEditingController();
  final TextEditingController _buscarController = TextEditingController();
  
  String _editingId = '';
  DateTime _fechaIngreso = DateTime.now();
  bool _activo = true;
  String _busqueda = '';

  final List<String> _areas = [
    'Cocina',
    'Atención',
    'Delivery',
    'Administración'
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _dniController.dispose();
    _areaController.dispose();
    _cargoController.dispose();
    _buscarController.dispose();
    super.dispose();
  }

  void _mostrarSnackBar(String mensaje, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _fechaIngreso,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _fechaIngreso = picked;
      });
    }
  }

  Future<void> _guardarEmpleado() async {
    if (_nombreController.text.isEmpty || 
        _dniController.text.isEmpty ||
        _areaController.text.isEmpty ||
        _cargoController.text.isEmpty) {
      _mostrarSnackBar('Complete todos los campos requeridos', Colors.red);
      return;
    }

    if (_dniController.text.length != 8) {
      _mostrarSnackBar('El DNI debe tener 8 dígitos', Colors.red);
      return;
    }

    try {
      final empleado = {
        'nombre': _nombreController.text,
        'dni': _dniController.text,
        'area': _areaController.text,
        'cargo': _cargoController.text,
        'fechaIngreso': DateFormat('yyyy-MM-dd').format(_fechaIngreso),
        'activo': _activo,
      };

      if (_editingId.isEmpty) {
        await _dbRef.push().set(empleado);
        _mostrarSnackBar('Empleado agregado exitosamente', Colors.green);
      } else {
        await _dbRef.child(_editingId).update(empleado);
        _mostrarSnackBar('Empleado actualizado exitosamente', Colors.blue);
        _editingId = '';
      }

      _limpiarFormulario();
    } catch (e) {
      _mostrarSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _eliminarEmpleado(String id) async {
    try {
      await _dbRef.child(id).remove();
      _mostrarSnackBar('Empleado eliminado exitosamente', Colors.orange);
    } catch (e) {
      _mostrarSnackBar('Error al eliminar: $e', Colors.red);
    }
  }

  void _cargarParaEditar(String id, Map<dynamic, dynamic> datos) {
    setState(() {
      _editingId = id;
      _nombreController.text = datos['nombre'] ?? '';
      _dniController.text = datos['dni'] ?? '';
      _areaController.text = datos['area'] ?? '';
      _cargoController.text = datos['cargo'] ?? '';
      _activo = datos['activo'] ?? true;
      
      try {
        _fechaIngreso = DateFormat('yyyy-MM-dd').parse(datos['fechaIngreso']);
      } catch (e) {
        _fechaIngreso = DateTime.now();
      }
    });
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _dniController.clear();
    _areaController.clear();
    _cargoController.clear();
    setState(() {
      _editingId = '';
      _fechaIngreso = DateTime.now();
      _activo = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Empleados'),
        backgroundColor: Colors.orange[700],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Formulario
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre completo *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _dniController,
                        keyboardType: TextInputType.number,
                        maxLength: 8,
                        decoration: const InputDecoration(
                          labelText: 'DNI *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge),
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _areaController.text.isEmpty 
                            ? null 
                            : _areaController.text,
                        decoration: const InputDecoration(
                          labelText: 'Área *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        items: _areas.map((area) {
                          return DropdownMenuItem(value: area, child: Text(area));
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _areaController.text = value ?? '';
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _cargoController,
                  decoration: const InputDecoration(
                    labelText: 'Cargo *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.work),
                  ),
                ),
                const SizedBox(height: 10),
                ListTile(
                  title: const Text('Fecha de ingreso'),
                  subtitle: Text(DateFormat('dd/MM/yyyy').format(_fechaIngreso)),
                  leading: const Icon(Icons.calendar_today),
                  trailing: const Icon(Icons.edit),
                  onTap: _seleccionarFecha,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(color: Colors.grey.shade400),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Estado'),
                  subtitle: Text(_activo ? 'Activo' : 'Inactivo'),
                  value: _activo,
                  onChanged: (value) {
                    setState(() {
                      _activo = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _guardarEmpleado,
                        icon: Icon(_editingId.isEmpty ? Icons.add : Icons.save),
                        label: Text(_editingId.isEmpty ? 'Agregar' : 'Actualizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    if (_editingId.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _limpiarFormulario,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscarController,
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o DNI',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _busqueda = value.toLowerCase();
                });
              },
            ),
          ),

          // Lista de empleados
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar datos'));
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No hay empleados registrados'));
                }

                Map<dynamic, dynamic> empleados = snapshot.data!.snapshot.value as Map;
                List<MapEntry> listaEmpleados = empleados.entries.toList();

                // Filtrar por búsqueda
                if (_busqueda.isNotEmpty) {
                  listaEmpleados = listaEmpleados.where((entry) {
                    String nombre = entry.value['nombre'].toString().toLowerCase();
                    String dni = entry.value['dni'].toString();
                    return nombre.contains(_busqueda) || dni.contains(_busqueda);
                  }).toList();
                }

                return ListView.builder(
                  itemCount: listaEmpleados.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final entry = listaEmpleados[index];
                    final id = entry.key;
                    final empleado = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: empleado['activo'] 
                              ? Colors.green 
                              : Colors.red,
                          child: const Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(
                          empleado['nombre'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'DNI: ${empleado['dni']}\n${empleado['area']} - ${empleado['cargo']}\nIngreso: ${empleado['fechaIngreso']}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _cargarParaEditar(id, empleado),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarEmpleado(id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}