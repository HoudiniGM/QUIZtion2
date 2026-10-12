import 'package:flutter/material.dart';

/// A dropdown that lists existing options plus a "Criar..." entry. Choosing
/// "Criar..." reveals an inline text field to add a new value; on confirm,
/// [onCreate] is called and should return the created (normalized) value.
///
/// Used to pick/create themes and subtopics (requirements, section 3).
class SelectorWithCreate extends StatefulWidget {
  final String label;
  final String createLabel;
  final List<String> options;
  final String? value;
  final ValueChanged<String?> onSelected;

  /// Called when the user confirms creating a new value. Returns the created
  /// value (which becomes the selection), or null/throws on failure.
  final Future<String?> Function(String name) onCreate;

  final bool enabled;

  const SelectorWithCreate({
    super.key,
    required this.label,
    required this.createLabel,
    required this.options,
    required this.value,
    required this.onSelected,
    required this.onCreate,
    this.enabled = true,
  });

  @override
  State<SelectorWithCreate> createState() => _SelectorWithCreateState();
}

class _SelectorWithCreateState extends State<SelectorWithCreate> {
  static const _createSentinel = '__create__';

  bool _creating = false;
  final _newController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _newController.dispose();
    super.dispose();
  }

  Future<void> _confirmCreate() async {
    final name = _newController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Informe um nome.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final created = await widget.onCreate(name);
      if (!mounted) return;
      setState(() {
        _creating = false;
        _saving = false;
        _newController.clear();
      });
      if (created != null) widget.onSelected(created);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Não foi possível criar. Tente outro nome.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: widget.value,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: widget.label,
            border: const OutlineInputBorder(),
          ),
          items: [
            ...widget.options.map(
              (o) => DropdownMenuItem(value: o, child: Text(o)),
            ),
            DropdownMenuItem(
              value: _createSentinel,
              child: Row(
                children: [
                  const Icon(Icons.add, size: 18),
                  const SizedBox(width: 6),
                  Text(widget.createLabel),
                ],
              ),
            ),
          ],
          onChanged: !widget.enabled
              ? null
              : (v) {
                  if (v == _createSentinel) {
                    setState(() => _creating = true);
                  } else {
                    setState(() => _creating = false);
                    widget.onSelected(v);
                  }
                },
        ),
        if (_creating) ...[
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _newController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: widget.createLabel,
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _confirmCreate(),
                ),
              ),
              const SizedBox(width: 8),
              _saving
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : IconButton.filled(
                      onPressed: _confirmCreate,
                      icon: const Icon(Icons.check),
                      tooltip: 'Confirmar',
                    ),
              IconButton(
                onPressed: _saving
                    ? null
                    : () => setState(() {
                          _creating = false;
                          _error = null;
                          _newController.clear();
                        }),
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar',
              ),
            ],
          ),
        ],
      ],
    );
  }
}
