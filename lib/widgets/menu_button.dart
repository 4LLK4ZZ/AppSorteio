import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const MenuButton({
    Key? key,
    required this.label,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Container(
        width: double.maxFinite,
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 30,color: Colors.white),
          label: Text(
            label,
            style: TextStyle(fontSize: 22,
            color: Colors.white,
            fontWeight: FontWeight.bold),
          ),
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: 20),
            backgroundColor: Colors.blue[700],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), // Borda menos arredondada
            ),
          ),
        ),
      ),
    );
  }
}
