import 'package:flutter/material.dart';

class CategoryAddDialog {
  final BuildContext _context;
  final TextEditingController _addCategoryTextController;

  CategoryAddDialog(this._context, {TextEditingController? addCategoryTextController}) :
    _addCategoryTextController = addCategoryTextController ?? TextEditingController();

  void dispose() {
    _addCategoryTextController.dispose();
  }

  Future<String?> openCategoryAddDialog() => showDialog<String>(
    context: _context,
    builder: (context) => AlertDialog(
      title: const Text(r'Enter new category name'),
      content: TextField(
        autofocus: true,
        autocorrect: true,
        decoration: const InputDecoration(hintText: r'Category name'),
        controller: _addCategoryTextController,
        onSubmitted: (_) => _submitText(),
      ),
      actions: [
        TextButton(
          onPressed: _submitText,
          child: const Text(r'Add category'),
        )
      ]
    ),
  );

  void _submitText() {
    Navigator.of(_context).pop(_addCategoryTextController.text);
    _addCategoryTextController.clear();
  }
}
