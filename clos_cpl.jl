function clos_compute_cpl(class)
  linearize(list_of_classes) = begin
    if isempty(list_of_classes)
      return []
    end
    for candidate in list_of_classes
      if all_parents_before(candidate, list_of_classes)
        return append!([candidate], linearize(filter(c -> c != candidate, list_of_classes)))
      end
    end
    throw("Cannot linearize classes")
  end

  all_parents_before(candidate, list_of_classes) = begin
    for parent in candidate.direct_superclasses
      if any([!is_before(parent, c, list_of_classes) for c in filter(x -> x != candidate, list_of_classes)])
        return false
      end
    end
    return true
  end

  is_before(class1, class2, list_of_classes) = begin
    index1 = findfirst(c -> c == class1, list_of_classes)
    index2 = findfirst(c -> c == class2, list_of_classes)
    for c in list_of_classes[index1+1:index2]
      if !(class1 in c.direct_superclasses)
        return false
      end
    end
    return true
  end

  list_of_classes = [class]
  for parent in class.direct_superclasses
    push!(list_of_classes, standard_compute_cpl(parent)...)
  end
  return linearize(list_of_classes)
end

@defclass(A, [], [])
@defclass(B, [], [])
@defclass(C, [], [])
@defclass(D, [A, B], [])
@defclass(E, [A, C], [])
@defclass(F, [D, E], [])

map(c -> c.name, clos_compute_cpl(F))
