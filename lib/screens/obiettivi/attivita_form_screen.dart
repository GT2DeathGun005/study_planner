import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/attivita.dart';
import '../../providers/attivita_provider.dart';

/// Form per creare o modificare un'Attività.
///
/// Campi: Titolo (obbligatorio) → Numero pomodori → Descrizione.
/// La priorità è ereditata dall'obiettivo padre (mostrata ma non modificabile).
class AttivitaFormScreen extends StatefulWidget {
  final String obiettivoId;
  final Attivita? attivita;

  const AttivitaFormScreen({
    super.key,
    required this.obiettivoId,
    this.attivita,
  });

  @override
  State<AttivitaFormScreen> createState() => _AttivitaFormScreenState();
}

class _AttivitaFormScreenState extends State<AttivitaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloCtrl;
  late final TextEditingController _descrCtrl;
  late final TextEditingController _pomodoroCtrl;
  bool get isEditing => widget.attivita != null;

  @override
  void initState() {
    super.initState();
    final a = widget.attivita;
    _titoloCtrl = TextEditingController(text: a?.titolo ?? '');
    _descrCtrl = TextEditingController(text: a?.descrizione ?? '');
    _pomodoroCtrl = TextEditingController(text: '${a?.pomodoroTotali ?? 1}');
  }

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _descrCtrl.dispose();
    _pomodoroCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica Attività' : 'Nuova Attività'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Titolo
              TextFormField(
                controller: _titoloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titolo *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator:
                    (v) =>
                        v == null || v.trim().isEmpty
                            ? 'Campo obbligatorio'
                            : null,
              ),
              const SizedBox(height: 16),

              // 2. Numero pomodori
              TextFormField(
                controller: _pomodoroCtrl,
                decoration: const InputDecoration(
                  labelText: 'Pomodori',
                  prefixIcon: Icon(Icons.timer),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo obbligatorio';
                  }
                  final n = int.tryParse(v.trim());
                  if (n == null || n < 1) {
                    return 'Inserisci un numero ≥ 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 3. Descrizione (in fondo)
              TextFormField(
                controller: _descrCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descrizione',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),

              // Pulsante salva
              FilledButton.icon(
                onPressed: _save,
                icon: Icon(isEditing ? Icons.save : Icons.add),
                label: Text(isEditing ? 'Salva modifiche' : 'Crea attività'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<AttivitaProvider>();
    final pomodoroTotali = int.tryParse(_pomodoroCtrl.text.trim()) ?? 1;

    if (isEditing) {
      await prov.updateAttivita(
        widget.attivita!.copyWith(
          titolo: _titoloCtrl.text.trim(),
          descrizione: _descrCtrl.text.trim(),
          pomodoroTotali: pomodoroTotali,
        ),
      );
    } else {
      await prov.addAttivita(
        obiettivoId: widget.obiettivoId,
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descrCtrl.text.trim(),
        pomodoroTotali: pomodoroTotali,
      );
    }
    if (mounted) Navigator.pop(context);
  }
}
