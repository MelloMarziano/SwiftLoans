import 'package:get_storage/get_storage.dart';

/// Almacenamiento clave-valor. En la app usa GetStorage (disco); en los tests,
/// memoria.
abstract class KeyValueStore {
  T? read<T>(String key);
  void write(String key, Object? value);
  void remove(String key);
  void erase();
}

class GetStorageStore implements KeyValueStore {
  final _box = GetStorage();

  @override
  T? read<T>(String key) => _box.read<T>(key);

  @override
  void write(String key, Object? value) => _box.write(key, value);

  @override
  void remove(String key) => _box.remove(key);

  @override
  void erase() => _box.erase();
}

class MemoryStore implements KeyValueStore {
  final _data = <String, Object?>{};

  @override
  T? read<T>(String key) => _data[key] as T?;

  @override
  void write(String key, Object? value) => _data[key] = value;

  @override
  void remove(String key) => _data.remove(key);

  @override
  void erase() => _data.clear();
}
