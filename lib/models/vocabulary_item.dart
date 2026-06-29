import 'package:uuid/uuid.dart';

class VocabularyItem {
  final String id;
  final String termA;
  final String termB;
  final String comment;

  VocabularyItem({
    String? id,
    required this.termA,
    required this.termB,
    this.comment = '',
  }) : id = id ?? const Uuid().v4();
}