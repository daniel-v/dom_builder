import 'package:swiss_knife/swiss_knife.dart';

import 'dom_builder_base.dart';
import 'dom_builder_generator.dart';
import 'dom_builder_treemap.dart';

/// Wraps the actual generated node [T] and allows some operations over it.
abstract class DOMNodeRuntime<T> {
  final DOMTreeMap<T> treeMap;

  DOMGenerator<T> get domGenerator => treeMap.domGenerator;

  final DOMNode domNode;

  final T node;

  DOMNodeRuntime(this.treeMap, this.domNode, this.node);

  DOMNodeRuntime<T> get parentRuntime {
    var domNodeParent = domNode != null ? domNode.parent : null;
    var nodeParent = domGenerator.getNodeParent(node);
    if (nodeParent == null) return null;
    return domGenerator.createDOMNodeRuntime(
        treeMap, domNodeParent, nodeParent);
  }

  bool get hasParent {
    var nodeParent = domGenerator.getNodeParent(node);
    return nodeParent != null;
  }

  String get tagName;

  bool get isStringElement;

  List<String> get classes;

  void addClass(String className);

  bool removeClass(String className);

  void clearClasses();

  bool get exists => domNode != null && node != null;

  String get text;

  set text(String value);

  String get value;

  set value(String value);

  String operator [](String name) => getAttribute(name);

  void operator []=(String name, dynamic value) => setAttribute(name, value);

  String getAttribute(String name);

  void setAttribute(String name, String value);

  void removeAttribute(String name);

  List<T> get children;

  int get nodesLength;

  T getNodeAt(int index);

  int get indexInParent;

  bool isInSameParent(T other) {
    var nodeParent = domGenerator.getNodeParent(node);
    return nodeParent != null &&
        nodeParent == domGenerator.getNodeParent(other);
  }

  DOMNodeRuntime<T> getSiblingRuntime(T other) {
    if (other == null || !isInSameParent(other)) return null;

    var otherDomNode = treeMap.getMappedDOMNode(other);
    return domGenerator.createDOMNodeRuntime(treeMap, otherDomNode, other);
  }

  bool isPreviousNode(T other) {
    var otherRuntime = getSiblingRuntime(other);
    if (otherRuntime == null) return false;

    var idx = indexInParent;
    var otherIdx = otherRuntime.indexInParent;
    return otherIdx >= 0 && otherIdx + 1 == idx;
  }

  bool isNextNode(T other) {
    var otherRuntime = getSiblingRuntime(other);
    if (otherRuntime == null) return false;

    var idx = indexInParent;
    var otherIdx = otherRuntime.indexInParent;
    return idx >= 0 && idx + 1 == otherIdx;
  }

  bool isConsecutiveNode(T other) {
    return isNextNode(other) || isPreviousNode(other);
  }

  int indexOf(T child);

  void add(T child);

  void insertAt(int index, T child);

  bool removeNode(T child);

  T removeAt(int index);

  void clear();

  bool remove() {
    if (hasParent) {
      return parentRuntime.removeNode(node);
    }
    return false;
  }

  int _contentFromIndexBackwardWhere(
      int idx, int steps, bool Function(T node) test) {
    for (var i = Math.min(idx, nodesLength - 1); i >= 0; i--) {
      var node = getNodeAt(i);
      if (test(node)) {
        if (steps <= 0) {
          return i;
        } else {
          --steps;
        }
      }
    }
    return -1;
  }

  int _contentFromIndexForwardWhere(
      int idx, int steps, bool Function(T node) test) {
    for (var i = idx; i < nodesLength; i++) {
      var node = getNodeAt(i);
      if (test(node)) {
        if (steps <= 0) {
          return i;
        } else {
          --steps;
        }
      }
    }
    return -1;
  }

  bool moveUp() {
    if (!hasParent) return false;
    var parentRuntime = this.parentRuntime;

    var idx = indexInParent;
    if (idx < 0) return false;
    if (idx == 0) return true;

    remove();

    var idxUp = parentRuntime._contentFromIndexBackwardWhere(
        idx - 1, 0, (node) => domGenerator.isElementNode(node));
    if (idxUp < 0) {
      idxUp = 0;
    }

    parentRuntime.insertAt(idxUp, node);
    return true;
  }

  bool moveDown() {
    if (!hasParent) return false;
    var parentRuntime = this.parentRuntime;

    var idx = indexInParent;
    if (idx < 0) return false;
    if (idx >= parentRuntime.nodesLength - 1) return true;

    remove();

    var idxDown = parentRuntime._contentFromIndexForwardWhere(
        idx, 1, (node) => domGenerator.isElementNode(node));
    if (idxDown < 0) {
      idxDown = parentRuntime.nodesLength;
    }

    parentRuntime.insertAt(idxDown, node);
    return true;
  }

  T copy();

  T duplicate() {
    var parentRuntime = this.parentRuntime;
    var idx = indexInParent;
    if (idx < 0) return null;

    var copy = this.copy();
    parentRuntime.insertAt(idx + 1, copy);

    return copy;
  }

  bool absorbNode(T other);

  bool mergeNode(T other, {bool onlyConsecutive = true}) {
    onlyConsecutive ??= true;

    if (onlyConsecutive) {
      if (isPreviousNode(other)) {
        return getSiblingRuntime(other).mergeNode(node, onlyConsecutive: false);
      } else if (!isNextNode(other)) {
        return false;
      }
    }

    if (hasParent) {
      parentRuntime.removeNode(other);
    }

    absorbNode(other);
    return true;
  }
}

class DOMNodeRuntimeDummy<T> extends DOMNodeRuntime<T> {
  DOMNodeRuntimeDummy(DOMTreeMap<T> treeMap, DOMNode domNode, T node)
      : super(treeMap, domNode, node);

  @override
  String get tagName => null;

  @override
  void addClass(String className) {}

  @override
  List<String> get classes => [];

  @override
  void clearClasses() {}

  @override
  bool removeClass(String className) => false;

  @override
  String get text => '';

  @override
  set text(String value) {}

  @override
  String get value => '';

  @override
  set value(String value) {}

  @override
  String getAttribute(String name) {
    return null;
  }

  @override
  void setAttribute(String name, String value) {}

  @override
  void removeAttribute(String name) {}

  @override
  void add(T child) {}

  @override
  List<T> get children => [];

  @override
  int get nodesLength => 0;

  @override
  T getNodeAt(int index) => null;

  @override
  void clear() {}

  @override
  int get indexInParent => -1;

  @override
  int indexOf(T child) => -1;

  @override
  void insertAt(int index, T child) {}

  @override
  bool removeNode(T child) => false;

  @override
  T removeAt(int index) => null;

  @override
  T copy() => null;

  @override
  bool absorbNode(T other) => false;

  @override
  bool get isStringElement => false;
}
