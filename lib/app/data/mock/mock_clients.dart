import 'dart:math';

import '../catalogs.dart';
import '../models/client.dart';

/// Clientes de ejemplo mientras se conecta Supabase.
/// Genera 178 clientes: 168 activos, 10 inactivos y 44 con préstamo.
abstract class MockClients {
  static const _named = [
    Client(id: '43', name: 'Alexander Cueva', alias: 'El Marron'),
    Client(id: '0000000', name: 'Angelo Peralta'),
    Client(id: '26', name: 'Carolina Martínez'),
    Client(id: '36', name: 'Clave'),
    Client(id: '31', name: 'Darico Rosario'),
    Client(id: '28', name: 'David Lora'),
  ];

  static const _firstNames = [
    'Ana',
    'Luis',
    'María',
    'José',
    'Carmen',
    'Pedro',
    'Rosa',
    'Miguel',
    'Yolanda',
    'Ramón',
    'Juana',
    'Rafael',
    'Altagracia',
    'Julio',
    'Mercedes',
    'Francisco',
    'Josefina',
    'Manuel',
    'Elena',
    'Héctor',
    'Sonia',
    'Wilson',
  ];

  static const _lastNames = [
    'Pérez',
    'Rodríguez',
    'Gómez',
    'Santana',
    'Reyes',
    'Jiménez',
    'Batista',
    'Polanco',
    'Vásquez',
    'Castillo',
    'Féliz',
    'Núñez',
    'Guzmán',
    'Almonte',
    'Mejía',
    'De la Cruz',
    'Tavárez',
    'Encarnación',
  ];

  static List<Client> generate() {
    final random = Random(7);
    final base = <Client>[..._named];
    var nextId = 100;

    while (base.length < 178) {
      final first = _firstNames[random.nextInt(_firstNames.length)];
      final last = _lastNames[random.nextInt(_lastNames.length)];
      final name = '$first $last';
      if (base.any((c) => c.name == name)) continue;
      base.add(
        Client(
          id: '${nextId++}',
          name: name,
          document: random.nextInt(3) == 0
              ? null
              : '0${random.nextInt(90) + 10}-${random.nextInt(9000000) + 1000000}-${random.nextInt(10)}',
          phone: random.nextBool()
              ? '809-${random.nextInt(900) + 100}-${random.nextInt(9000) + 1000}'
              : null,
        ),
      );
    }

    // Los primeros del diseño tienen préstamo por cobrar; el resto se reparte.
    final order = List.generate(
      base.length - _named.length,
      (i) => i + _named.length,
    )..shuffle(random);
    final inactive = order.take(10).toSet();
    final withLoan = order.skip(10).take(44 - _named.length).toList();

    const loanStatuses = [
      ClientLoanStatus.toCollect,
      ClientLoanStatus.toCollect,
      ClientLoanStatus.upToDate,
      ClientLoanStatus.overdue,
    ];

    final clients = [
      for (var i = 0; i < base.length; i++)
        base[i].copyWith(
          route: Catalogs.routes[i % Catalogs.routes.length],
          isActive: !inactive.contains(i),
          loanStatus: i < _named.length
              ? ClientLoanStatus.toCollect
              : withLoan.contains(i)
              ? loanStatuses[i % loanStatuses.length]
              : ClientLoanStatus.none,
        ),
    ];

    return clients;
  }
}
