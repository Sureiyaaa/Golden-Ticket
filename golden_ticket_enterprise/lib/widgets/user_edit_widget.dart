import 'package:flutter/material.dart';

class EditUserPopup extends StatefulWidget {
  final String adminName;
  final String adminEmail;
  final String adminRole;
  final Function(String name, String email, String role) onSave;

  const EditUserPopup({
    Key? key,
    required this.adminName,
    required this.adminEmail,
    required this.adminRole,
    required this.onSave,
  }) : super(key: key);

  @override
  _EditUserPopupState createState() => _EditUserPopupState();
}

class _EditUserPopupState extends State<EditUserPopup> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  String? selectedRole;

  final List<String> roles = ["Admin", "Moderator", "Viewer"];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.adminName);
    _emailController = TextEditingController(text: widget.adminEmail);
    selectedRole = widget.adminRole;
  }

  void _save() {
    if (_nameController.text.isNotEmpty && _emailController.text.isNotEmpty) {
      widget.onSave(_nameController.text, _emailController.text, selectedRole!);
      Navigator.pop(context); // Close the popup after saving
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Admin"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Name"),
          ),
          SizedBox(height: 10),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(labelText: "Email"),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: InputDecoration(labelText: "Role"),
            items: roles.map((role) {
              return DropdownMenuItem(value: role, child: Text(role));
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedRole = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _save,
          child: Text("Save"),
        ),
      ],
    );
  }
}
