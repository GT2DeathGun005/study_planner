import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/obiettivo.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';
import '../../providers/obiettivo_provider.dart';

/// Form per creare o modificare un Obiettivo/Task.
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
  late final TextEditingController _tempoCtrl;
  late final TextEditingController _noteCtrl;
  late String _priorita;
  String? _corsoId;
  String? _esameId;
  DateTime? _dataPianificata;
  DateTime? _dataScadenza;
  bool get isEditing => widget.obiettivo != null;

  @override
  void initState() {
    super.initState();
    final o = widget.obiettivo;
    _titoloCtrl = TextEditingController(text: o?.titolo ?? '');
    _descrCtrl = TextEditingController(text: o?.descrizione ?? '');
    _tempoCtrl = TextEditingController(text: '${o?.tempoStimato ?? 0}');
    _noteCtrl = TextEditingController(text: o?.note ?? '');
    _priorita = o?.priorita ?? 'media';
    _corsoId = o?.corsoId;
    _esameId = o?.esameId;
    _dataPianificata = o?.dataPianificata ?? widget.dataPianificata;
    _dataScadenza = o?.dataScadenza;
  }

  @override
  void dispose() {
    _titoloCtrl.dispose();
    _descrCtrl.dispose();
    _tempoCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corsi = context.watch<CorsoProvider>().tuttiCorsi;
    final esami = context.watch<EsameProvider>().esami;
    final df = DateFormat('dd MMM yyyy', 'it_IT');
    final esamiFilt = _corsoId != null
        ? esami.where((e) => e.corsoId == _corsoId).toList()
        : esami;

    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Modifica Obiettivo' : 'Nuovo Obiettivo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titoloCtrl,
                decoration: const InputDecoration(labelText: 'Titolo *', prefixIcon: Icon(Icons.title)),
                validator: (v) => v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _descrCtrl, decoration: const InputDecoration(labelText: 'Descrizione', prefixIcon: Icon(Icons.description), alignLabelWithHint: true), maxLines: 3),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _corsoId,
                decoration: const InputDecoration(labelText: 'Corso (opzionale)', prefixIcon: Icon(Icons.book)),
                items: [const DropdownMenuItem(value: null, child: Text('Nessun corso')), ...corsi.map((c) => DropdownMenuItem(value: c.id, child: Text(c.nome)))],
                onChanged: (v) => setState(() { _corsoId = v; _esameId = null; }),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _esameId,
                decoration: const InputDecoration(labelText: 'Esame (opzionale)', prefixIcon: Icon(Icons.quiz)),
                items: [const DropdownMenuItem(value: null, child: Text('Nessun esame')), ...esamiFilt.map((e) => DropdownMenuItem(value: e.id, child: Text(e.titolo)))],
                onChanged: (v) => setState(() => _esameId = v),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(initialValue: _priorita, decoration: const InputDecoration(labelText: 'Priorità', prefixIcon: Icon(Icons.priority_high)), items: Obiettivo.prioritaDisponibili.map((p) => DropdownMenuItem(value: p, child: Text(Obiettivo.prioritaLabel(p)))).toList(), onChanged: (v) { if (v != null) setState(() => _priorita = v); })),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(controller: _tempoCtrl, decoration: const InputDecoration(labelText: 'Tempo stimato (min)', prefixIcon: Icon(Icons.timer)), keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 16),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.event), title: const Text('Data pianificata'), subtitle: Text(_dataPianificata != null ? df.format(_dataPianificata!) : 'Non impostata'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (_dataPianificata != null) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _dataPianificata = null)), const Icon(Icons.chevron_right)]), onTap: () async { final d = await showDatePicker(context: context, initialDate: _dataPianificata ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => _dataPianificata = d); }),
              ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.alarm), title: const Text('Scadenza'), subtitle: Text(_dataScadenza != null ? df.format(_dataScadenza!) : 'Non impostata'), trailing: Row(mainAxisSize: MainAxisSize.min, children: [if (_dataScadenza != null) IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () => setState(() => _dataScadenza = null)), const Icon(Icons.chevron_right)]), onTap: () async { final d = await showDatePicker(context: context, initialDate: _dataScadenza ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030)); if (d != null) setState(() => _dataScadenza = d); }),
              const SizedBox(height: 16),
              TextFormField(controller: _noteCtrl, decoration: const InputDecoration(labelText: 'Note', prefixIcon: Icon(Icons.notes), alignLabelWithHint: true), maxLines: 2),
              const SizedBox(height: 32),
              FilledButton.icon(onPressed: _save, icon: Icon(isEditing ? Icons.save : Icons.add), label: Text(isEditing ? 'Salva modifiche' : 'Crea obiettivo'), style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
            ],
          ),
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<ObiettivoProvider>();
    final ts = int.tryParse(_tempoCtrl.text) ?? 0;
    if (isEditing) {
      prov.updateObiettivo(widget.obiettivo!.copyWith(titolo: _titoloCtrl.text.trim(), descrizione: _descrCtrl.text.trim(), corsoId: _corsoId, clearCorsoId: _corsoId == null, esameId: _esameId, clearEsameId: _esameId == null, priorita: _priorita, tempoStimato: ts, dataPianificata: _dataPianificata, clearDataPianificata: _dataPianificata == null, dataScadenza: _dataScadenza, clearDataScadenza: _dataScadenza == null, note: _noteCtrl.text.trim()));
    } else {
      prov.addObiettivo(titolo: _titoloCtrl.text.trim(), descrizione: _descrCtrl.text.trim(), corsoId: _corsoId, esameId: _esameId, priorita: _priorita, tempoStimato: ts, dataPianificata: _dataPianificata, dataScadenza: _dataScadenza, note: _noteCtrl.text.trim());
    }
    Navigator.pop(context);
  }
}
