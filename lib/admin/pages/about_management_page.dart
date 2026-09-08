import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AboutManagementPage extends StatefulWidget {
  const AboutManagementPage({super.key});

  @override
  State<AboutManagementPage> createState() => _AboutManagementPageState();
}

class _AboutManagementPageState extends State<AboutManagementPage> {
  final _storyController = TextEditingController();
  final _visionController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAboutData();
  }

  Future<void> _loadAboutData() async {
    final doc = await FirebaseFirestore.instance.collection('info').doc('about').get();
    if (doc.exists) {
      setState(() {
        _storyController.text = doc.data()?['story'] ?? '';
        _visionController.text = doc.data()?['vision'] ?? '';
      });
    }
  }

  Future<void> _saveAboutData() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('info').doc('about').set({
        'story': _storyController.text.trim(),
        'vision': _visionController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("About Us updated!"), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool isDesktop = size.width > 900;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage About Us"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? size.width * 0.15 : 20,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Our Story", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _storyController,
                        maxLines: isDesktop ? 12 : 8,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        decoration: InputDecoration(
                          hintText: "Tell your customers about your bakery's history...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.brown, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 30),
                      const Text("Our Vision & Mission", 
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown)),
                      const SizedBox(height: 15),
                      TextField(
                        controller: _visionController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        decoration: InputDecoration(
                          hintText: "What are your goals?...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.brown, width: 2)),
                        ),
                      ),
                      const SizedBox(height: 40),
                      _isLoading 
                        ? const Center(child: CircularProgressIndicator(color: Colors.brown)) 
                        : SizedBox(
                            width: double.infinity,
                            height: 55,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.brown,
                                elevation: 5,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              onPressed: _saveAboutData, 
                              child: const Text("UPDATE ABOUT US", 
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18))),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 50),
            ],
          ),
        ),
      ),
    );
  }
}
