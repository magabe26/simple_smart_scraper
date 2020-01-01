import 'package:meta/meta.dart';

///  openEndElement eg;- <font color="green'></font>
///  closeEndElement eg;- <link color="green'/>
///  otherElement eg- emptyElement like <br>
enum ElementType { openEndElement, closeEndElement, comment, otherElement }

class Element {
  final ElementType type;
  final String tag;
  final String markup;

  Element({
    @required this.type,
    this.tag,
    @required this.markup,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Element &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          tag == other.tag &&
          markup == other.markup;

  @override
  int get hashCode => type.hashCode ^ tag.hashCode ^ markup.hashCode;

  @override
  String toString() {
    return markup ?? '';
  }
}
