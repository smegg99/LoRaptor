// lib/services/hive_service.dart
import 'package:hive/hive.dart';
import 'package:raptchat/models/connection_element.dart';

class HiveService {
  static const _boxName = 'connection_elements';

  Future<Box<ConnectionElement>> openBox() async {
    return await Hive.openBox<ConnectionElement>(_boxName);
  }

  Future<void> addElement(ConnectionElement element) async {
    final box = await openBox();
    await box.add(element);
  }

  Future<void> deleteElement(ConnectionElement element) async {
    final box = await openBox();
    await box.delete(element.key);
  }

  Future<void> updateElement(ConnectionElement element) async {
    await element.save();
  }

  Future<List<ConnectionElement>> getAllElements() async {
    final box = await openBox();
    return box.values.toList();
  }
}
