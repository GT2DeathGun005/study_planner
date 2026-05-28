import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/esame.dart';
import '../../providers/esame_provider.dart';

/// Schermata per creare o modificare un Esame.
///
/// Il [corsoId] è obbligatorio e determina il corso associato.
/// Se viene passato un [esame] esistente, pre-compila i campi per la modifica.
/// Un esame completato non è modificabile.
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
  late final TextEditingController _pesoController;
  late String _corsoId;
  late DateTime _data;
  late String _tipologia;
  late String _priorita;
  late String _stato;

  bool get isEditing => widget.esame != null;

  /// Un esame completato non può essere modificato.
  bool get isReadOnly =>
      isEditing && widget.esame!.stato == 'completato';

  @override
  void initState() {
    super.initState();
    final e = widget.esame;
    _titoloController = TextEditingController(text: e?.titolo ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _votoController =
        TextEditingController(text: e?.voto?.toString() ?? '');
    _pesoController = TextEditingController(
        text: e?.pesoPercentuale.toString() ?? '100');
    _corsoId = e?.corsoId ?? widget.corsoId!;
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
    _pesoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final esameProv = context.watch<EsameProvider>();
    final disponibile = esameProv.getPercentualeDisponibile(
      _corsoId,
      excludeEsameId: widget.esame?.id,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(isReadOnly
            ? 'Dettaglio Esame'
            : isEditing
                ? 'Modifica Esame'
                : 'Nuovo Esame'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Banner esame completato
              if (isReadOnly) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Esame completato — non modificabile',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Titolo
              TextFormField(
                controller: _titoloController,
                readOnly: isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Titolo *',
                  prefixIcon: Icon(Icons.title),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Data
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_today),
                title: const Text('Data'),
                subtitle:
                    Text(DateFormat('dd MMMM yyyy', 'it_IT').format(_data)),
                trailing: isReadOnly
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: isReadOnly ? null : _pickDate,
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
                      onChanged: isReadOnly
                          ? null
                          : (v) {
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
                      onChanged: isReadOnly
                          ? null
                          : (v) {
                              if (v != null) setState(() => _priorita = v);
                            },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Stato (solo Programmato / Completato)
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
                onChanged: isReadOnly
                    ? null
                    : (v) {
                        if (v != null) setState(() => _stato = v);
                      },
              ),
              const SizedBox(height: 16),

              // Peso percentuale
              _buildPesoField(context, disponibile),
              const SizedBox(height: 16),

              // Voto (obbligatorio se completato)
              TextFormField(
                controller: _votoController,
                readOnly: isReadOnly,
                decoration: InputDecoration(
                  labelText: _stato == 'completato'
                      ? 'Voto *'
                      : 'Voto ',
                  prefixIcon: const Icon(Icons.grade),
                  helperText: 'Valore in trentesimi (0-30)',
                ),
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  // Se l'utente inserisce un voto, imposta automaticamente lo stato a completato
                  if (v.isNotEmpty && int.tryParse(v) != null) {
                    if (_stato != 'completato') {
                      setState(() => _stato = 'completato');
                    }
                  }
                },
                validator: (v) {
                  if (_stato == 'completato') {
                    if (v == null || v.isEmpty) {
                      return 'Il voto è obbligatorio per un esame completato';
                    }
                    final n = int.tryParse(v);
                    if (n == null || n < 0 || n > 30) {
                      return 'Valore 0-30';
                    }
                  } else if (v != null && v.isNotEmpty) {
                    // Se c'è un voto ma lo stato non è completato
                    return 'Imposta lo stato a "Completato" per inserire un voto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Note
              TextFormField(
                controller: _noteController,
                readOnly: isReadOnly,
                decoration: const InputDecoration(
                  labelText: 'Note',
                  prefixIcon: Icon(Icons.notes),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),

              const SizedBox(height: 32),

              // Pulsante salva (nascosto se read-only)
              if (!isReadOnly)
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

  /// Costruisce il campo per il peso percentuale con indicazione
  /// della percentuale disponibile e validazione stretta.
  Widget _buildPesoField(BuildContext context, double disponibile) {
    final pesoInserito = int.tryParse(_pesoController.text) ?? 0;
    final superaLimite = pesoInserito > disponibile;

    return TextFormField(
      controller: _pesoController,
      readOnly: isReadOnly,
      decoration: InputDecoration(
        labelText: 'Peso % *',
        prefixIcon: const Icon(Icons.percent),
        helperText: 'Percentuale rimanente: ${disponibile.toStringAsFixed(0)}%',
        helperStyle: TextStyle(
          color: superaLimite ? Theme.of(context).colorScheme.error : null,
        ),
        errorText: superaLimite
            ? 'Non puoi superare la percentuale rimanente (${disponibile.toStringAsFixed(0)}%)'
            : null,
        suffixText: '%',
      ),
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Campo obbligatorio';
        final n = int.tryParse(v);
        if (n == null || n < 0) return 'Valore non valido';
        if (n > disponibile) {
          return 'Max ${disponibile.toStringAsFixed(0)}%';
        }
        return null;
      },
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _data,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      locale: const Locale('it', 'IT'),
    );
    if (picked != null) {
      setState(() => _data = picked);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<EsameProvider>();
    final voto = int.tryParse(_votoController.text);
    final peso = int.tryParse(_pesoController.text) ?? 100;

    if (isEditing) {
      final updated = widget.esame!.copyWith(
        titolo: _titoloController.text.trim(),
        corsoId: _corsoId,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: voto,
        clearVoto: _votoController.text.isEmpty,
        pesoPercentuale: peso,
        note: _noteController.text.trim(),
      );
      provider.updateEsame(updated);
    } else {
      provider.addEsame(
        titolo: _titoloController.text.trim(),
        corsoId: _corsoId,
        data: _data,
        tipologia: _tipologia,
        priorita: _priorita,
        stato: _stato,
        voto: voto,
        pesoPercentuale: peso,
        note: _noteController.text.trim(),
      );
    }

    Navigator.pop(context);
  }
}
