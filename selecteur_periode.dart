import 'package:flutter/material.dart';

import '../core/periode.dart';
import '../core/utils.dart';

/// Choix de la période (aujourd'hui, semaine, mois, année, dates libres).
class SelecteurPeriode extends StatelessWidget {
  final Periode periode;
  final String annee;
  final ValueChanged<Periode> onChanged;

  const SelecteurPeriode({
    super.key,
    required this.periode,
    required this.annee,
    required this.onChanged,
  });

  Future<void> _choisir(BuildContext context, TypePeriode t) async {
    if (t != TypePeriode.personnalisee) {
      onChanged(Periode.calculer(t, annee: annee));
      return;
    }
    final now = DateTime.now();
    final plage = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: periode.type == TypePeriode.personnalisee
          ? DateTimeRange(start: periode.debut, end: periode.fin)
          : null,
      helpText: 'Choisir la période',
      cancelText: 'Annuler',
      confirmText: 'Valider',
      saveText: 'Valider',
    );
    if (plage == null) return;
    onChanged(Periode.calculer(t,
        annee: annee, debutPerso: plage.start, finPerso: plage.end));
  }

  @override
  Widget build(BuildContext context) {
    final precision = periode.type == TypePeriode.aujourdhui
        ? null
        : 'du ${formatDateFr(periode.du)} au ${formatDateFr(periode.au)}';
    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'Période',
        helperText: precision,
        border: const OutlineInputBorder(),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TypePeriode>(
          isExpanded: true,
          value: periode.type,
          items: [
            for (final t in TypePeriode.values)
              DropdownMenuItem(value: t, child: Text(Periode.libelle(t))),
          ],
          onChanged: (t) {
            if (t != null) _choisir(context, t);
          },
        ),
      ),
    );
  }
}
