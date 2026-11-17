# SwiftLoans

App de gestión de préstamos (Flutter + GetX + Firebase) para web, tablet y móvil:
clientes, préstamos, cobros en ruta, movimientos, gastos, cuadre de caja,
reportes, notificaciones y recibos por WhatsApp o impresora Bluetooth.

## Probar sin instalar

**https://mellomarziano.github.io/SwiftLoans/**

En el login toca **Ver demo** y elige *Como dueño* o *Como cobrador*.
La demo usa datos de ejemplo: no guarda nada y se reinicia al salir.

## Desarrollo

```bash
flutter pub get
flutter run
flutter test
```

La web se publica sola en GitHub Pages en cada push a `main`
(`.github/workflows/pages.yml`).
