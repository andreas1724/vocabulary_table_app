import 'package:uuid/uuid.dart';

class VocabularyItem {
  VocabularyItem({
    String? id,
    required this.termA,
    required this.termB,
    this.comment = '',
  }) : id = id ?? const Uuid().v4();
  
  final String id;
  final String termA;
  final String termB;
  final String comment;
}
