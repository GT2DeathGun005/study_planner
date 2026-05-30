import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/corso.dart';
import '../../providers/corso_provider.dart';

/// Schermata per creare o modificare un Corso.
///
/// Se viene passato un [corso] esistente, pre-compila i campi per la modifica.
/// Altrimenti mostra un form vuoto per la creazione.
class CorsoFormScreen extends StatefulWidget {
  final Corso? corso;

  const CorsoFormScreen({super.key, this.corso});

  @override
  State<CorsoFormScreen> createState() => _CorsoFormScreenState();
}

class _CorsoFormScreenState extends State<CorsoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nomeController;
  late final TextEditingController _docenteController;
  late final TextEditingController _cfuController;
  late final TextEditingController _descrizioneController;
  late final TextEditingController _materialiController;
  late final TextEditingController _votoPrevistoController;
  late int _semestre;
  late String _stato;
  late String _tipoLaurea;
  late int _anno;

  bool get isEditing => widget.corso != null;

  @override
  void initState() {
    super.initState();
    final c = widget.corso;
    _nomeController = TextEditingController(text: c?.nome ?? '');
    _docenteController = TextEditingController(text: c?.docente ?? '');
    _cfuController = TextEditingController(text: c?.cfu.toString() ?? '');
    _descrizioneController =
        TextEditingController(text: c?.descrizione ?? '');
    _materialiController = TextEditingController(text: c?.materiali ?? '');
    _votoPrevistoController =
        TextEditingController(text: c?.votoPrevisto?.toString() ?? '');
    _semestre = c?.semestre ?? 1;
    _stato = c?.stato ?? 'da_iniziare';
    _tipoLaurea = c?.tipoLaurea ?? 'triennale';
    _anno = c?.anno ?? 1;
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _docenteController.dispose();
    _cfuController.dispose();
    _descrizioneController.dispose();
    _materialiController.dispose();
    _votoPrevistoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Modifica Corso' : 'Nuovo Corso'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Nome corso
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'Nome del corso *',
                  prefixIcon: Icon(Icons.book),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Campo obbligatorio';
                  }
                  final trimmed = v.trim().toLowerCase();
                  final exists = context.read<CorsoProvider>().tuttiCorsi.any(
                    (c) => c.nome.trim().toLowerCase() == trimmed && c.id != widget.corso?.id
                  );
                  if (exists) {
                    return 'Esiste già un corso con questo nome';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Docente
              TextFormField(
                controller: _docenteController,
                decoration: const InputDecoration(
                  labelText: 'Docente *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 16),

              // Tipo Laurea e Anno
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _tipoLaurea,
                      decoration: const InputDecoration(
                        labelText: 'Tipo Laurea',
                        prefixIcon: Icon(Icons.workspace_premium),
                      ),
                      items: Corso.tipiLaureaDisponibili.map((tipo) {
                        return DropdownMenuItem(
                          value: tipo,
                          child: Text(Corso.tipoLaureaLabel(tipo)),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() {
                            _tipoLaurea = v;
                            // Reset anno se non valido per il nuovo tipo
                            final anniValidi = Corso.anniPerTipo(v);
                            if (!anniValidi.contains(_anno)) {
                              _anno = 1;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _anno,
                      decoration: const InputDecoration(
                        labelText: 'Anno',
                        prefixIcon: Icon(Icons.looks_one),
                      ),
                      items: Corso.anniPerTipo(_tipoLaurea).map((a) {
                        return DropdownMenuItem(
                          value: a,
                          child: Text('$a° Anno'),
                        );
                      }).toList(),
                      onChanged: (v) {
                        if (v != null) setState(() => _anno = v);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // CFU e Semestre in riga
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cfuController,
                      decoration: const InputDecoration(
                        labelText: 'CFU *',
                        prefixIcon: Icon(Icons.star),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Obbligatorio';
                        }
                        if (int.tryParse(v) == null || int.parse(v) <= 0) {
                          return 'Valore non valido';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _semestre,
                      decoration: const InputDecoration(
                        labelText: 'Semestre',
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1° Semestre')),
                        DropdownMenuItem(value: 2, child: Text('2° Semestre')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => _semestre = v);
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
                  prefixIcon: Icon(Icons.traffic),
                ),
                items: Corso.statiDisponibili
                    .where((stato) => stato != 'superato' || _stato == 'superato')
                    .map((stato) {
                  return DropdownMenuItem(
                    value: stato,
                    child: Text(Corso.statoLabel(stato)),
                  );
                }).toList(),
                onChanged: (widget.corso != null && widget.corso!.stato == 'superato')
                    ? null
                    : (v) {
                        if (v != null) setState(() => _stato = v);
                      },
              ),
              const SizedBox(height: 16),

              // Voto previsto
              TextFormField(
                controller: _votoPrevistoController,
                decoration: const InputDecoration(
                  labelText: 'Voto previsto',
                  prefixIcon: Icon(Icons.trending_up),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v != null && v.isNotEmpty) {
                    final n = int.tryParse(v);
                    if (n == null || n < 18 || n > 30) {
                      return '18-30';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Descrizione
              TextFormField(
                controller: _descrizioneController,
                decoration: const InputDecoration(
                  labelText: 'Descrizione / Note',
                  prefixIcon: Icon(Icons.notes),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // Materiali
              TextFormField(
                controller: _materialiController,
                decoration: const InputDecoration(
                  labelText: 'Materiali / Riferimenti',
                  prefixIcon: Icon(Icons.link),
                ),
              ),

              const SizedBox(height: 32),

              // Pulsante salva
              FilledButton.icon(
                onPressed: _save,
                icon: Icon(isEditing ? Icons.save : Icons.add),
                label: Text(isEditing ? 'Salva modifiche' : 'Crea corso'),
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

    final provider = context.read<CorsoProvider>();
    final votoPrevisto = int.tryParse(_votoPrevistoController.text);

    if (isEditing) {
      final updated = widget.corso!.copyWith(
        nome: _nomeController.text.trim(),
        docente: _docenteController.text.trim(),
        semestre: _semestre,
        cfu: int.parse(_cfuController.text.trim()),
        descrizione: _descrizioneController.text.trim(),
        stato: _stato,
        tipoLaurea: _tipoLaurea,
        anno: _anno,
        votoPrevisto: votoPrevisto,
        clearVotoPrevisto: _votoPrevistoController.text.isEmpty,
        materiali: _materialiController.text.trim(),
      );
      provider.updateCorso(updated);
    } else {
      provider.addCorso(
        nome: _nomeController.text.trim(),
        docente: _docenteController.text.trim(),
        semestre: _semestre,
        cfu: int.parse(_cfuController.text.trim()),
        descrizione: _descrizioneController.text.trim(),
        stato: _stato,
        tipoLaurea: _tipoLaurea,
        anno: _anno,
        votoPrevisto: votoPrevisto,
        materiali: _materialiController.text.trim(),
      );
    }

    Navigator.pop(context);
  }
}
