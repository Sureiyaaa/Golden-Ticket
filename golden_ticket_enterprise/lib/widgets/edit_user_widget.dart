import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/config.dart';
import 'package:golden_ticket_enterprise/models/hive_session.dart';
import 'package:provider/provider.dart';
import 'package:golden_ticket_enterprise/entities/user.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';

class EditUserWidget extends StatefulWidget {
  final User user;
  final HiveSession session;

  const EditUserWidget({super.key, required this.user, required this.session});

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
  bool _isDisabled = false;
  bool _isTagsDropdownOpen = false;

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
    _isDisabled = widget.user.isDisabled;
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
      _isDisabled, // Make sure your signalRService method accepts this!
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

        String _selectedTagsSummary() {
          int selectedCount = _tagSelectionMap.values.where((v) => v).length;
          if (selectedCount == 0) return 'Assigned Tags';
          return 'Assigned Tags: $selectedCount selected';
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
                  const SizedBox(height: 10),
                  if (_selectedRole != 'Employee')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _isTagsDropdownOpen = !_isTagsDropdownOpen;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedTagsSummary(),
                                  style: TextStyle(fontSize: 16),
                                ),
                                Icon(
                                  _isTagsDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_isTagsDropdownOpen)
                          Container(
                            margin: const EdgeInsets.only(top: 4),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade50,
                            ),
                            child: Column(
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
                          ),
                      ],
                    ),
                  if(widget.user.userID != widget.session.user.userID && widget.user.userID != 100000000)CheckboxListTile(
                    title: const Text("Disabled User"),
                    value: _isDisabled,
                    onChanged: (bool? value) {
                      setState(() {
                        _isDisabled = value ?? false;
                      });
                    },
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
