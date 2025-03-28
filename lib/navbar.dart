import 'package:flutter/material.dart';

class NavBar extends StatefulWidget {
  final int selectedIndex;
  final Function(int)? onItemSelected;

  const NavBar({
    Key? key,
    this.selectedIndex = 0,
    this.onItemSelected,
  }) : super(key: key);

  @override
  _NavBarState createState() => _NavBarState();
}

class _NavBarState extends State<NavBar> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.selectedIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
      widget.onItemSelected?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      height: 60 + bottomPadding, // Kurangi tinggi navbar
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8BC34A),
            Color(0xFF689F38),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.only(bottom: bottomPadding), // Tambahkan padding minimal
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home'),
              _buildNavItem(1, Icons.add_circle_outline, Icons.add_circle, 'Add'),
              _buildNavItem(2, Icons.favorite_border, Icons.favorite, 'Favorite'),
              _buildNavItem(3, Icons.photo_library_outlined, Icons.photo_library, 'Review'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: SizedBox(
        width: 70,
        height: 55, // Kurangi tinggi item
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 2,
              width: 24,
              margin: const EdgeInsets.only(bottom: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2), // Kurangi padding
              child: Icon(
                isSelected ? activeIcon : icon,
                color: Colors.white,
                size: 20, // Kurangi ukuran icon
              ),
            ),
            Flexible( // Gunakan Flexible agar teks tidak overflow
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9, // Kurangi ukuran font
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
