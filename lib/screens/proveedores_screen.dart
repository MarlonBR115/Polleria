import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ProveedoresScreen extends StatefulWidget {
  const ProveedoresScreen({super.key});

  @override
  State<ProveedoresScreen> createState() => _ProveedoresScreenState();
}

class _ProveedoresScreenState extends State<ProveedoresScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('proveedores');
  
  final TextEditingController _razonSocialController = TextEditingController();
  final TextEditingController _rucController = TextEditingController();
  final TextEditingController _direccionController = TextEditingController();
  final TextEditingController _contactoController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  final TextEditingController _buscarController = TextEditingController();
  
  String _editingId = '';
  String _busqueda = '';

  // Filtros avanzados
  String _filtroCategoria = 'Todas';
  String _ordenamiento = 'razon_asc';

  final List<String> _categorias = [
    'Carnes',
    'Verduras',
    'Bebidas',
    'Insumos'
  ];

  @override
  void dispose() {
    _razonSocialController.dispose();
    _rucController.dispose();
    _direccionController.dispose();
    _contactoController.dispose();
    _emailController.dispose();
    _categoriaController.dispose();
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
                  
                  // Filtro por categoría
                  const Text('Categoría:', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButtonFormField<String>(
                    value: _filtroCategoria,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: ['Todas', ..._categorias].map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _filtroCategoria = value ?? 'Todas';
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
                      DropdownMenuItem(value: 'razon_asc', child: Text('Razón Social (A-Z)')),
                      DropdownMenuItem(value: 'razon_desc', child: Text('Razón Social (Z-A)')),
                      DropdownMenuItem(value: 'categoria_asc', child: Text('Categoría (A-Z)')),
                    ],
                    onChanged: (value) {
                      setModalState(() {
                        setState(() {
                          _ordenamiento = value ?? 'razon_asc';
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
                              _filtroCategoria = 'Todas';
                              _ordenamiento = 'razon_asc';
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

  List<MapEntry> _aplicarFiltrosYOrdenamiento(List<MapEntry> listaProveedores) {
    // Aplicar filtros
    listaProveedores = listaProveedores.where((entry) {
      bool cumpleCategoria = _filtroCategoria == 'Todas' || 
                             entry.value['categoria'] == _filtroCategoria;
      
      bool cumpleBusqueda = _busqueda.isEmpty ||
                           entry.value['razonSocial'].toString().toLowerCase().contains(_busqueda) ||
                           entry.value['ruc'].toString().contains(_busqueda);
      
      return cumpleCategoria && cumpleBusqueda;
    }).toList();

    // Aplicar ordenamiento
    listaProveedores.sort((a, b) {
      switch (_ordenamiento) {
        case 'razon_asc':
          return a.value['razonSocial'].toString().compareTo(b.value['razonSocial'].toString());
        case 'razon_desc':
          return b.value['razonSocial'].toString().compareTo(a.value['razonSocial'].toString());
        case 'categoria_asc':
          return a.value['categoria'].toString().compareTo(b.value['categoria'].toString());
        default:
          return 0;
      }
    });

    return listaProveedores;
  }

  bool _validarEmail(String email) {
    return RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);
  }

  Future<void> _guardarProveedor() async {
    if (_razonSocialController.text.isEmpty || 
        _rucController.text.isEmpty ||
        _direccionController.text.isEmpty ||
        _contactoController.text.isEmpty ||
        _categoriaController.text.isEmpty) {
      _mostrarSnackBar('Complete todos los campos requeridos', Colors.red);
      return;
    }

    if (_rucController.text.length != 11) {
      _mostrarSnackBar('El RUC debe tener 11 dígitos', Colors.red);
      return;
    }

    if (_emailController.text.isNotEmpty && !_validarEmail(_emailController.text)) {
      _mostrarSnackBar('Email inválido', Colors.red);
      return;
    }

    try {
      final proveedor = {
        'razonSocial': _razonSocialController.text,
        'ruc': _rucController.text,
        'direccion': _direccionController.text,
        'contacto': _contactoController.text,
        'email': _emailController.text,
        'categoria': _categoriaController.text,
      };

      if (_editingId.isEmpty) {
        await _dbRef.push().set(proveedor);
        _mostrarSnackBar('Proveedor agregado exitosamente', Colors.green);
      } else {
        await _dbRef.child(_editingId).update(proveedor);
        _mostrarSnackBar('Proveedor actualizado exitosamente', Colors.blue);
        _editingId = '';
      }

      _limpiarFormulario();
    } catch (e) {
      _mostrarSnackBar('Error: $e', Colors.red);
    }
  }

  Future<void> _eliminarProveedor(String id) async {
    try {
      await _dbRef.child(id).remove();
      _mostrarSnackBar('Proveedor eliminado exitosamente', Colors.orange);
    } catch (e) {
      _mostrarSnackBar('Error al eliminar: $e', Colors.red);
    }
  }

  void _cargarParaEditar(String id, Map<dynamic, dynamic> datos) {
    setState(() {
      _editingId = id;
      _razonSocialController.text = datos['razonSocial'] ?? '';
      _rucController.text = datos['ruc'] ?? '';
      _direccionController.text = datos['direccion'] ?? '';
      _contactoController.text = datos['contacto'] ?? '';
      _emailController.text = datos['email'] ?? '';
      _categoriaController.text = datos['categoria'] ?? '';
    });
  }

  void _limpiarFormulario() {
    _razonSocialController.clear();
    _rucController.clear();
    _direccionController.clear();
    _contactoController.clear();
    _emailController.clear();
    _categoriaController.clear();
    setState(() {
      _editingId = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Proveedores'),
        backgroundColor: Colors.orange[700],
        elevation: 0,
      ),
      body: Column(
        children: [
          // Formulario
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: _razonSocialController,
                    decoration: const InputDecoration(
                      labelText: 'Razón Social *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _rucController,
                          keyboardType: TextInputType.number,
                          maxLength: 11,
                          decoration: const InputDecoration(
                            labelText: 'RUC *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.numbers),
                            counterText: '',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<String>(
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _direccionController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contactoController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Contacto (Teléfono) *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _guardarProveedor,
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
                      labelText: 'Buscar por razón social o RUC',
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
          if (_filtroCategoria != 'Todas')
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text('Categoría: $_filtroCategoria'),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _filtroCategoria = 'Todas';
                      });
                    },
                  ),
                ],
              ),
            ),

          // Lista de proveedores
          Expanded(
            child: StreamBuilder(
              stream: _dbRef.onValue,
              builder: (context, AsyncSnapshot<DatabaseEvent> snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Error al cargar datos'));
                }
                if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                  return const Center(child: Text('No hay proveedores registrados'));
                }

                Map<dynamic, dynamic> proveedores = snapshot.data!.snapshot.value as Map;
                List<MapEntry> listaProveedores = proveedores.entries.toList();

                // Aplicar filtros y ordenamiento
                listaProveedores = _aplicarFiltrosYOrdenamiento(listaProveedores);

                if (listaProveedores.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No se encontraron proveedores con los filtros seleccionados'),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: listaProveedores.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final entry = listaProveedores[index];
                    final id = entry.key;
                    final proveedor = entry.value;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.orange[700],
                          child: const Icon(Icons.local_shipping, color: Colors.white),
                        ),
                        title: Text(
                          proveedor['razonSocial'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'RUC: ${proveedor['ruc']}\n${proveedor['categoria']} | ${proveedor['contacto']}\n${proveedor['direccion']}',
                        ),
                        isThreeLine: true,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _cargarParaEditar(id, proveedor),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _eliminarProveedor(id),
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