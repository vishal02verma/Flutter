import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProductManagementPage extends StatefulWidget {
  const ProductManagementPage({super.key});

  @override
  State<ProductManagementPage> createState() => _ProductManagementPageState();
}

class _ProductManagementPageState extends State<ProductManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();

  String? _selectedCategory;
  bool _isFeatured = false;
  bool _isUploading = false;
  Uint8List? _selectedImage;
  dynamic _existingImageData;
  String? _editingProductId;

  Future<void> _pickImage(StateSetter setDialogState) async {
    try {
      final picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 400, 
        maxHeight: 400, 
        imageQuality: 60
      );
      if (image != null) {
        final bytes = await image.readAsBytes();
        setDialogState(() => _selectedImage = bytes);
        setState(() => _selectedImage = bytes);
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  Future<void> _saveProduct(StateSetter setDialogState) async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategory == null ||
        (_selectedImage == null && _existingImageData == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill all required fields")));
      return;
    }

    setDialogState(() => _isUploading = true);
    setState(() => _isUploading = true);

    try {
      String id = _editingProductId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      Map<String, dynamic> productData = {
        'id': id,
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'price': double.parse(_priceController.text),
        'category': _selectedCategory,
        'stock': int.parse(_stockController.text),
        'isFeatured': _isFeatured,
        'isAvailable': true,
      };

      if (_selectedImage != null) {
        productData['image'] = Blob(_selectedImage!);
      }

      if (_editingProductId == null) {
        productData['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('products').doc(id).set(productData, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.pop(context);
      _clearForm();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Product saved successfully!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) {
        setDialogState(() => _isUploading = false);
        setState(() => _isUploading = false);
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descController.clear();
    _priceController.clear();
    _stockController.clear();
    setState(() {
      _selectedImage = null;
      _existingImageData = null;
      _selectedCategory = null;
      _isFeatured = false;
      _editingProductId = null;
    });
  }

  void _showProductForm({Map<String, dynamic>? product}) {
    if (product != null) {
      _editingProductId = product['id'];
      _nameController.text = product['name'];
      _descController.text = product['description'] ?? "";
      _priceController.text = product['price'].toString();
      _stockController.text = product['stock'].toString();
      _selectedCategory = product['category'];
      _isFeatured = product['isFeatured'] ?? false;
      _existingImageData = product['image'];
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(product == null ? "Add New Product" : "Edit Product"),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _pickImage(setDialogState),
                    child: Container(
                      height: 150, width: double.infinity,
                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(15)),
                      child: _selectedImage != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.memory(_selectedImage!, fit: BoxFit.cover))
                          : (_existingImageData != null
                              ? ClipRRect(borderRadius: BorderRadius.circular(15), child: _buildImageWidget(_existingImageData))
                              : const Icon(Icons.add_a_photo, size: 50, color: Colors.brown)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Product Name")),
                  TextField(controller: _descController, decoration: const InputDecoration(labelText: "Description")),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: _priceController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Price"))),
                      const SizedBox(width: 10),
                      Expanded(child: TextField(controller: _stockController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Stock"))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('categories').snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) return const LinearProgressIndicator();
                        var items = snapshot.data!.docs.map((doc) => doc['name'].toString()).toList();
                        if (items.isEmpty) return const Text("Add category first", style: TextStyle(color: Colors.red));
                        return DropdownButtonFormField<String>(
                          hint: const Text("Select Category"),
                          value: _selectedCategory,
                          isExpanded: true,
                          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (val) => setDialogState(() => _selectedCategory = val),
                        );
                      }),
                  SwitchListTile(
                    title: const Text("Featured Product"),
                    value: _isFeatured,
                    onChanged: (val) => setDialogState(() => _isFeatured = val),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: () => _saveProduct(setDialogState), child: const Text("SAVE")),
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(dynamic imageData) {
    if (imageData == null) return const Icon(Icons.broken_image);
    if (imageData is String) return Image.network(imageData, fit: BoxFit.cover, gaplessPlayback: true, errorBuilder: (c,e,s) => const Icon(Icons.broken_image));
    if (imageData is Blob) return Image.memory(imageData.bytes, fit: BoxFit.cover, gaplessPlayback: true);
    return const Icon(Icons.broken_image);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 1024;

    return Scaffold(
      appBar: AppBar(title: const Text("Product Management")),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.brown,
        onPressed: () => _showProductForm(),
        label: const Text("Add Product", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('products').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;

          if (isDesktop) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columnSpacing: size.width * 0.05,
                          columns: const [
                            DataColumn(label: Text('Image', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DataRow(cells: [
                              DataCell(SizedBox(width: 40, height: 40, child: _buildImageWidget(data['image']))),
                              DataCell(Text(data['name'] ?? "")),
                              DataCell(Text(data['category'] ?? "")),
                              DataCell(Text('₹${data['price']}')),
                              DataCell(Text(data['stock'].toString())),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductForm(product: data)),
                                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(data['id'])),
                                ],
                              )),
                            ]);
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: SizedBox(
                    width: 60, height: 60,
                    child: ClipRRect(borderRadius: BorderRadius.circular(8), child: _buildImageWidget(data['image'])),
                  ),
                  title: Text(data['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${data['category']} • ₹${data['price']}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductForm(product: data)),
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _confirmDelete(data['id'])),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Delete Product?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              _firestore.collection('products').doc(id).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
