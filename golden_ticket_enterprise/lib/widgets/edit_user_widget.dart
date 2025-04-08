import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/config.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';

class EditUserWidget extends StatefulWidget {
  final User user;

  const EditUserWidget({super.key, required this.user});

  @override
  _EditUserWidgetState createState() => _EditUserWidgetState();
}

class _EditUserWidgetState extends State<EditUserWidget> {
  late TextEditingController _usernameController;
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  String? _selectedRole;
  Map<String, bool> _tagSelectionMap = {};
  bool _isSaving = false;

  List<String> get selectedTags => _selectedRole != 'Employee'
      ? _tagSelectionMap.entries.where((e) => e.value).map((e) => e.key).toList()
      : [];

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.user.username);
    _firstNameController.text = widget.user.firstName;
    _middleNameController.text = widget.user.middleName ?? '';
    _lastNameController.text = widget.user.lastName;
    _selectedRole = widget.user.role;
  }

  Future<void> _initializeTags(DataManager dataManager) async {
    final mainTags = dataManager.mainTags;
    final userTags = widget.user.assignedTags ?? [];

    setState(() {
      for (var tag in mainTags) {
        _tagSelectionMap[tag.tagName] = userTags.contains(tag.tagName);
      }
    });
  }

  void _saveUser(BuildContext context, DataManager dataManager) async {
    if (_firstNameController.text.isEmpty ||
        _lastNameController.text.isEmpty ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all required fields.")),
      );
      return;
    }

    setState(() => _isSaving = true);

    final password = _passwordController.text.isEmpty ? "" : _passwordController.text;

    dataManager.signalRService.updateUser(
      widget.user.userID,
      widget.user.username,
      password,
      _firstNameController.text,
      _middleNameController.text,
      _lastNameController.text,
      _selectedRole!,
      selectedTags,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, _) {
        if (_tagSelectionMap.isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _initializeTags(dataManager);
          });
        }

        return AlertDialog(
          title: const Text("Edit User"),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _usernameController,
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'Username'),
                  ),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New Password (optional, leave empty to keep current)',
                    ),
                  ),
                  TextField(
                    controller: _firstNameController,
                    decoration: const InputDecoration(labelText: 'First Name *'),
                  ),
                  TextField(
                    controller: _middleNameController,
                    decoration: const InputDecoration(labelText: 'Middle Name (optional)'),
                  ),
                  TextField(
                    controller: _lastNameController,
                    decoration: const InputDecoration(labelText: 'Last Name *'),
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    hint: const Text('Select Role *'),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedRole = newValue;
                      });
                    },
                    items: rolesData.map((role) {
                      return DropdownMenuItem<String>(
                        value: role,
                        child: Text(role),
                      );
                    }).toList(),
                  ),
                  if (_selectedRole != 'Employee')
                    Column(
                      children: dataManager.mainTags.map((tag) {
                        return CheckboxListTile(
                          title: Text(tag.tagName),
                          value: _tagSelectionMap[tag.tagName] ?? false,
                          onChanged: (bool? value) {
                            setState(() {
                              _tagSelectionMap[tag.tagName] = value ?? false;
                            });
                          },
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: _isSaving ? null : () => _saveUser(context, dataManager),
              child: _isSaving
                  ? const SizedBox(
                  width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text("Save Changes"),
            ),
          ],
        );
      },
    );
  }
}
