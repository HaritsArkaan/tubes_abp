import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dotted_border/dotted_border.dart';
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
    AwesomeDialog(
      context: context,
      dialogType: DialogType.question,
      animType: AnimType.scale,
      title: 'Save Changes?',
      desc: 'Do you want to save this snack?',
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
    AwesomeDialog(
      context: context,
      dialogType: DialogType.success,
      animType: AnimType.scale,
      title: 'Success!',
      desc: 'Snack saved successfully!',
      btnOkText: 'OK',
      btnOkColor: const Color(0xFF4CAF50),
      btnOkOnPress: () {
        Navigator.pop(context);
      },
    ).show();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Color(0xFF2E3E5C),
              size: 16,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: const Text(
          'Add new',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.5),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _imageFile != null
                    ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(
                    _imageFile!,
                    height: 180,
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
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.cloud_upload_outlined,
                          size: 32,
                          color: Color(0xFFBDBDBD),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add photos of snacks here',
                          style: TextStyle(
                            color: Color(0xFFBDBDBD),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildInputField(
                'Name of snacks',
                _nameController,
                '0/100',
                'Add name of snacks here',
              ),
              const SizedBox(height: 24),
              const Text(
                'Snack prices',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2E3E5C),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _priceOptions.map((price) => _buildPriceChip(price)).toList(),
                  ),
                  const SizedBox(height: 8),
                  _buildCustomPriceInput(),
                ],
              ),
              const SizedBox(height: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _typeOptions.map((type) => _buildTypeChip(type)).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildInputField(
                'Address',
                _addressController,
                '0/100',
                'Add address here',
              ),
              const SizedBox(height: 24),
              _buildInputField(
                'Contact',
                _contactController,
                '0/100',
                'Add contact here',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _showConfirmationDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save',
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