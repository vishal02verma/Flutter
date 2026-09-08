import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});

  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  
  bool _isSaving = false;
  Uint8List? _pickedImageBytes;
  String? _editingCategoryId;
  dynamic _existingImageData;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(StateSetter setDialogState) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 400,
        maxHeight: 400,
        imageQuality: 60,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        setDialogState(() => _pickedImageBytes = bytes);
        setState(() => _pickedImageBytes = bytes);
      }
    } catch (e) {
      debugPrint("Picker Error: $e");
    }
  }

  Future<void> _handleSave(BuildContext dialogContext, StateSetter setDialogState) async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_pickedImageBytes == null && _existingImageData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    setDialogState(() => _isSaving = true);
    setState(() => _isSaving = true);

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        throw Exception("Authentication required.");
      }

      String id = _editingCategoryId ?? DateTime.now().millisecondsSinceEpoch.toString();
      
      Map<String, dynamic> categoryData = {
        'id': id,
        'name': _nameController.text.trim(),
        'isActive': true,
      };

      if (_pickedImageBytes != null) {
        categoryData['image'] = Blob(_pickedImageBytes!);
      }

      if (_editingCategoryId == null) {
        categoryData['createdAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection('categories').doc(id).set(categoryData, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(dialogContext).pop(); 
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Category saved successfully!"), backgroundColor: Colors.green),
      );

      _resetForm();

    } catch (e) {
      debugPrint("SAVE ERROR: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setDialogState(() => _isSaving = false);
        setState(() => _isSaving = false);
      }
    }
  }

  void _resetForm() {
    _nameController.clear();
    _pickedImageBytes = null;
    _editingCategoryId = null;
    _existingImageData = null;
    _isSaving = false;
  }

  void _showForm({Map<String, dynamic>? category}) {
    if (category != null) {
      _editingCategoryId = category['id'];
      _nameController.text = category['name'];
      _existingImageData = category['image'];
    } else {
      _resetForm();
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (sheetContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setSheetState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              left: 20, right: 20, top: 20,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category == null ? "Add New Category" : "Edit Category",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                  const SizedBox(height: 20),
                  
                  GestureDetector(
                    onTap: _isSaving ? null : () => _pickImage(setSheetState),
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.brown.shade50,
                      backgroundImage: _getImageProvider(_pickedImageBytes, _existingImageData),
                      child: (_pickedImageBytes == null && _existingImageData == null)
                        ? const Icon(Icons.add_a_photo, size: 40, color: Colors.brown)
                        : null,
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    decoration: const InputDecoration(
                      labelText: "Category Name",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category),
                    ),
                    validator: (val) => val == null || val.isEmpty ? "Enter name" : null,
                  ),
                  
                  const SizedBox(height: 30),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isSaving ? null : () => _handleSave(sheetContext, setSheetState),
                      child: _isSaving 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text("SAVE CATEGORY", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
    );
  }

  ImageProvider? _getImageProvider(Uint8List? pickedBytes, dynamic existingData) {
    if (pickedBytes != null) return MemoryImage(pickedBytes);
    if (existingData == null) return null;
    
    if (existingData is String) return NetworkImage(existingData);
    if (existingData is Blob) return MemoryImage(existingData.bytes);
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;
    final int crossAxisCount = isDesktop ? 4 : 2;

    return Scaffold(
      appBar: AppBar(title: const Text("Category Management")),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showForm(),
        backgroundColor: Colors.brown,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("New Category", style: TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('categories').orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          
          return Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: GridView.builder(
                padding: const EdgeInsets.all(15),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: isDesktop ? 1.2 : 1.1,
                ),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  return Card(
                    clipBehavior: Clip.antiAlias,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: InkWell(
                      onTap: () => _showForm(category: data),
                      child: Stack(
                        children: [
                          _buildImageWidget(data['image']),
                          Container(color: Colors.black38),
                          Center(
                            child: Text(
                              data['name'] ?? "",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Positioned(
                            top: 0, right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _confirmDelete(data['id']),
                            ),
                          )
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImageWidget(dynamic imageData) {
    if (imageData == null) return const Center(child: Icon(Icons.broken_image));
    if (imageData is String) {
      return Image.network(imageData, fit: BoxFit.cover, width: double.infinity, height: double.infinity,
        gaplessPlayback: true,
        errorBuilder: (c, e, s) => const Icon(Icons.broken_image));
    }
    if (imageData is Blob) {
      return Image.memory(imageData.bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity, gaplessPlayback: true);
    }
    return const Center(child: Icon(Icons.broken_image));

  }

  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Category?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              _firestore.collection('categories').doc(id).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
