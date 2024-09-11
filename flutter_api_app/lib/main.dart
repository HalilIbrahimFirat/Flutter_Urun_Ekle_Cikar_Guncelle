import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter API App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<dynamic> _products = [];
  bool _isLoading = true;
  String _errorMessage = '';
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  int? _editingProductId; // Düzenlenen ürünün ID'si

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response =
          await http.get(Uri.parse('http://10.0.2.2:3000/api/products'));

      if (response.statusCode == 200) {
        setState(() {
          _products = json.decode(response.body);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Ürünler Yüklenemedi: ${response.reasonPhrase}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _addProduct(String name, String price) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:3000/api/products'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'price': price,
        }),
      );

      if (response.statusCode == 201) {
        _fetchProducts(); // Yeni ürün eklendikten sonra ürünleri tekrar getir.
      } else {
        setState(() {
          _errorMessage = 'Ürün Eklenemedi: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProduct(int id, String name, String price) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.put(
        Uri.parse('http://10.0.2.2:3000/api/products/$id'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'price': price,
        }),
      );

      if (response.statusCode == 200) {
        _fetchProducts(); // Ürün güncellendikten sonra ürünleri tekrar getir.
        setState(() {
          _editingProductId = null; // Güncelleme modundan çık
        });
      } else {
        setState(() {
          _errorMessage = 'Ürün Güncellenemedi: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProduct(int productId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await http.delete(
        Uri.parse('http://10.0.2.2:3000/api/products/$productId'),
      );

      if (response.statusCode == 200) {
        _fetchProducts(); // Ürün silindikten sonra ürünleri tekrar getir.
      } else {
        setState(() {
          _errorMessage = 'Ürün Silinemedi: ${response.reasonPhrase}';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _editProduct(dynamic product) {
    setState(() {
      _editingProductId = product['id'];
      _nameController.text = product['name'];
      _priceController.text = product['price'].toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ÜRÜNLER'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'ÜRÜN ADI',
                            ),
                          ),
                          TextField(
                            controller: _priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ÜRÜN FİYATI',
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (_nameController.text.isNotEmpty &&
                                  _priceController.text.isNotEmpty) {
                                if (_editingProductId == null) {
                                  // Yeni ürün ekleme
                                  _addProduct(
                                    _nameController.text,
                                    _priceController.text,
                                  );
                                } else {
                                  // Ürün güncelleme
                                  _updateProduct(
                                    _editingProductId!,
                                    _nameController.text,
                                    _priceController.text,
                                  );
                                }
                                _nameController.clear();
                                _priceController.clear();
                              }
                            },
                            child: Text(_editingProductId == null
                                ? 'ÜRÜN EKLE'
                                : 'ÜRÜN GÜNCELLE'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return ListTile(
                            title: Text(product['name']),
                            subtitle: Text('FİYAT: ₺${product['price']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit,
                                      color: Colors.orange),
                                  onPressed: () {
                                    _editProduct(product);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () {
                                    _deleteProduct(product['id']);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
    );
  }
}
