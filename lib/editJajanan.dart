import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dotted_border/dotted_border.dart';
import 'dart:io';
import 'models/snack.dart';
import 'config.dart'; // For base URL

// Import the SnackItem class from jajananku.dart
import 'jajananku.dart' show SnackItem;

class EditSnackDialog extends StatefulWidget {
  final Snack snack;
  final Function(Snack) onSave;

  const EditSnackDialog({
    Key? key,
    required this.snack,
    required this.onSave,
  }) : super(key: key);

  @override
  State<EditSnackDialog> createState() => _EditSnackDialogState();
}

class _EditSnackDialogState extends State<EditSnackDialog> {
  late TextEditingController _nameController;
  late TextEditingController _customPriceController;
  late TextEditingController _addressController;
  late TextEditingController _contactController;
  File? _imageFile;
  late String _selectedType;
  String _selectedPrice = '';
  final ImagePicker _picker = ImagePicker();

  final List<String> _priceOptions = ['5000', '7000', '10000', '15000'];
  final List<String> _typeOptions = ['Food', 'Drink', 'Dessert', 'Snack'];

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing data
    _nameController = TextEditingController(text: widget.snack.name);
    _customPriceController = TextEditingController(text: widget.snack.price.toString());
    _addressController = TextEditingController(text: widget.snack.location ?? "");
    _contactController = TextEditingController(text: widget.snack.contact ?? "");
    _selectedType = widget.snack.type;

    // Check if the price matches any predefined options
    String priceString = widget.snack.price.toStringAsFixed(0);
    if (_priceOptions.contains(priceString)) {
      _selectedPrice = priceString;
      _customPriceController.clear();
    }
  }

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
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Save Changes?',
      desc: 'Do you want to save the changes to this snack?',
      btnCancelText: 'Cancel',
      btnOkText: 'Save',
      btnCancelColor: Colors.grey,
      btnOkColor: const Color(0xFF4CAF50),
      btnCancelOnPress: () {},
      btnOkOnPress: () {
        _saveSnack();
      },
    ).show();
  }

  void _saveSnack() {
    // Validate required fields
    if (_nameController.text.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Error',
        desc: 'Please enter a name for the snack',
        btnOkOnPress: () {},
        btnOkColor: Colors.red,
      ).show();
      return;
    }

    if (_selectedType.isEmpty) {
      AwesomeDialog(
        context: context,
        dialogType: DialogType.error,
        animType: AnimType.scale,
        title: 'Error',
        desc: 'Please select a type for the snack',
        btnOkOnPress: () {},
        btnOkColor: Colors.red,
      ).show();
      return;
    }

    // Prepare image data if a new image was selected
    String imageBase64 = '';
    if (_imageFile != null) {
      try {
        final bytes = _imageFile!.readAsBytesSync();
        imageBase64 = base64Encode(bytes);
      } catch (e) {
        print('Error encoding image: $e');
        // Continue without updating the image
      }
    }

    // Create updated snack item
    double price;
    if (_selectedPrice.isNotEmpty) {
      price = double.parse(_selectedPrice);
    } else if (_customPriceController.text.isNotEmpty) {
      price = double.parse(_customPriceController.text);
    } else {
      price = widget.snack.price; // Keep original if nothing selected
    }

    final updatedSnack = Snack(
      id: widget.snack.id,
      name: _nameController.text,
      imageUrl: widget.snack.imageUrl, // Keep original URL
      image: imageBase64, // Add base64 image if available
      price: price,
      type: _selectedType,
      location: _addressController.text,
      rating: widget.snack.rating, // Keep original rating
      contact: _contactController.text,
      seller: widget.snack.seller, // Keep original seller
      userId: widget.snack.userId, // Keep original userId
    );

    // Call the onSave callback
    widget.onSave(updatedSnack);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Snack',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Image picker
              GestureDetector(
                onTap: _pickImage,
                child: _imageFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _imageFile!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                )
                    : DottedBorder(
                  borderType: BorderType.RRect,
                  radius: const Radius.circular(16),
                  color: Colors.grey.withOpacity(0.3),
                  strokeWidth: 1,
                  dashPattern: const [6, 3],
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: NetworkImage(
                          widget.snack.imageUrl.isNotEmpty
                              ? AppConfig.baseUrl + widget.snack.imageUrl
                              : 'https://via.placeholder.com/150',
                        ),
                        fit: BoxFit.cover,
                        onError: (exception, stackTrace) {
                          print('Error loading image: $exception');
                        },
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.edit,
                              size: 32,
                              color: Colors.white,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Change Image',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Name field
              _buildInputField(
                'Name of snacks',
                _nameController,
                '${_nameController.text.length}/100',
                'Add name of snacks here',
              ),
              const SizedBox(height: 20),

              // Price options
              const Text(
                'Snack prices',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _priceOptions.map((price) => _buildPriceChip(price)).toList(),
              ),
              const SizedBox(height: 8),
              _buildCustomPriceInput(),
              const SizedBox(height: 20),

              // Type selection
              const Text(
                'Type',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose the type that describes your snack!',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _typeOptions.map((type) => _buildTypeChip(type)).toList(),
              ),
              const SizedBox(height: 20),

              // Address field
              _buildInputField(
                'Address',
                _addressController,
                '${_addressController.text.length}/100',
                'Add address here',
              ),
              const SizedBox(height: 20),

              // Contact field
              _buildInputField(
                'Contact',
                _contactController,
                '${_contactController.text.length}/100',
                'Add contact here',
              ),
              const SizedBox(height: 24),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
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
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E3E5C),
              ),
            ),
            Text(
              counter,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                color: Color(0xFF9E9E9E),
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
              filled: true,
              fillColor: const Color(0xFFE8F5E9),
            ),
            onChanged: (value) {
              // Force a rebuild to update the counter
              setState(() {});
            },
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
      backgroundColor: const Color(0xFFE8F5E9),
      selectedColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4CAF50),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : const Color(0xFF4CAF50),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  Widget _buildCustomPriceInput() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: _customPriceController,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          hintText: 'Enter another nominal here',
          hintStyle: TextStyle(
            color: Color(0xFF9E9E9E),
            fontSize: 14,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          filled: true,
          fillColor: Color(0xFFE8F5E9),
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
      backgroundColor: const Color(0xFFE8F5E9),
      selectedColor: const Color(0xFF4CAF50),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF4CAF50),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.transparent : const Color(0xFF4CAF50),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
    );
  }
}
