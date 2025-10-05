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
          
          // Búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscarController,
              decoration: InputDecoration(
                labelText: 'Buscar por razón social o RUC',
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

                // Filtrar por búsqueda
                if (_busqueda.isNotEmpty) {
                  listaProveedores = listaProveedores.where((entry) {
                    String razonSocial = entry.value['razonSocial'].toString().toLowerCase();
                    String ruc = entry.value['ruc'].toString();
                    return razonSocial.contains(_busqueda) || ruc.contains(_busqueda);
                  }).toList();
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