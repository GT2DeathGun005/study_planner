import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/esame.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';

/// Schermata per creare o modificare un Esame.
///
/// Se viene passato un [esame] esistente, pre-compila i campi per la modifica.
/// Il [corsoId] può essere passato per pre-selezionare il corso associato.
class EsameFormScreen extends StatefulWidget {
  final Esame? esame;
  final String? corsoId;

  const EsameFormScreen({super.key, this.esame, this.corsoId});

  @override
  State<EsameFormScreen> createState() => _EsameFormScreenState();
}

class _EsameFormScreenState extends State<EsameFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titoloController;
  late final TextEditingController _noteController;
  late final TextEditingController _votoController;
  late String? _corsoId;
  late DateTime _data;
  late String _tipologia;
  late String _priorita;
  late String _stato;

  bool get isEditing => widget.esame != null;

  @override
  void initState() {
    super.initState();
    final e = widget.esame;
    _titoloController = TextEditingController(text: e?.titolo ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _votoController =
        TextEditingController(text: e?.voto?.toString() ?? '');
    _corsoId = e?.corsoId ?? widget.corsoId;
    _data = e?.data ?? DateTime.now().add(const Duration(days: 7));
    _tipologia = e?.tipologia ?? 'scritto';
    _priorita = e?.priorita ?? 'media';
    _stato = e?.stato ?? 'programmato';
  }

  @override
  void dispose() {
    _titoloController.dispose();
    _noteController.dispose();
    _votoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final corsi = context.watch<CorsoProvider>().tuttiCorsi;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica Esame' : 'Nuovo Esame'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Titolo
              TextFormField(
                controller: _titoloController,
                decoration: const InputDecoration(
                  labelText: 'Titolo *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Corso associato
              DropdownButtonFormField<String>(
                initialValue: _corsoId,
                decoration: const InputDecoration(
                  labelText: 'Corso associato *',
                  prefixIcon: Icon(Icons.book),
                ),
                items: corsi.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.nome));
                }).toList(),
                onChanged: (v) => setState(() => _corsoId = v),
                validator: (v) => v == null ? 'Seleziona un corso' : null,
              ),
              const SizedBox(height: 16),

              // Data
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Data'),
                subtitle:
                    Text(DateFormat('dd MMMM yyyy', 'it_IT').format(_data)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
              const Divider(),

              // Tipologia e Priorità
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _tipologia,
                      decoration: const InputDecoration(
                        labelText: 'Tipologia',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: Esame.tipologieDisponibili.map((t) {
                        return DropdownMenuItem(
                          value: t,
                          child: Text(Esame.tipologiaLabel(t)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _tipologia = v);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _priorita,
                      decoration: const InputDecoration(
                        labelText: 'Priorità',
                        prefixIcon: Icon(Icons.priority_high),
                      ),
                      items: Esame.prioritaDisponibili.map((p) {
                        return DropdownMenuItem(
                          value: p,
                          child: Text(Esame.prioritaLabel(p)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _priorita = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stato
              DropdownButtonFormField<String>(
                initialValue: _stato,
                decoration: const InputDecoration(
                  labelText: 'Stato',
                  prefixIcon: Icon(Icons.flag),
                ),
                items: Esame.statiDisponibili.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(Esame.statoLabel(s)),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _stato = v);
                },
              ),
              const SizedBox(height: 16),

              // Voto (opzionale)
              TextFormField(
                controller: _votoController,
                decoration: const InputDecoration(
                  labelText: 'Voto (opzionale)',
                  prefixIcon: Icon(Icons.grade),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final n = int.tryParse(v);
                    if (n == null || n < 0 || n > 30) {
                      return 'Valore 0-30';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Pulsante salva
              FilledButton.icon(
                onPressed: _save,
                icon: Icon(isEditing ? Icons.save : Icons.add),
                label: Text(isEditing ? 'Salva modifiche' : 'Crea esame'),
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

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _data = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EsameProvider>();
    final voto = int.tryParse(_votoController.text);

    if (isEditing) {
      final updated = widget.esame!.copyWith(
        titolo: _titoloController.text.trim(),
        corsoId: _corsoId!,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: voto,
        clearVoto: _votoController.text.isEmpty,
        note: _noteController.text.trim(),
      );
      provider.updateEsame(updated);
    } else {
      provider.addEsame(
        titolo: _titoloController.text.trim(),
        corsoId: _corsoId!,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: voto,
        note: _noteController.text.trim(),
      );
    }

    Navigator.pop(context);
  }
}
