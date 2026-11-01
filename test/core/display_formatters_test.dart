import 'package:flutter_test/flutter_test.dart';
import 'package:cohv/core/utils/display_formatters.dart';

void main() {
  group('cleanDisplayValue', () {
    test('handles null, empty, and "null"', () {
      expect(cleanDisplayValue(null), '—');
      expect(cleanDisplayValue(''), '—');
      expect(cleanDisplayValue('   '), '—');
      expect(cleanDisplayValue('null'), '—');
      expect(cleanDisplayValue('[]'), '—');
    });

    test('formats raw bracket string lists', () {
      expect(
        cleanDisplayValue('[Public Health Department, Animal Husbandry Department]'),
        'Public Health Department, Animal Husbandry Department',
      );
      expect(
        cleanDisplayValue("['Dengue', 'Malaria']"),
        'Dengue, Malaria',
      );
      expect(
        cleanDisplayValue('["Rabies", "Anthrax"]'),
        'Rabies, Anthrax',
      );
      expect(
        cleanDisplayValue('[1, 2, 3]'),
        '1, 2, 3',
      );
    });

    test('formats Dart Lists', () {
      expect(
        cleanDisplayValue(['Public Health', 'Animal Husbandry']),
        'Public Health, Animal Husbandry',
      );
      expect(
        cleanDisplayValue([1, 2, 3]),
        '1, 2, 3',
      );
      expect(
        cleanDisplayValue([]),
        '—',
      );
    });

    test('preserves normal strings', () {
      expect(
        cleanDisplayValue('Single Department'),
        'Single Department',
      );
      expect(
        cleanDisplayValue('Achampet Village'),
        'Achampet Village',
      );
    });
  });
}
