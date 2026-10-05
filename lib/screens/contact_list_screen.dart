
import 'package:flutter/material.dart';

import '../models/contact.dart';
import '../services/contact_storage.dart';
import '../services/tag_storage.dart';
import '../services/export_service.dart';
import '../theme.dart';
import 'import_contacts_screen.dart';
import 'contact_form_screen.dart';


class ContactListScreen extends StatefulWidget {
  const ContactListScreen({super.key});

  @override
  State<ContactListScreen> createState() => _ContactListScreenState();
}

class _ContactListScreenState extends State<ContactListScreen> {
  final _storage = ContactStorage();
  final _tagStorage = TagStorage();

  List<Contact> _contacts = [];
  List<String> _availableTags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final contacts = await _storage.load();
    final tags = await _tagStorage.load();
    _sort(contacts);
    if (!mounted) return;
    setState(() {
      _contacts = contacts;
      _availableTags = tags;
      _loading = false;
    });
  }

  void _sort(List<Contact> list) {
    list.sort((a, b) =>
        a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  }

  Future<void> _persist() => _storage.save(_contacts);

  Future<void> _openForm({Contact? existing}) async {
    final result = await Navigator.push<Contact>(
      context,
      MaterialPageRoute(
        builder: (_) => ContactFormScreen(
          contact: existing,
          availableTags: _availableTags,
        ),
      ),
    );
    if (result == null) return;

    setState(() {
      if (existing == null) {
        _contacts.add(result);
      } else {
        final i = _contacts.indexWhere((c) => c.id == result.id);
        if (i != -1) _contacts[i] = result;
      }
      _sort(_contacts);
    });
    await _persist();

    // The form may have created new tags — reload so the chip list
    // stays in sync across screens.
    final tags = await _tagStorage.load();
    if (mounted) setState(() => _availableTags = tags);
  }

  Future<void> _openImport() async {
    final existingPhones = _contacts
        .where((c) => c.phone.isNotEmpty)
        .map((c) => c.phone.replaceAll(RegExp(r'[^\d+]'), ''))
        .toSet();

    final imported = await Navigator.push<List<Contact>>(
      context,
      MaterialPageRoute(
        builder: (_) => ImportContactsScreen(
          existingPhones: existingPhones,
        ),
      ),
    );

    if (imported == null || imported.isEmpty) return;

    setState(() {
      _contacts.addAll(imported);
      _sort(_contacts);
    });
    await _persist();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: TerminalColors.surfaceHi,
        content: Text(
          '${imported.length} contact${imported.length == 1 ? '' : 's'} imported',
          style: const TextStyle(
            color: TerminalColors.textBright,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Future<void> _exportToClipboard() async {
    if (_contacts.isEmpty) return;
    await ExportService.exportToClipboard(_contacts);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: TerminalColors.surfaceHi,
        content: Text(
          '${_contacts.length} contact${_contacts.length == 1 ? '' : 's'} copied to clipboard',
          style: const TextStyle(
            color: TerminalColors.textBright,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Contact c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TerminalColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
          side: const BorderSide(color: TerminalColors.borderHi),
        ),
        title: const Text(
          'Delete contact?',
          style: TextStyle(fontSize: 15),
        ),
        content: Text(
          'Delete "${c.fullName}" (${c.hexId})?\nThis cannot be undone.',
          style: const TextStyle(
            color: TerminalColors.textDim,
            fontSize: 12.5,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: TerminalColors.textDim),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: TerminalColors.red,
              foregroundColor: TerminalColors.bg,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    setState(() => _contacts.removeWhere((x) => x.id == c.id));
    await _persist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Text('Contacts'),
            const SizedBox(width: 10),
            if (_contacts.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: TerminalColors.borderHi),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${_contacts.length}',
                  style: const TextStyle(
                    color: TerminalColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.upload_outlined, size: 20),
              tooltip: 'Export to clipboard',
              color: TerminalColors.textBright,
              onPressed: _contacts.isEmpty ? null : _exportToClipboard,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.download_outlined, size: 20),
              tooltip: 'Import from phone',
              color: TerminalColors.textBright,
              onPressed: _openImport,
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 1.6,
                  color: TerminalColors.primary,
                ),
              ),
            )
          : _contacts.isEmpty
              ? const _EmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
                  itemCount: _contacts.length,
                  itemBuilder: (context, i) => _ContactTile(
                    contact: _contacts[i],
                    onTap: () => _openForm(existing: _contacts[i]),
                    onDelete: () => _confirmDelete(_contacts[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add, size: 18),
        label: const Text(
          'Add Contact',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(2),
        ),
        backgroundColor: TerminalColors.primary,
        foregroundColor: TerminalColors.bg,
        elevation: 0,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ContactTile({
    required this.contact,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final hasContactLine =
        contact.phone.isNotEmpty || contact.email.isNotEmpty;
    final hasTags = contact.tags.isNotEmpty;
    final hasDescription = contact.description.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: TerminalColors.surface,
        child: InkWell(
          onTap: onTap,
          splashColor: TerminalColors.primary.withOpacity(0.08),
          highlightColor: TerminalColors.primary.withOpacity(0.04),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: TerminalColors.border),
              borderRadius: BorderRadius.circular(2),
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left rail: bracketed initials
                  Container(
                    width: 58,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: TerminalColors.surfaceHi,
                      border: Border(
                        right: BorderSide(color: TerminalColors.border),
                      ),
                    ),
                    child: Text(
                      '[${contact.initials}]',
                      style: const TextStyle(
                        color: TerminalColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  // Middle: identity + fields + tags + description
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  contact.fullName,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: TerminalColors.textBright,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13.5,
                                  ),
                                ),
                              ),
                              Text(
                                contact.hexId,
                                style: const TextStyle(
                                  color: TerminalColors.textDim,
                                  fontSize: 10.5,
                                ),
                              ),
                            ],
                          ),
                          if (hasContactLine) ...[
                            const SizedBox(height: 4),
                            _kv('Phone', contact.phone, TerminalColors.amber),
                            _kv('Email', contact.email, TerminalColors.pink),
                          ],
                          if (hasTags) ...[
                            const SizedBox(height: 8),
                            _TagRow(tags: contact.tags),
                          ],
                          if (hasDescription) ...[
                            const SizedBox(height: 6),
                            Text(
                              contact.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: TerminalColors.textDim,
                                fontSize: 11.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Right: delete
                  SizedBox(
                    width: 40,
                    child: IconButton(
                      iconSize: 16,
                      padding: EdgeInsets.zero,
                      splashRadius: 20,
                      icon: const Icon(Icons.close),
                      color: TerminalColors.textDim,
                      tooltip: 'Delete',
                      onPressed: onDelete,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _kv(String label, String value, Color valueColor) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              label,
              style: const TextStyle(
                color: TerminalColors.textDim,
                fontSize: 11.5,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: valueColor, fontSize: 11.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagRow extends StatelessWidget {
  final List<String> tags;
  const _TagRow({required this.tags});

  @override
  Widget build(BuildContext context) {
    const maxVisible = 4;
    final visible = tags.take(maxVisible).toList();
    final overflow = tags.length - visible.length;

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final t in visible) _MiniTag(label: t),
        if (overflow > 0)
          Text(
            '+$overflow',
            style: const TextStyle(
              color: TerminalColors.textDim,
              fontSize: 11,
            ),
          ),
      ],
    );
  }
}

class _MiniTag extends StatelessWidget {
  final String label;
  const _MiniTag({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TerminalColors.primary.withOpacity(0.10),
        border: Border.all(
          color: TerminalColors.primary.withOpacity(0.35),
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        '#$label',
        style: const TextStyle(
          color: TerminalColors.primary,
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'No contacts yet',
            style: TextStyle(
              color: TerminalColors.textBright,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Tap Add Contact below to create your first one.',
            style: TextStyle(color: TerminalColors.textDim, fontSize: 13),
          ),
          SizedBox(height: 14),
          BlinkingCursor(),
        ],
      ),
    );
  }
}
