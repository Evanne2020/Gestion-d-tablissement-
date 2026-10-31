import 'package:flutter/material.dart';

import '../models/classe.dart';

/// Liste déroulante « Toutes les classes » / une classe.
class FiltreClasse extends StatelessWidget {
  final List<Classe> classes;
  final int? valeur;
  final ValueChanged<int?> onChanged;

  const FiltreClasse({
    super.key,
    required this.classes,
    required this.valeur,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Classe',
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          isExpanded: true,
          value: valeur,
          items: [
            const DropdownMenuItem<int?>(
                value: null, child: Text('Toutes les classes')),
            for (final c in classes)
              DropdownMenuItem<int?>(value: c.id, child: Text(c.nom)),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
