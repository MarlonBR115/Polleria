import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class PlatosScreen extends StatefulWidget {
  const PlatosScreen({super.key});

  @override
  State<PlatosScreen> createState() => _PlatosScreenState();
}

class _PlatosScreenState extends State<PlatosScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('platos');
  
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _tamanoController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _buscarController = TextEditingController();
  
  String _editingId = '';
  bool _disponible = true;
  String _busqueda = '';
  
  // Variables para filtros avanzados
  String _filtroCategoria = 'Todas';
  String _filtroDisponibilidad = 'Todos';
  String _ordenamiento = 'nombre_asc';
  bool _vistaLista = true;

  final List<String> _categorias = [
    'Pollo a la brasa',
    'Parrillas',
    'Bebidas',
    'Guarniciones',
    'Postres'
  ];

  @override
  void dispose() {
    _nombreController.dispose();
    _categoriaController.dispose();
    _tamanoController.dispose();
    _precioController.dispose();
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
    // Variables temporales para el modal
    String tempCategoria = _filtroCategoria;
    String tempDisponibilidad = _filtroDisponibilidad;
    String tempOrdenamiento = _ordenamiento;

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
                  
                  // Filtro por categoría
                  const Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: tempCategoria,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: ['Todas', ..._categorias].map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempCategoria = value ?? 'Todas';
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  // Filtro por disponibilidad
                  const Text('Disponibilidad:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: tempDisponibilidad,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: ['Todos', 'Disponibles', 'No disponibles'].map((disp) {
                      return DropdownMenuItem(value: disp, child: Text(disp));
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        tempDisponibilidad = value ?? 'Todos';
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  
                  // Ordenamiento
                  const Text('Ordenar por:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: tempOrdenamiento,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'nombre_asc', child: Text('Nombre (A-Z)')),
                      DropdownMenuItem(value: 'nombre_desc', child: Text('Nombre (Z-A)')),
                      DropdownMenuItem(value: 'precio_asc', child: Text('Precio (menor a mayor)')),
                      DropdownMenuItem(value: 'precio_desc', child: Text('Precio (mayor a menor)')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        tempOrdenamiento = value ?? 'nombre_asc';
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
                            Navigator.pop(context);
                            setState(() {
                              _filtroCategoria = 'Todas';
                              _filtroDisponibilidad = 'Todos';
                              _ordenamiento = 'nombre_asc';
                            });
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
                          onPressed: () {
                            Navigator.pop(context);
                            setState(() {
                              _filtroCategoria = tempCategoria;
                              _filtroDisponibilidad = tempDisponibilidad;
                              _ordenamiento = tempOrdenamiento;
                            });
                          },
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

  List<MapEntry> _aplicarFiltrosYOrdenamiento(List<MapEntry> listaPlatos) {
    // Aplicar filtros
    listaPlatos = listaPlatos.where((entry) {
      bool cumpleCategoria = _filtroCategoria == 'Todas' || 
                             entry.value['categoria'] == _filtroCategoria;
      
      bool cumpleDisponibilidad = _filtroDisponibilidad == 'Todos' ||
                                  (_filtroDisponibilidad == 'Disponibles' && entry.value['disponible'] == true) ||
                                  (_filtroDisponibilidad == 'No disponibles' && entry.value['disponible'] == false);
      
      bool cumpleBusqueda = _busqueda.isEmpty ||
                           entry.value['nombre'].toString().toLowerCase().contains(_busqueda);
      
      return cumpleCategoria && cumpleDisponibilidad && cumpleBusqueda;
    }).toList();

    // Aplicar ordenamiento
    listaPlatos.sort((a, b) {
      switch (_ordenamiento) {
        case 'nombre_asc':
          return a.value['nombre'].toString().compareTo(b.value['nombre'].toString());
        case 'nombre_desc':
          return b.value['nombre'].toString().compareTo(a.value['nombre'].toString());
        case 'precio_asc':
          return (a.value['precio'] ?? 0).compareTo(b.value['precio'] ?? 0);
        case 'precio_desc':
          return (b.value['precio'] ?? 0).compareTo(a.value['precio'] ?? 0);
        default:
          return 0;
      }
    });

    return listaPlatos;
  }

  Future<void> _guardarPlato() async {
    if (_nombreController.text.isEmpty || 
        _categoriaController.text.isEmpty ||
        _precioController.text.isEmpty) {
      _mostrarSnackBar('Complete todos los campos requeridos', Colors.red);
      return;
    }

    // Validar que el precio sea un número válido
    final precio = double.tryParse(_precioController.text);
    if (precio == null || precio < 0) {
      _mostrarSnackBar('Ingrese un precio válido', Colors.red);
      return;
    }

    try {
      final plato = {
        'nombre': _nombreController.text.trim(),
        'categoria': _categoriaController.text,
        'tamano': _tamanoController.text.trim().isEmpty ? 'N/A' : _tamanoController.text.trim(),
        'precio': precio,
        'disponible': _disponible,
      };

      if (_editingId.isEmpty) {
        await _dbRef.push().set(plato);
        if (mounted) {
          _mostrarSnackBar('Plato agregado exitosamente', Colors.green);
          _limpiarFormulario();
        }
      } else {
        await _dbRef.child(_editingId).update(plato);
        if (mounted) {
          _mostrarSnackBar('Plato actualizado exitosamente', Colors.blue);
          _limpiarFormulario();
        }
      }
    } catch (e) {
      if (mounted) {
        _mostrarSnackBar('Error: ${e.toString()}', Colors.red);
      }
    }
  }

  Future<void> _eliminarPlato(String id) async {
    try {
      await _dbRef.child(id).remove();
      _mostrarSnackBar('Plato eliminado exitosamente', Colors.orange);
    } catch (e) {
      _mostrarSnackBar('Error al eliminar: $e', Colors.red);
    }
  }

  void _cargarParaEditar(String id, Map<dynamic, dynamic> datos) {
    setState(() {
      _editingId = id;
      _nombreController.text = datos['nombre'] ?? '';
      _categoriaController.text = datos['categoria'] ?? '';
      _tamanoController.text = datos['tamano'] ?? '';
      _precioController.text = datos['precio'].toString();
      _disponible = datos['disponible'] ?? true;
    });
  }

  void _limpiarFormulario() {
    _nombreController.clear();
    _categoriaController.clear();
    _tamanoController.clear();
    _precioController.clear();
    setState(() {
      _editingId = '';
      _disponible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Platos'),
        backgroundColor: Colors.orange[700],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_vistaLista ? Icons.grid_view : Icons.list),
            onPressed: () {
              setState(() {
                _vistaLista = !_vistaLista;
              });
            },
            tooltip: _vistaLista ? 'Vista de tarjetas' : 'Vista de lista',
          ),
        ],
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
                    labelText: 'Nombre del plato *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.restaurant),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: _categoriaController.text.isEmpty 
                      ? null 
                      : _categoriaController.text,
                  decoration: const InputDecoration(
                    labelText: 'Categoría *',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: _categorias.map((cat) {
                    return DropdownMenuItem(value: cat, child: Text(cat));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _categoriaController.text = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _tamanoController,
                        decoration: const InputDecoration(
                          labelText: 'Tamaño/Porción',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.straighten),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _precioController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Precio *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Disponible'),
                  value: _disponible,
                  onChanged: (value) {
                    setState(() {
                      _disponible = value;
                    });
                  },
                  activeColor: Colors.green,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _guardarPlato,
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
                      labelText: 'Buscar plato',
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
          if (_filtroCategoria != 'Todas' || _filtroDisponibilidad != 'Todos')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (_filtroCategoria != 'Todas')
                    Chip(
                      label: Text('Categoría: $_filtroCategoria'),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _filtroCategoria = 'Todas';
                        });
                      },
                    ),
                  if (_filtroDisponibilidad != 'Todos')
                    Chip(
                      label: Text(_filtroDisponibilidad),
                      deleteIcon: const Icon(Icons.close, size: 18),
                      onDeleted: () {
                        setState(() {
                          _filtroDisponibilidad = 'Todos';
                        });
                      },
                    ),
                ],
              ),
            ),

          // Lista de platos
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar datos'));
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No hay platos registrados'));
                }

                Map<dynamic, dynamic> platos = snapshot.data!.snapshot.value as Map;
                List<MapEntry> listaPlatos = platos.entries.toList();

                // Aplicar filtros y ordenamiento
                listaPlatos = _aplicarFiltrosYOrdenamiento(listaPlatos);

                if (listaPlatos.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No se encontraron platos con los filtros seleccionados'),
                      ],
                    ),
                  );
                }

                return _vistaLista 
                    ? _buildListaView(listaPlatos)
                    : _buildGridView(listaPlatos);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListaView(List<MapEntry> listaPlatos) {
    return ListView.builder(
      itemCount: listaPlatos.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final entry = listaPlatos[index];
        final id = entry.key;
        final plato = entry.value;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: plato['disponible'] 
                  ? Colors.green 
                  : Colors.red,
              child: const Icon(Icons.restaurant, color: Colors.white),
            ),
            title: Text(
              plato['nombre'],
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${plato['categoria']} | ${plato['tamano'] ?? 'N/A'}\nS/ ${plato['precio'].toStringAsFixed(2)}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _cargarParaEditar(id, plato),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _eliminarPlato(id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGridView(List<MapEntry> listaPlatos) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.75,
      ),
      itemCount: listaPlatos.length,
      itemBuilder: (context, index) {
        final entry = listaPlatos[index];
        final id = entry.key;
        final plato = entry.value;

        return Card(
          elevation: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: plato['disponible'] ? Colors.green[100] : Colors.red[100],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                  child: Icon(
                    Icons.restaurant,
                    size: 60,
                    color: plato['disponible'] ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plato['nombre'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plato['categoria'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'S/ ${plato['precio'].toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          color: Colors.blue,
                          onPressed: () => _cargarParaEditar(id, plato),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          color: Colors.red,
                          onPressed: () => _eliminarPlato(id),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}