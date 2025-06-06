/// A helper to modify groups of ``EditorComponent`` arrays.
public class ArrayModifier<Element, Group: Hashable> {
  var toAddLast = [Group: [Element]]()
  var toAddFirst = [Group: [Element]]()
  private var toAddAfter = [EditorComponentID: [Element]]()
  private var toAddBefore = [EditorComponentID: [Element]]()
  private var toReplace = [EditorComponentID: [Element]]()
  private var toRemove = Set<EditorComponentID>()

  // swiftlint:disable:next cyclomatic_complexity
  func apply(to groups: inout [Group: [Element]]) throws {
    let keys = Set(groups.keys).union(toAddFirst.keys).union(toAddLast.keys)
    for key in keys {
      let elements = groups[key] ?? []
      groups[key] = withArrayBuilder {
        toAddFirst[key] ?? []
        for item in elements {
          if let component = item as? any EditorComponent {
            let id = component.id

            // Try remove item first, then do other operations.
            if toRemove.remove(id) == nil {
              if let before = toAddBefore.removeValue(forKey: id) {
                before
              }
              if let replacement = toReplace.removeValue(forKey: id) {
                replacement
              } else {
                item
              }
              if let after = toAddAfter.removeValue(forKey: id) {
                after
              }
            }
          }
        }
        toAddLast[key] ?? []
      }
    }

    if let id = toRemove.first {
      throw error(operation: "remove", id: id)
    }
    if let id = toAddBefore.keys.first {
      throw error(operation: "addBefore", id: id)
    }
    if let id = toAddAfter.keys.first {
      throw error(operation: "addAfter", id: id)
    }
    if let id = toReplace.keys.first {
      throw error(operation: "replace", id: id)
    }

    toAddFirst.removeAll()
    toAddLast.removeAll()
    toReplace.removeAll()
  }

  private func error(operation: String, id: EditorComponentID) -> EditorError {
    .init(
      // swiftlint:disable:next line_length
      "The '\(operation)' operation was invoked with id '\(id.value)' which does not exist in the source array or is already removed via remove API."
    )
  }
}

/// A helper that is used as a group type for the ``ArrayModifier`` when no grouping is needed.
public struct None: Hashable {}

extension ArrayModifier where Group == None {
  func apply(to elements: inout [Element]) throws {
    var groups = [None(): elements]
    try apply(to: &groups)
    elements = groups[None(), default: []]
  }
}

public extension ArrayModifier where Group == None {
  /// Appends an array of `elements`.
  /// - Parameter elements: A builder closure to evaluate the elements that should be appended.
  func addLast(@ArrayBuilder<Element> _ elements: () -> [Element]) {
    toAddLast[None(), default: []].append(contentsOf: elements())
  }

  /// Prepends an array of `elements`.
  /// - Parameter elements: A builder closure to evaluate the elements that should be prepended.
  func addFirst(@ArrayBuilder<Element> _ elements: () -> [Element]) {
    toAddFirst[None(), default: []].insert(contentsOf: elements(), at: 0)
  }
}

public extension ArrayModifier {
  /// Inserts an array of `elements` after the element with the specified `id`.
  /// - Parameters:
  ///   - id: The id of the element after which the `elements` should be inserted.
  ///   - elements: A builder closure to evaluate the elements that should be inserted.
  /// - Note: An error will be thrown if no element exists with the provided `id` when the modifications are applied.
  func addAfter(id: EditorComponentID, @ArrayBuilder<Element> _ elements: () -> [Element]) {
    toAddAfter[id, default: []].insert(contentsOf: elements(), at: 0)
  }

  /// Inserts an array of `elements` before the element with the specified `id`.
  /// - Parameters:
  ///   - id: The id of the element before which the `elements` should be inserted.
  ///   - elements: A builder closure to evaluate the elements that should be inserted.
  /// - Note: An error will be thrown if no element exists with the provided `id` when the modifications are applied.
  func addBefore(id: EditorComponentID, @ArrayBuilder<Element> _ elements: () -> [Element]) {
    toAddBefore[id, default: []].append(contentsOf: elements())
  }

  /// Replaces the element with the specified `id` with an array of `elements`.
  /// - Parameters:
  ///   - id: The id of the element that should be replaced.
  ///   - elements: A builder closure to evaluate the elements that should be the replacement.
  /// - Note: An error will be thrown if no element exists with the provided `id` when the modifications are applied.
  func replace(id: EditorComponentID, @ArrayBuilder<Element> _ elements: () -> [Element]) {
    toReplace[id] = elements()
  }

  /// Removes the element with the specified `id`.
  /// - Parameter id: The id of the element that should be removed.
  /// - Note: An error will be thrown if no element exists with the provided `id` when the modifications are applied.
  func remove(id: EditorComponentID) {
    toRemove.insert(id)
  }
}
