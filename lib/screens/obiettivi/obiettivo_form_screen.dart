import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/obiettivo.dart';
import '../../providers/corso_provider.dart';
import '../../providers/obiettivo_provider.dart';

/// Form per creare o modificare un Obiettivo.
///
/// Ordine campi: Titolo → Data pianificata → Corso → Priorità → Descrizione.
class ObiettivoFormScreen extends StatefulWidget {
  final Obiettivo? obiettivo;
  final DateTime? dataPianificata;
  const ObiettivoFormScreen({super.key, this.obiettivo, this.dataPianificata});
  @override
  State<ObiettivoFormScreen> createState() => _ObiettivoFormScreenState();
}

class _ObiettivoFormScreenState extends State<ObiettivoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloCtrl;
  late final TextEditingController _descrCtrl;
  late String _priorita;
  String? _corsoId;
  DateTime? _dataPianificata;
  bool get isEditing => widget.obiettivo != null;

  @override
  void initState() {
    super.initState();
    final o = widget.obiettivo;
    _titoloCtrl = TextEditingController(text: o?.titolo ?? '');
    _descrCtrl = TextEditingController(text: o?.descrizione ?? '');
    _priorita = o?.priorita ?? 'media';
    _corsoId = o?.corsoId;
    _dataPianificata = o?.dataPianificata ?? widget.dataPianificata;
  }

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _descrCtrl.dispose();
    super.dispose();
  }

  String _getFormattedDate(DateTime date) {
    final raw = DateFormat('dd MMM yyyy', 'it_IT').format(date);
    // Capitalizza la prima lettera del mese
    final parts = raw.split(' ');
    if (parts.length >= 2) {
      parts[1] = parts[1][0].toUpperCase() + parts[1].substring(1);
    }
    return parts.join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final corsi = context.watch<CorsoProvider>().tuttiCorsi;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica Obiettivo' : 'Nuovo Obiettivo'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titolo
              TextFormField(
                controller: _titoloCtrl,
                decoration: const InputDecoration(
                  labelText: 'Titolo *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo obbligatorio';
                  }
                  final trimmed = v.trim().toLowerCase();
                  final exists = context
                      .read<ObiettivoProvider>()
                      .tuttiObiettivi
                      .any(
                        (o) =>
                            o.titolo.trim().toLowerCase() == trimmed &&
                            o.id != widget.obiettivo?.id,
                      );
                  if (exists) {
                    return 'Esiste già un obiettivo con questo titolo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Data pianificata 
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Data pianificata'),
                subtitle: Text(
                  _dataPianificata != null
                      ? _getFormattedDate(_dataPianificata!)
                      : 'Non impostata',
                ),
                trailing: SizedBox(
                  width: 80,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_dataPianificata != null)
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed:
                                () => setState(() => _dataPianificata = null),
                          ),
                        ),
                      const Icon(Icons.chevron_right),
                    ],
                  ),
                ),
                onTap: () async {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final initial = _dataPianificata ?? today;
                  final first = initial.isBefore(today) ? initial : today;
                  
                  final d = await showDatePicker(
                    context: context,
                    initialDate: initial,
                    firstDate: first,
                    lastDate: DateTime(2030),
                    locale: const Locale('it', 'IT'),
                  );
                  if (d != null) setState(() => _dataPianificata = d);
                },
              ),
              const Divider(),
              const SizedBox(height: 16),

              // Corso
              DropdownButtonFormField<String>(
                initialValue: _corsoId,
                decoration: const InputDecoration(
                  labelText: 'Corso',
                  prefixIcon: Icon(Icons.book),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Nessun corso'),
                  ),
                  ...corsi.map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.nome)),
                  ),
                ],
                onChanged: (v) => setState(() => _corsoId = v),
              ),
              const SizedBox(height: 16),

              // Priorità
              DropdownButtonFormField<String>(
                initialValue: _priorita,
                decoration: const InputDecoration(
                  labelText: 'Priorità',
                  prefixIcon: Icon(Icons.priority_high),
                ),
                items:
                    Obiettivo.prioritaDisponibili
                        .map(
                          (p) => DropdownMenuItem(
                            value: p,
                            child: Text(Obiettivo.prioritaLabel(p)),
                          ),
                        )
                        .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _priorita = v);
                },
              ),
              const SizedBox(height: 16),

              // Descrizione 
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
                label: Text(isEditing ? 'Salva modifiche' : 'Crea obiettivo'),
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<ObiettivoProvider>();
    if (isEditing) {
      prov.updateObiettivo(
        widget.obiettivo!.copyWith(
          titolo: _titoloCtrl.text.trim(),
          descrizione: _descrCtrl.text.trim(),
          corsoId: _corsoId,
          clearCorsoId: _corsoId == null,
          priorita: _priorita,
          dataPianificata: _dataPianificata,
          clearDataPianificata: _dataPianificata == null,
        ),
      );
    } else {
      prov.addObiettivo(
        titolo: _titoloCtrl.text.trim(),
        descrizione: _descrCtrl.text.trim(),
        corsoId: _corsoId,
        priorita: _priorita,
        dataPianificata: _dataPianificata,
      );
    }
    Navigator.pop(context);
  }
}
