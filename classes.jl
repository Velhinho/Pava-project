module Classes
export PavaObj, Class, Object, make_obj, make_class, @defclass

struct PavaObj
  obj
end

Class = PavaObj(Dict(:name => :Class, :direct_superclasses => [], :slots => [], :class_of => missing))
# FIXME
# Class.direct_superclasses = merge(Class.direct_superclasses, [Top])???
# Class[:class_of] = Class

Top = PavaObj(Dict(:name => :Top, :direct_superclasses => [], :slots => [], :class_of => Class))
Object = PavaObj(Dict(:name => :Object, :direct_superclasses => [Top], :slots => [], :class_of => Class))

function make_obj(class; kwargs...)
  obj = Dict{Symbol, Any}(:class_of => class)
  for (k, v) in kwargs
    obj[k] = v
  end
  PavaObj(obj)
end

function Base.getproperty(pava_obj::PavaObj, symbol::Symbol)
  # FIXME
  # Base.getproperty leads to infinite recursion
  getfield(pava_obj, :obj)[symbol]
end

function Base.setproperty!(pava_obj::PavaObj, symbol::Symbol, value::Any)
  setfield!(pava_obj.obj, symbol, value)
end

function make_class(name, direct_superclasses, slots, metaclass=Class)
  direct_superclasses = direct_superclasses == [] ? [Object] : direct_superclasses
  make_obj(metaclass, name=name, direct_superclasses=direct_superclasses, slots=slots)
end

macro defclass(name, superclasses, slots)
  superclasses = superclasses == :([]) ? [Object] : superclasses
  obj = make_class(name, eval(superclasses), eval(slots.args))
  :($(esc(name)) = $obj)
end

function compute_cpl(class)
  queue = [class]
  cpl = []
  while !isempty(queue)
    current_node = popfirst!(queue)
    if !(current_node in cpl)
      push!(cpl, current_node)
    end
    for parent in current_node.direct_superclasses
      push!(queue, parent)
    end
  end
  return cpl
end

@defclass(A, [], [])
@defclass(B, [], [])
@defclass(C, [], [])
@defclass(D, [A, B], [])
@defclass(E, [A, C], [])
@defclass(F, [D, E], [])

end