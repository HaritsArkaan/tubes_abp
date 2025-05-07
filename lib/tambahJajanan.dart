import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'dart:convert';
import 'services/api_snack.dart';
import 'models/snack.dart';

class AddSnackPage extends StatefulWidget {
  const AddSnackPage({Key? key}) : super(key: key);

  @override
  State<AddSnackPage> createState() => _AddSnackPageState();
}

class _AddSnackPageState extends State<AddSnackPage> {
  final _nameController = TextEditingController();
  final _customPriceController = TextEditingController();
  final _sellerController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  File? _imageFile;
  String _selectedType = '';
  String _selectedPrice = '';
  final ImagePicker _picker = ImagePicker();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  final List<String> _priceOptions = ['5000', '7000', '10000', '15000'];
  final List<String> _typeOptions = ['Food', 'Drink', 'Dessert', 'Snack'];

  @override
  void dispose() {
    _nameController.dispose();
    _customPriceController.dispose();
    _sellerController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
                        SizedBox(width: 10),
                        Text('Gallery'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
                        SizedBox(width: 10),
                        Text('Camera'),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImage(ImageSource.camera);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmationDialog() {
    if (_nameController.text.isEmpty) {
      _showErrorDialog('Please enter a name for the snack');
      return;
    }

    if (_selectedType.isEmpty) {
      _showErrorDialog('Please select a type for the snack');
      return;
    }

    if (_selectedPrice.isEmpty && _customPriceController.text.isEmpty) {
      _showErrorDialog('Please select or enter a price for the snack');
      return;
    }

    if (_sellerController.text.isEmpty) {
      _showErrorDialog('Please enter a seller name');
      return;
    }

    if (_addressController.text.isEmpty) {
      _showErrorDialog('Please enter an address');
      return;
    }

    if (_contactController.text.isEmpty) {
      _showErrorDialog('Please enter contact information');
      return;
    }

    if (_imageFile == null) {
      _showErrorDialog('Please select an image for the snack');
      return;
    }

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

  void _showErrorDialog(String message) {
    AwesomeDialog(
      context: context,
      dialogType: DialogType.error,
      animType: AnimType.scale,
      title: 'Error',
      desc: message,
      btnOkText: 'OK',
      btnOkColor: Colors.red,
      btnOkOnPress: () {},
    ).show();
  }

  void _showLoadingDialog() {
    setState(() {
      _isLoading = true;
    });
  }

  void _hideLoadingDialog() {
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _saveSnack() async {
    _showLoadingDialog();

    try {
      // Get user token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('jwt_token');
      final userId = prefs.getInt('user_id');

      if (token == null || userId == null) {
        _hideLoadingDialog();
        _showErrorDialog('You need to be logged in to add a snack');
        return;
      }

      // Get the price value
      final price = _selectedPrice.isNotEmpty
          ? _selectedPrice
          : _customPriceController.text;

      // Convert price string to double
      double priceValue;
      try {
        // Remove any non-numeric characters except decimal point
        final cleanPrice = price.replaceAll(RegExp(r'[^\d.]'), '');
        priceValue = double.parse(cleanPrice);
      } catch (e) {
        _hideLoadingDialog();
        _showErrorDialog('Invalid price format');
        return;
      }

      // Create a base64 string from the image file
      final bytes = await _imageFile!.readAsBytes();
      final base64Image = base64Encode(bytes);

      // Create a Snack object
      final snack = Snack(
        id: 0, // ID will be assigned by the server
        name: _nameController.text,
        price: priceValue,
        type: _selectedType,
        location: _addressController.text,
        seller: _sellerController.text,
        contact: _contactController.text,
        image: base64Image,
        userId: userId,
        rating: 0, imageUrl: '',  // This will be initialized by the server
      );

      // Call the API to add the snack
      final addedSnack = await _apiService.addSnack(snack, token);

      _hideLoadingDialog();

      // Show success dialog
      AwesomeDialog(
        context: context,
        dialogType: DialogType.success,
        animType: AnimType.scale,
        title: 'Success!',
        desc: 'Snack saved successfully!',
        btnOkText: 'OK',
        btnOkColor: const Color(0xFF4CAF50),
        btnOkOnPress: () {
          Navigator.pop(context, addedSnack); // Return the added snack to the previous screen
        },
      ).show();
    } catch (e) {
      _hideLoadingDialog();
      _showErrorDialog('Failed to save snack: $e');
      debugPrint('Error saving snack: $e');
    }
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
      body: Stack(
        children: [
          Container(
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
                    onTap: _showImageSourceDialog,
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
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
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
                    'Seller',
                    _sellerController,
                    '0/100',
                    'Add seller name here',
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
                      onPressed: _isLoading ? null : _showConfirmationDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                          : const Text(
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
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
        ],
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
