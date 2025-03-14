import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddSnackPage extends StatefulWidget {
  const AddSnackPage({Key? key}) : super(key: key);

  @override
  State<AddSnackPage> createState() => _AddSnackPageState();
}

class _AddSnackPageState extends State<AddSnackPage> {
  final _nameController = TextEditingController();
  final _customPriceController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  File? _imageFile;
  String _selectedType = '';
  String _selectedPrice = '';
  final ImagePicker _picker = ImagePicker();

  final List<String> _priceOptions = ['5.000', '7.000', '10.000', '15.000'];
  final List<String> _typeOptions = ['Food', 'Drink', 'Dessert', 'Snack'];

  @override
  void dispose() {
    _nameController.dispose();
    _customPriceController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Are you sure?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E3E5C),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Yes button
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // Add save logic here
                          _saveSnack();
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'Yes, save',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // No button
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.red.shade100,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          'No',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveSnack() {
    // Implement save logic here
    debugPrint('Saving snack...');
    // You can add API call or database operation here

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Snack saved successfully!'),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Navigate back
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFD1E7D1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E3E5C),
              size: 16,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Add new',
          style: TextStyle(
            color: Colors.green,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image upload area
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    // Base container
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: _imageFile != null
                          ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.file(
                          _imageFile!,
                          fit: BoxFit.cover,
                        ),
                      )
                          : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 40,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add photos of snacks here',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Dashed border overlay
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: _imageFile == null ? _buildDashedBorder() : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Name input
              _buildInputField(
                'Name of snacks',
                _nameController,
                '0/100',
                'Add name of snacks here',
              ),
              const SizedBox(height: 20),

              // Price options
              const Text(
                'Snack prices',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  ..._priceOptions.map((price) => _buildPriceChip(price)),
                  _buildCustomPriceInput(),
                ],
              ),
              const SizedBox(height: 20),

              // Type selection
              const Text(
                'Type',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Choose the type that describes your snack!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _typeOptions
                    .map((type) => _buildTypeChip(type))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Address input
              _buildInputField(
                'Address',
                _addressController,
                '0/100',
                'Add address here',
              ),
              const SizedBox(height: 20),

              // Contact input
              _buildInputField(
                'Contact',
                _contactController,
                '0/100',
                'Add contact here',
              ),
              const SizedBox(height: 30),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxBorder _buildDashedBorder() {
    return Border.all(
      color: Colors.grey.withOpacity(0.5),
      width: 2,
    );
  }

  Widget _buildInputField(
      String label,
      TextEditingController controller,
      String counter,
      String hint,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E3E5C),
              ),
            ),
            Text(
              counter,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceChip(String price) {
    final isSelected = _selectedPrice == price;
    return ChoiceChip(
      label: Text('Rp $price'),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedPrice = selected ? price : '';
          if (selected) {
            _customPriceController.clear();
          }
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.green.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildCustomPriceInput() {
    return Container(
      width: 150,
      height: 32,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: _customPriceController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Enter another nominal here',
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 12,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty) {
            setState(() {
              _selectedPrice = '';
            });
          }
        },
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      label: Text(type),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedType = selected ? type : '';
        });
      },
      backgroundColor: Colors.white,
      selectedColor: Colors.green.shade100,
      labelStyle: TextStyle(
        color: isSelected ? Colors.green.shade700 : Colors.grey.shade600,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
    );
  }
}

