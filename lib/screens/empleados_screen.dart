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

  // Filtros avanzados
  String _filtroArea = 'Todas';
  String _filtroEstado = 'Todos';
  String _ordenamiento = 'nombre_asc';

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

  void _mostrarFiltrosAvanzados() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filtros Avanzados',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  
                  // Filtro por área
                  const Text('Área:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: _filtroArea,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: ['Todas', ..._areas].map((area) {
                      return DropdownMenuItem(value: area, child: Text(area));
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _filtroArea = value ?? 'Todas';
                        });
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  // Filtro por estado
                  const Text('Estado:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: _filtroEstado,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: ['Todos', 'Activos', 'Inactivos'].map((estado) {
                      return DropdownMenuItem(value: estado, child: Text(estado));
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _filtroEstado = value ?? 'Todos';
                        });
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  // Ordenamiento
                  const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: _ordenamiento,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'nombre_asc', child: Text('Nombre (A-Z)')),
                      DropdownMenuItem(value: 'nombre_desc', child: Text('Nombre (Z-A)')),
                      DropdownMenuItem(value: 'fecha_asc', child: Text('Fecha ingreso (antiguo)')),
                      DropdownMenuItem(value: 'fecha_desc', child: Text('Fecha ingreso (reciente)')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _ordenamiento = value ?? 'nombre_asc';
                        });
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _filtroArea = 'Todas';
                              _filtroEstado = 'Todos';
                              _ordenamiento = 'nombre_asc';
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey,
                          ),
                          child: const Text('Limpiar filtros'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange[700],
                          ),
                          child: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<MapEntry> _aplicarFiltrosYOrdenamiento(List<MapEntry> listaEmpleados) {
    // Aplicar filtros
    listaEmpleados = listaEmpleados.where((entry) {
      bool cumpleArea = _filtroArea == 'Todas' || 
                        entry.value['area'] == _filtroArea;
      
      bool cumpleEstado = _filtroEstado == 'Todos' ||
                          (_filtroEstado == 'Activos' && entry.value['activo'] == true) ||
                          (_filtroEstado == 'Inactivos' && entry.value['activo'] == false);
      
      bool cumpleBusqueda = _busqueda.isEmpty ||
                           entry.value['nombre'].toString().toLowerCase().contains(_busqueda) ||
                           entry.value['dni'].toString().contains(_busqueda);
      
      return cumpleArea && cumpleEstado && cumpleBusqueda;
    }).toList();

    // Aplicar ordenamiento
    listaEmpleados.sort((a, b) {
      switch (_ordenamiento) {
        case 'nombre_asc':
          return a.value['nombre'].toString().compareTo(b.value['nombre'].toString());
        case 'nombre_desc':
          return b.value['nombre'].toString().compareTo(a.value['nombre'].toString());
        case 'fecha_asc':
          return (a.value['fechaIngreso'] ?? '').toString().compareTo((b.value['fechaIngreso'] ?? '').toString());
        case 'fecha_desc':
          return (b.value['fechaIngreso'] ?? '').toString().compareTo((a.value['fechaIngreso'] ?? '').toString());
        default:
          return 0;
      }
    });

    return listaEmpleados;
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
          
          // Búsqueda y Filtros
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _buscarController,
                    decoration: InputDecoration(
                      labelText: 'Buscar por nombre o DNI',
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _busqueda = value.toLowerCase();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _mostrarFiltrosAvanzados,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filtros'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ],
            ),
          ),

          // Chips de filtros activos
          if (_filtroArea != 'Todas' || _filtroEstado != 'Todos')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filtroArea != 'Todas')
                    Chip(
                      label: Text('Área: $_filtroArea'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _filtroArea = 'Todas';
                        });
                      },
                    ),
                  if (_filtroEstado != 'Todos')
                    Chip(
                      label: Text(_filtroEstado),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _filtroEstado = 'Todos';
                        });
                      },
                    ),
                ],
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

                // Aplicar filtros y ordenamiento
                listaEmpleados = _aplicarFiltrosYOrdenamiento(listaEmpleados);

                if (listaEmpleados.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No se encontraron empleados con los filtros seleccionados'),
                      ],
                    ),
                  );
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