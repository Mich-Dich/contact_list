
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;

import '../models/contact.dart';
import '../theme.dart';


/// Shows the phone's contact list with checkboxes. On finish, returns
/// the list of selected contacts (already mapped to our Contact model).
class ImportContactsScreen extends StatefulWidget {
  /// IDs (or phone numbers) that already exist in our app, so we can
  /// pre-disable obvious duplicates.
  final Set<String> existingPhones;

  const ImportContactsScreen({super.key, required this.existingPhones});

  @override
  State<ImportContactsScreen> createState() => _ImportContactsScreenState();
}

class _ImportContactsScreenState extends State<ImportContactsScreen> {
  bool _loading = true;
  bool _permissionDenied = false;
  String? _error;

  /// All device contacts, mapped to our model.
  List<Contact> _deviceContacts = [];

  /// Which ones the user ticked.
  final Set<String> _selectedIds = {};

  @override
  void initState() {
    super.initState();
    _loadDeviceContacts();
  }

  Future<void> _loadDeviceContacts() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
      _error = null;
    });

    try {
      // 1. Ask for READ_CONTACTS.
      final status = await fc.FlutterContacts.permissions
          .request(fc.PermissionType.read);

      if (status != fc.PermissionStatus.granted &&
          status != fc.PermissionStatus.limited) {
        if (!mounted) return;
        setState(() {
          _loading = false;
          _permissionDenied = true;
        });
        return;
      }

      // 2. Fetch everything with the fields we care about.
      final deviceContacts = await fc.FlutterContacts.getAll(
        properties: {
          fc.ContactProperty.name,
          fc.ContactProperty.phone,
          fc.ContactProperty.email,
        },
      );

      // 3. Map to our model.
      final mapped = deviceContacts.map((dc) {
        final name = dc.name;

        final first = name?.first?.trim() ?? '';
        final middle = name?.middle?.trim() ?? '';
        final last = name?.last?.trim() ?? '';
        final display = dc.displayName?.trim() ?? '';

        // Reassemble the name the way the phone's own contact app shows it:
        //   "given middle family" → firstName = "given middle", lastName = "family"
        // Falls back to the raw display string if the structured fields are empty
        // (company contacts, imported vCards, etc.).
        String firstName;
        String lastName;

        if (first.isNotEmpty || last.isNotEmpty) {
          firstName = [first, middle].where((s) => s.isNotEmpty).join(' ');
          lastName = last;
        } else if (display.isNotEmpty) {
          firstName = display;
          lastName = '';
        } else {
          firstName = '';
          lastName = '';
        }

        final phone =
            dc.phones.isNotEmpty ? dc.phones.first.number.trim() : '';
        final email =
            dc.emails.isNotEmpty ? dc.emails.first.address.trim() : '';

        return Contact(
          firstName: firstName,
          lastName: lastName,
          phone: phone,
          email: email,
        );
      }).where((c) {
        // Drop entries with no name and no phone — nothing to import.
        return c.fullName != '(no name)' || c.phone.isNotEmpty;
      }).toList();

      // 4. Sort alphabetically (same as main list).
      mapped.sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));

      if (!mounted) return;
      setState(() {
        _deviceContacts = mapped;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  bool _isDuplicate(Contact c) {
    if (c.phone.isEmpty) return false;
    return widget.existingPhones.contains(_normalizePhone(c.phone));
  }

  String _normalizePhone(String raw) {
    return raw.replaceAll(RegExp(r'[^\d+]'), '');
  }

  void _toggle(Contact c) {
    setState(() {
      if (_selectedIds.contains(c.id)) {
        _selectedIds.remove(c.id);
      } else {
        _selectedIds.add(c.id);
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectedIds.addAll(
        _deviceContacts.where((c) => !_isDuplicate(c)).map((c) => c.id),
      );
    });
  }

  void _clearSelection() {
    setState(() => _selectedIds.clear());
  }

  void _finish() {
    final picked =
        _deviceContacts.where((c) => _selectedIds.contains(c.id)).toList();
    Navigator.pop(context, picked);
  }

  @override
  Widget build(BuildContext context) {
    final importable = _deviceContacts.where((c) => !_isDuplicate(c)).length;
    final duplicates = _deviceContacts.length - importable;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            const Text('Import Contacts'),
            const SizedBox(width: 10),
            if (_selectedIds.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(color: TerminalColors.borderHi),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  '${_selectedIds.length}',
                  style: const TextStyle(
                    color: TerminalColors.primary,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        actions: [
          if (!_loading && !_permissionDenied && _deviceContacts.isNotEmpty)
            PopupMenuButton<String>(
              color: TerminalColors.surface,
              icon: const Icon(Icons.more_vert, size: 18),
              onSelected: (v) {
                if (v == 'all') _selectAll();
                if (v == 'none') _clearSelection();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'all',
                  child: Text('Select all importable',
                      style: TextStyle(fontSize: 12.5)),
                ),
                PopupMenuItem(
                  value: 'none',
                  child: Text('Clear selection',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ],
            ),
        ],
      ),
      body: _buildBody(importable, duplicates),
      bottomNavigationBar: _loading || _permissionDenied
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                decoration: const BoxDecoration(
                  border: Border(
                    top: BorderSide(color: TerminalColors.border),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} selected',
                        style: const TextStyle(
                          color: TerminalColors.textDim,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    FilledButton(
                      onPressed:
                          _selectedIds.isEmpty ? null : _finish,
                      style: FilledButton.styleFrom(
                        backgroundColor: TerminalColors.primary,
                        foregroundColor: TerminalColors.bg,
                        disabledBackgroundColor: TerminalColors.surfaceHi,
                        disabledForegroundColor: TerminalColors.textDim,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 22, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      child: const Text(
                        'Finish Import',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBody(int importable, int duplicates) {
    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1.6,
            color: TerminalColors.primary,
          ),
        ),
      );
    }

    if (_permissionDenied) {
      return _Message(
        title: 'Permission denied',
        body:
            'This app needs read access to your contacts to import them.\n'
            'You can enable it in Settings → Apps → Contact List → Permissions.',
        actionLabel: 'Try again',
        onAction: _loadDeviceContacts,
      );
    }

    if (_error != null) {
      return _Message(
        title: 'Could not read contacts',
        body: _error!,
        actionLabel: 'Retry',
        onAction: _loadDeviceContacts,
      );
    }

    if (_deviceContacts.isEmpty) {
      return const _Message(
        title: 'No contacts found',
        body: 'Your phone\'s contact list is empty.',
      );
    }

    return Column(
      children: [
        // Status strip, matching the terminal vibe.
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(color: TerminalColors.border),
            ),
          ),
          child: Text(
            '$importable importable'
            '${duplicates > 0 ? '  ·  $duplicates already in list' : ''}',
            style: const TextStyle(
              color: TerminalColors.textDim,
              fontSize: 11.5,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            itemCount: _deviceContacts.length,
            itemBuilder: (context, i) {
              final c = _deviceContacts[i];
              final dup = _isDuplicate(c);
              final selected = _selectedIds.contains(c.id);

              return _ImportTile(
                contact: c,
                isDuplicate: dup,
                isSelected: selected,
                onChanged: dup ? null : () => _toggle(c),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────

class _ImportTile extends StatelessWidget {
  final Contact contact;
  final bool isDuplicate;
  final bool isSelected;
  final VoidCallback? onChanged;

  const _ImportTile({
    required this.contact,
    required this.isDuplicate,
    required this.isSelected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final subtitle = [
      if (contact.phone.isNotEmpty) contact.phone,
      if (contact.email.isNotEmpty) contact.email,
    ].join('  ·  ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Opacity(
        opacity: isDuplicate ? 0.45 : 1.0,
        child: Material(
          color: isSelected
              ? TerminalColors.surfaceHi
              : TerminalColors.surface,
          child: InkWell(
            onTap: onChanged,
            splashColor: TerminalColors.primary.withOpacity(0.08),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isSelected
                      ? TerminalColors.primary
                      : TerminalColors.border,
                ),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Row(
                children: [
                  // Checkbox column
                  SizedBox(
                    width: 46,
                    child: Center(
                      child: Checkbox(
                        value: isSelected,
                        onChanged: onChanged == null
                            ? null
                            : (_) => onChanged!(),
                        side: const BorderSide(
                          color: TerminalColors.borderHi,
                          width: 1.2,
                        ),
                        activeColor: TerminalColors.primary,
                        checkColor: TerminalColors.bg,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ),
                  // Divider
                  Container(
                    width: 1,
                    height: 42,
                    color: TerminalColors.border,
                  ),
                  // Body
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            contact.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: TerminalColors.textBright,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: TerminalColors.textDim,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                          if (isDuplicate) ...[
                            const SizedBox(height: 3),
                            const Text(
                              'already imported',
                              style: TextStyle(
                                color: TerminalColors.amber,
                                fontSize: 10.5,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ],
                        ],
                      ),
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
}

class _Message extends StatelessWidget {
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: TerminalColors.textBright,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                color: TerminalColors.textDim,
                fontSize: 12.5,
                height: 1.5,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 18),
              OutlinedButton(
                onPressed: onAction,
                style: OutlinedButton.styleFrom(
                  foregroundColor: TerminalColors.primary,
                  side: const BorderSide(color: TerminalColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
