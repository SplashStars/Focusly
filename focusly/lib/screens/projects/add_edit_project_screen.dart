// ─────────────────────────────────────────────────────────────────────────────
// Add/Edit Project Screen
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/project_model.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_theme.dart';

class AddEditProjectScreen extends StatefulWidget {
  final ProjectModel? project;

  const AddEditProjectScreen({super.key, this.project});

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  int _selectedColor = ProjectColors.colorValues[0];
  String _selectedIcon = 'folder';
  bool _isSaving = false;

  bool get _isEditing => widget.project != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.project!;
      _nameController.text = p.name;
      _selectedColor = p.colorValue;
      _selectedIcon = p.iconName;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final previewColor = Color(_selectedColor);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(_isEditing ? 'Edit Project' : 'New Project'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        actions: [
          _isSaving
              ? const Padding(padding: EdgeInsets.all(16), child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold)))
              : TextButton(
                  onPressed: _save,
                  child: const Text('Save', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, fontSize: 16)),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: previewColor.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: previewColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(ProjectIcons.getIcon(_selectedIcon), color: previewColor, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      _nameController.text.isEmpty ? 'Project Preview' : _nameController.text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildLabel('Project Name *'),
              TextFormField(
                controller: _nameController,
                autofocus: !_isEditing,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: const InputDecoration(hintText: 'e.g. Work, Personal, Health...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a project name' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              _buildLabel('Color'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ProjectColors.colorValues.map((c) {
                  final isSelected = _selectedColor == c;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(c),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 3) : null,
                        boxShadow: isSelected ? [BoxShadow(color: Color(c).withOpacity(0.6), blurRadius: 8, spreadRadius: 2)] : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              _buildLabel('Icon'),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: ProjectIcons.icons.length,
                itemBuilder: (context, index) {
                  final entry = ProjectIcons.icons.entries.elementAt(index);
                  final isSelected = _selectedIcon == entry.key;
                  final pColor = Color(_selectedColor);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        color: isSelected ? pColor.withOpacity(0.2) : AppColors.surface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? pColor : AppColors.surfaceHighlight),
                      ),
                      child: Icon(entry.value, size: 22, color: isSelected ? pColor : AppColors.textMuted),
                    ),
                  );
                },
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final provider = context.read<ProjectProvider>();

      if (_isEditing) {
        await provider.updateProject(
          widget.project!.copyWith(
            name: _nameController.text.trim(),
            colorValue: _selectedColor,
            iconName: _selectedIcon,
          ),
        );
      } else {
        await provider.addProject(
          name: _nameController.text.trim(),
          colorValue: _selectedColor,
          iconName: _selectedIcon,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
