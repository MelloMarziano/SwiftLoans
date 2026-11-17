import 'package:flutter_test/flutter_test.dart';
import 'package:swiftloans/app/core/utils/formatters.dart';

void main() {
  test('Formatters', () {
    expect(Formatters.currency(10450000), '10,450,000');
    expect(Formatters.currency2(4500.5), '4,500.50');
    expect(Formatters.compact(800000), '800K');
    expect(Formatters.compact(2500), '2.5K');
    expect(Formatters.compact(1200000), '1.2M');
    expect(Formatters.percent(0.845), '84.5%');
  });
}
