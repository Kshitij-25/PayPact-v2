import 'package:flutter_test/flutter_test.dart';
import 'package:paypact/core/services/receipt_scanner.dart';

final _now = DateTime(2026, 10, 1);

void main() {
  test('restaurant bill: picks the total, not the subtotal or tax', () {
    const text = '''
SPICE GARDEN RESTAURANT
123 MG Road, Bengaluru
GSTIN 29ABCDE1234F1Z5
Date: 05/03/2026   Table 4
Butter Chicken        1  420.00
Naan                  4  160.00
Subtotal                 580.00
CGST 2.5%                14.50
SGST 2.5%                14.50
Total                    609.00
Thank you!
''';
    final r = parseReceiptText(text, now: _now);
    expect(r.total, 609.00);
    expect(r.merchant, 'SPICE GARDEN RESTAURANT');
    expect(r.date, DateTime(2026, 3, 5));
  });

  test('grand total beats other totals; thousands separators are understood', () {
    const text = '''
Reliance Fresh
Total Items 12
Sub Total 1,180.00
Discount 80.00
Grand Total 1,100.00
''';
    final r = parseReceiptText(text, now: _now);
    expect(r.total, 1100.00);
    expect(r.merchant, 'Reliance Fresh');
  });

  test('a keyword on its own line takes the amount from the next line', () {
    const text = 'Cafe Roma\nAmount Due\n24.50\nVisa ****1234';
    expect(parseReceiptText(text, now: _now).total, 24.50);
  });

  test('European decimal commas', () {
    expect(parseReceiptText('Bistro\nTotal 18,90 EUR', now: _now).total, 18.90);
    expect(parseReceiptText('Bistro\nTotal 1.234,50', now: _now).total, 1234.50);
  });

  test('no keyword: falls back to the biggest amount on the page', () {
    const text = 'Taxi Co\nRide 120.00\nTip 20.00\n140.00';
    expect(parseReceiptText(text, now: _now).total, 140.00);
  });

  test('nothing readable gives an empty scan rather than an error', () {
    final r = parseReceiptText('%%% ~~\n', now: _now);
    expect(r.isEmpty, isTrue);
    expect(parseReceiptText('', now: _now).isEmpty, isTrue);
  });

  group('dates', () {
    DateTime? date(String s) => parseReceiptText('Shop\n$s', now: _now).date;

    test('understands the common formats', () {
      expect(date('2026-03-05'), DateTime(2026, 3, 5));
      expect(date('5 Mar 2026'), DateTime(2026, 3, 5));
      expect(date('05 March, 2026'), DateTime(2026, 3, 5));
      expect(date('05/03/26'), DateTime(2026, 3, 5));
      expect(date('5-3-2026'), DateTime(2026, 3, 5));
    });

    test('day-first by default, month-first when it must be', () {
      expect(date('03/04/2026'), DateTime(2026, 4, 3));
      expect(date('03/25/2026'), DateTime(2026, 3, 25));
    });

    test('rejects impossible or future dates', () {
      expect(date('31/02/2026'), isNull);
      expect(date('01/01/2031'), isNull);
    });
  });

  test('merchant skips boilerplate lines and caps its length', () {
    const text = 'TAX INVOICE\nTel: 98765 43210\nThe Very Long Named Establishment Of Fine Dining Pvt Ltd\nTotal 10.00';
    final m = parseReceiptText(text, now: _now).merchant!;
    expect(m.startsWith('The Very Long Named'), isTrue);
    expect(m.length, lessThanOrEqualTo(40));
  });
}
