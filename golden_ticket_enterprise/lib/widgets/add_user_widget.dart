import 'package:flutter/material.dart';

class AddUserWidget extends StatefulWidget {
  final String? adminName;
  final String? adminEmail;
  final String? adminRole;
  final Function(String name, String email, String role) onSave;

  const AddUserWidget({
    Key? key,
    this.adminName,
    this.adminEmail,
    this.adminRole,
    required this.onSave,
  }) : super(key: key);

  @override
  _AddUserWidgetState createState() => _AddUserWidgetState();
}

class _AddUserWidgetState extends State<AddUserWidget> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? selectedRole;

  final List<String> roles = ["Admin", "Agent/Staff", "Employee"];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.adminName ?? "";
    _emailController.text = widget.adminEmail ?? "";
    selectedRole = widget.adminRole ?? roles.first;
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
      title: Text(widget.adminName == null ? "Add Admin" : "Edit Admin"),
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
