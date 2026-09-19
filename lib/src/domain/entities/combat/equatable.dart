// ===============================================================================
// [MODULE_NAME]: equatable.dart
// [SYSTEM]: lunacian_card_wars
// [DOMAIN]: Domain / Entities
// [INTENT]: Pure deterministic value-equality base class for domain entities
// [DEPENDENCIES]: None
// [ARCHITECTURE]: Domain Value Object Pattern
// ===============================================================================

abstract class Equatable {
  const Equatable();

  List<Object?> get props;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Equatable &&
          runtimeType == other.runtimeType &&
          _propsAreEqual(props, other.props);

  @override
  int get hashCode => Object.hashAll(props);

  @override
  String toString() => '$runtimeType(${props.join(', ')})';

  static bool _propsAreEqual(List<Object?> a, List<Object?> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
