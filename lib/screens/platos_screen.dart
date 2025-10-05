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

  Future<void> _guardarPlato() async {
    if (_nombreController.text.isEmpty || 
        _categoriaController.text.isEmpty ||
        _precioController.text.isEmpty) {
      _mostrarSnackBar('Complete todos los campos requeridos', Colors.red);
      return;
    }

    try {
      final plato = {
        'nombre': _nombreController.text,
        'categoria': _categoriaController.text,
        'tamano': _tamanoController.text,
        'precio': double.tryParse(_precioController.text) ?? 0.0,
        'disponible': _disponible,
      };

      if (_editingId.isEmpty) {
        await _dbRef.push().set(plato);
        _mostrarSnackBar('Plato agregado exitosamente', Colors.green);
      } else {
        await _dbRef.child(_editingId).update(plato);
        _mostrarSnackBar('Plato actualizado exitosamente', Colors.blue);
        _editingId = '';
      }

      _limpiarFormulario();
    } catch (e) {
      _mostrarSnackBar('Error: $e', Colors.red);
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
          
          // Búsqueda
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _buscarController,
              decoration: InputDecoration(
                labelText: 'Buscar plato',
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

                // Filtrar por búsqueda
                if (_busqueda.isNotEmpty) {
                  listaPlatos = listaPlatos.where((entry) {
                    String nombre = entry.value['nombre'].toString().toLowerCase();
                    return nombre.contains(_busqueda);
                  }).toList();
                }

                return ListView.builder(
                  itemCount: listaPlatos.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}