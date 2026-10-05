
import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../services/tag_storage.dart';
import '../theme.dart';


class ContactFormScreen extends StatefulWidget {
  final Contact? contact;
  final List<String> availableTags;

  const ContactFormScreen({
    super.key,
    this.contact,
    this.availableTags = const [],
  });

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tagStorage = TagStorage();

  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _description;

  /// Union of tags handed in from the list screen + any the user
  /// adds right here. Kept sorted case-insensitively.
  late List<String> _allTags;
  late Set<String> _selectedTags;

  bool get _isEditing => widget.contact != null;

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    _firstName = TextEditingController(text: c?.firstName ?? '');
    _lastName = TextEditingController(text: c?.lastName ?? '');
    _phone = TextEditingController(text: c?.phone ?? '');
    _email = TextEditingController(text: c?.email ?? '');
    _description = TextEditingController(text: c?.description ?? '');

    _allTags = List<String>.from(widget.availableTags);
    _selectedTags = {...(c?.tags ?? const <String>[])};

    // Ensure any tag already attached to this contact shows in the list
    // even if the global tag list was edited elsewhere.
    for (final t in _selectedTags) {
      if (!_allTags.any((x) => x.toLowerCase() == t.toLowerCase())) {
        _allTags.add(t);
      }
    }
    _sortTags();
  }

  void _sortTags() {
    _allTags.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  }

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    _phone.dispose();
    _email.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final base = widget.contact ?? Contact();
    final result = base.copyWith(
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      description: _description.text.trim(),
      tags: _selectedTags.toList(),
    );
    Navigator.pop(context, result);
  }

  void _toggleTag(String tag) {
    setState(() {
      if (_selectedTags.contains(tag)) {
        _selectedTags.remove(tag);
      } else {
        _selectedTags.add(tag);
      }
    });
  }

  Future<void> _addNewTag() async {
    final controller = TextEditingController();

    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TerminalColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: TerminalColors.borderHi),
        ),
        title: const Text('New tag', style: TextStyle(fontSize: 15)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          style: const TextStyle(color: TerminalColors.textBright),
          cursorColor: TerminalColors.primary,
          decoration: const InputDecoration(
            hintText: 'e.g. Neighbors',
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancel',
              style: TextStyle(color: TerminalColors.textDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TerminalColors.primary,
              foregroundColor: TerminalColors.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (raw == null) return;
    final name = raw.trim();
    if (name.isEmpty) return;

    // Case-insensitive dedupe — if it already exists, just select it.
    final existing = _allTags.firstWhere(
      (t) => t.toLowerCase() == name.toLowerCase(),
      orElse: () => '',
    );

    if (existing.isEmpty) {
      setState(() {
        _allTags.add(name);
        _sortTags();
        _selectedTags.add(name);
      });
      await _tagStorage.save(_allTags);
    } else {
      setState(() => _selectedTags.add(existing));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Text(_isEditing ? 'Edit Contact' : 'New Contact'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.keyboard_return, size: 18),
              tooltip: 'Save',
              color: TerminalColors.primary,
              onPressed: _save,
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            const _SectionLabel('Name'),
            _Field(
              controller: _firstName,
              label: 'First name',
              hint: 'Ada',
              icon: Icons.person_outline,
              capitalization: TextCapitalization.words,
              validator: (v) {
                final firstOk = (v ?? '').trim().isNotEmpty;
                final lastOk = _lastName.text.trim().isNotEmpty;
                if (!firstOk && !lastOk) {
                  return 'Enter at least a first or last name';
                }
                return null;
              },
            ),
            _Field(
              controller: _lastName,
              label: 'Last name',
              hint: 'Lovelace',
              icon: Icons.badge_outlined,
              capitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            const _SectionLabel('Contact details'),
            _Field(
              controller: _phone,
              label: 'Phone',
              hint: '+49 123 456789',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
            ),
            _Field(
              controller: _email,
              label: 'Email',
              hint: 'name@example.com',
              icon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                final value = (v ?? '').trim();
                if (value.isEmpty) return null;
                final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                    .hasMatch(value);
                return ok ? null : 'Enter a valid email address';
              },
            ),
            const SizedBox(height: 12),
            const _SectionLabel('Tags'),
            _TagPicker(
              tags: _allTags,
              selected: _selectedTags,
              onToggle: _toggleTag,
              onAddNew: _addNewTag,
            ),
            const SizedBox(height: 18),
            const _SectionLabel('Description'),
            TextFormField(
              controller: _description,
              maxLines: 5,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(
                color: TerminalColors.textBright,
                fontSize: 13.5,
                height: 1.45,
              ),
              cursorColor: TerminalColors.primary,
              cursorWidth: 2,
              cursorRadius: const Radius.circular(0),
              decoration: const InputDecoration(
                hintText: 'Notes, context, how you met…',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(
                backgroundColor: TerminalColors.primary,
                foregroundColor: TerminalColors.bg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              child: Text(
                _isEditing ? 'Save Changes' : 'Add Contact',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: const [BlinkingCursor(height: 12)],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _TagPicker extends StatelessWidget {
  final List<String> tags;
  final Set<String> selected;
  final void Function(String) onToggle;
  final VoidCallback onAddNew;

  const _TagPicker({
    required this.tags,
    required this.selected,
    required this.onToggle,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final tag in tags)
          _Chip(
            label: '#$tag',
            selected: selected.contains(tag),
            onTap: () => onToggle(tag),
          ),
        _Chip(
          label: '+ New tag',
          selected: false,
          accent: true,
          onTap: onAddNew,
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = accent
        ? TerminalColors.textDim
        : (selected ? TerminalColors.primary : TerminalColors.textDim);

    final bgColor = selected
        ? TerminalColors.primary.withOpacity(0.14)
        : TerminalColors.surface;

    final borderColor = selected
        ? TerminalColors.primary
        : (accent ? TerminalColors.borderHi : TerminalColors.border);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: TerminalColors.primary.withOpacity(0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: baseColor,
              fontSize: 12,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          color: TerminalColors.textDim,
          fontSize: 10.5,
          letterSpacing: 1.6,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization capitalization;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.capitalization = TextCapitalization.none,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        autocorrect: false,
        style: const TextStyle(
          color: TerminalColors.textBright,
          fontSize: 13.5,
        ),
        cursorColor: TerminalColors.primary,
        cursorWidth: 2,
        cursorRadius: const Radius.circular(0),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 16, color: TerminalColors.textDim),
          prefixIconConstraints:
              const BoxConstraints(minWidth: 40, minHeight: 0),
        ),
        validator: validator,
      ),
    );
  }
}
