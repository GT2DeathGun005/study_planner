import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/esame.dart';
import '../../providers/corso_provider.dart';
import '../../providers/esame_provider.dart';

/// Schermata per creare o modificare un Esame.
///
/// Il corsoId è obbligatorio e determina il corso associato.
/// Se viene passato un esame esistente, pre-compila i campi per la modifica.
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

  /// Modalità visualizzazione se l'esame esiste già
  bool _isViewMode = false;

  Color _prioritaColor(String priorita) {
    switch (priorita) {
      case 'alta':
        return Colors.red;
      case 'media':
        return Colors.orange;
      case 'bassa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _statoColor(String stato) {
    switch (stato) {
      case 'programmato':
        return Colors.blue;
      case 'completato':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  void initState() {
    super.initState();
    final e = widget.esame;
    _isViewMode = e != null;
    _corsoId = e?.corsoId ?? widget.corsoId!;
    _titoloController = TextEditingController(text: e?.titolo ?? '');
    _noteController = TextEditingController(text: e?.note ?? '');
    _votoController =
        TextEditingController(text: e?.voto?.toString() ?? '');

    final esameProv = context.read<EsameProvider>();
    final disponibile = esameProv.getPercentualeDisponibile(
      _corsoId,
      excludeEsameId: e?.id,
    );

    _pesoController = TextEditingController(
        text: e?.pesoPercentuale.toString() ?? '${disponibile.toInt()}');
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
        title: Text(_isViewMode
            ? 'Dettaglio Esame'
            : isEditing
                ? 'Modifica Esame'
                : 'Nuovo Esame'),
        actions: [
          if (_isViewMode)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isViewMode = false),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isViewMode
            ? _buildInfoSection(context, theme)
            : _buildForm(context, theme, disponibile),
      ),
    );
  }

  /// Sezione informativa per un esame completato (read-only).
  Widget _buildInfoSection(BuildContext context, ThemeData theme) {
    final esame = widget.esame!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Card con dettagli
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                    icon: Icons.title,
                    label: 'Titolo',
                    value: esame.titolo),
                _DetailRow(
                    icon: Icons.calendar_today,
                    label: 'Data',
                    value: _getFormattedDate(esame.data)),
                _DetailRow(
                    icon: Icons.category,
                    label: 'Tipologia',
                    value: Esame.tipologiaLabel(esame.tipologia)),
                _DetailRow(
                    icon: Icons.priority_high,
                    label: 'Priorità',
                    value: Esame.prioritaLabel(esame.priorita),
                    valueColor: _prioritaColor(esame.priorita)),
                _DetailRow(
                    icon: Icons.traffic,
                    label: 'Stato',
                    value: Esame.statoLabel(esame.stato),
                    valueColor: _statoColor(esame.stato)),
                _DetailRow(
                    icon: Icons.percent,
                    label: 'Peso',
                    value: '${esame.pesoPercentuale}%'),
                if (esame.voto != null)
                  _DetailRow(
                      icon: Icons.grade,
                      label: 'Voto',
                      value: '${esame.voto}/30'),
                if (esame.voto != null)
                  _DetailRow(
                      icon: Icons.calculate,
                      label: 'Punti ponderati',
                      value: esame.puntiPonderati.toStringAsFixed(1)),
                if (esame.note.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text('Note',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurface
                            .withValues(alpha: 0.5),
                      )),
                  const SizedBox(height: 4),
                  Text(esame.note, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Form per creare o modificare un esame (non completato).
  Widget _buildForm(BuildContext context, ThemeData theme, double disponibile) {
    return Form(
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

          // Data
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today),
            title: const Text('Data'),
            subtitle:
                Text(_getFormattedDate(_data)),
            trailing: const Icon(Icons.chevron_right),
            onTap: _pickDate,
          ),

          const Divider(),
          const SizedBox(height: 16),

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

          // Stato (solo Programmato / Completato)
          DropdownButtonFormField<String>(
            initialValue: _stato,
            decoration: const InputDecoration(
              labelText: 'Stato',
              prefixIcon: Icon(Icons.traffic),
            ),
            items: Esame.statiDisponibili.map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(Esame.statoLabel(s)),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() {
                  _stato = v;
                  if (v == 'programmato') {
                    final now = DateTime.now();
                    final today = DateTime(now.year, now.month, now.day);
                    final dataCorrente = DateTime(_data.year, _data.month, _data.day);
                    if (dataCorrente.isBefore(today)) {
                      _data = now;
                    }
                  }
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // Peso percentuale
          _buildPesoField(context, disponibile),
          const SizedBox(height: 16),

          // Voto (obbligatorio se completato)
          TextFormField(
            controller: _votoController,
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
            decoration: const InputDecoration(
              labelText: 'Note',
              prefixIcon: Icon(Icons.notes),
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
    );
  }

  /// Costruisce il campo per il peso percentuale con indicazione
  /// della percentuale disponibile e validazione stretta.
  Widget _buildPesoField(BuildContext context, double disponibile) {
    final pesoInserito = int.tryParse(_pesoController.text) ?? 0;
    final superaLimite = pesoInserito > disponibile;

    return TextFormField(
      controller: _pesoController,
      readOnly: false,
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

  String _getFormattedDate(DateTime date) {
    final dayStr = DateFormat('dd', 'it_IT').format(date);
    final monthStr = DateFormat('MMMM', 'it_IT').format(date);
    final yearStr = DateFormat('yyyy', 'it_IT').format(date);
    final capitalizedMonth = monthStr.isEmpty
        ? ''
        : (monthStr[0].toUpperCase() + monthStr.substring(1));
    return '$dayStr $capitalizedMonth $yearStr';
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
      setState(() {
        _data = picked;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final pickedDate = DateTime(picked.year, picked.month, picked.day);
        if (pickedDate.isBefore(today)) {
          _stato = 'completato';
        }
      });
    }
  }

  int _arrotondaVoto(double voto) {
    final roundedDec = double.parse(voto.toStringAsFixed(2));
    final intero = roundedDec.floor();
    final decimale = roundedDec - intero;
    return decimale > 0.5 ? (intero + 1) : intero;
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    final esameProv = context.read<EsameProvider>();
    final corsoProv = context.read<CorsoProvider>();
    final voto = int.tryParse(_votoController.text);
    final peso = int.tryParse(_pesoController.text) ?? 100;

    // controllo media finale >= 18
    if (_stato == 'completato' && voto != null) {
      final usataAltri = esameProv.getPercentualeTotale(_corsoId, excludeEsameId: widget.esame?.id);
      final pesoTotaleFuturo = usataAltri + peso;

      if (pesoTotaleFuturo >= 100) {
        final esamiAltri = esameProv.getEsamiCorso(_corsoId).where((e) => e.id != widget.esame?.id).toList();
        final altriCompletati = esamiAltri.every((e) => e.stato == 'completato' && e.voto != null);
        
        if (altriCompletati || esamiAltri.isEmpty) {
          final puntiAltri = esamiAltri.fold<double>(0, (sum, e) => sum + e.puntiPonderati);
          final puntiQuesto = (voto * peso) / 100;
          final votoCalcolato = puntiAltri + puntiQuesto;
          final votoArrotondato = _arrotondaVoto(votoCalcolato);

          if (votoArrotondato < 18) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Mi dispiace ma non raggiungi la sufficienza. Impossibile completare il corso.'),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
            return;
          }
        }
      }
    }

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
      await esameProv.updateEsame(updated);
    } else {
      await esameProv.addEsame(
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

    // Controlla se il corso deve passare automaticamente a "superato":
    // - Il peso totale degli esami ha raggiunto il 100%
    // - Tutti gli esami del corso sono completati con un voto
    await _checkAutoSuperato(corsoProv, esameProv);

    if (mounted) Navigator.pop(context);
  }

  /// Verifica se il corso deve passare automaticamente allo stato 'superato'.
  /// Condizioni: peso totale = 100% e tutti gli esami completati con voto.
  Future<void> _checkAutoSuperato(CorsoProvider corsoProv, EsameProvider esameProv) async {
    final corso = corsoProv.getCorsoById(_corsoId);
    if (corso == null) return;

    final esamiCorso = esameProv.getEsamiCorso(_corsoId);
    final pesoTotale = esameProv.getPercentualeTotale(_corsoId);

    bool isCompletato = false;
    if (pesoTotale >= 100 && esamiCorso.isNotEmpty) {
      isCompletato = esamiCorso.every((e) => e.stato == 'completato' && e.voto != null);
    }

    if (isCompletato) {
      final votoCalcolato = esameProv.calcolaVotoCorso(_corsoId);
      final votoArrotondato = _arrotondaVoto(votoCalcolato);
      
      bool lode = corso.lode;
      if (votoArrotondato == 30 && corso.stato != 'superato') {
        if (mounted) {
          final answer = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return AlertDialog(
                title: const Text('Congratulazioni! 🎉'),
                content: const Text(
                  'Il voto complessivo calcolato è 30. Questo corso è stato superato con lode?'
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('No'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Sì, con lode'),
                  ),
                ],
              );
            },
          );
          lode = answer ?? false;
        }
      }
      
      if (corso.stato != 'superato' || corso.lode != lode) {
        await corsoProv.updateCorso(
          corso.copyWith(
            stato: 'superato',
            lode: lode,
          ),
        );
      }
    } else {
      if (corso.stato == 'superato') {
        await corsoProv.updateCorso(
          corso.copyWith(
            stato: 'in_corso',
            lode: false,
          ),
        );
      }
    }
  }
}

/// Widget riga dettaglio per la visualizzazione read-only di un esame.
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Text(label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              )),
          const Spacer(),
          Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: valueColor,
              )),
        ],
      ),
    );
  }
}
