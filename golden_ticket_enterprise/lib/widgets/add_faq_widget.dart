import 'package:flutter/material.dart';
import 'package:golden_ticket_enterprise/entities/main_tag.dart';
import 'package:golden_ticket_enterprise/models/data_manager.dart';
import 'package:provider/provider.dart';

class AddFAQDialog extends StatefulWidget {
  final Function(String title, String description, String solution, String? mainTag, String? subTag) onSubmit;

  const AddFAQDialog({Key? key, required this.onSubmit}) : super(key: key);

  @override
  State<AddFAQDialog> createState() => _AddFAQDialogState();
}

class _AddFAQDialogState extends State<AddFAQDialog> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController solutionController = TextEditingController();

  String? selectedMainTag;
  String? selectedSubTag;

  @override
  Widget build(BuildContext context) {
    return Consumer<DataManager>(
      builder: (context, dataManager, child) {
        List<MainTag> mainTags = dataManager.mainTags;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.4,
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Add FAQ", style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 16),

                  // Title
                  _buildTextField(titleController, "Title", 1),

                  // Description
                  _buildTextField(descriptionController, "Description", 3),

                  // Solution
                  _buildTextField(solutionController, "Solution", 3),

                  // Main Tag Dropdown
                  _buildDropdown("Select Main Tag", selectedMainTag, mainTags.map((tag) => tag.tagName).toList(), (value) {
                    setState(() {
                      selectedMainTag = value;
                      selectedSubTag = null;
                    });
                  }),

                  // Sub Tag Dropdown
                  _buildDropdown("Select Sub Tag", selectedSubTag, selectedMainTag == null
                      ? []
                      : mainTags
                      .firstWhere((tag) => tag.tagName == selectedMainTag)
                      .subTags
                      .map((subTag) => subTag.subTagName)
                      .toList(), (value) {
                    setState(() {
                      selectedSubTag = value;
                    });
                  }),

                  const SizedBox(height: 20),

                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("Cancel"),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          widget.onSubmit(
                            titleController.text,
                            descriptionController.text,
                            solutionController.text,
                            selectedMainTag,
                            selectedSubTag,
                          );
                          Navigator.pop(context);
                        },
                        child: const Text("Add FAQ"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, int maxLines) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint),
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    );
  }
}