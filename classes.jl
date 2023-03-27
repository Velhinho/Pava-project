module Classes
export PavaObj, Class, Object, make_obj, make_class, @defclass, class_of, find_class_by_name

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

function make_class(name, direct_superclasses, direct_slots, metaclass=Class)
  direct_superclasses = direct_superclasses == [] ? [Object] : direct_superclasses
  make_obj(metaclass, name=name, direct_superclasses=direct_superclasses, slots=direct_slots)
end

macro defclass(name, superclasses, direct_slots, metaclass=Class)
  superclasses = superclasses == :([]) ? [Object] : superclasses
  obj = make_class(name, eval(superclasses), eval(direct_slots.args), metaclass)
  :($(esc(name)) = $obj)
end

@defclass(BuiltInClass, [Top], [])
@defclass(_String, [Top], [], BuiltInClass)
@defclass(_Int64, [Top], [], BuiltInClass)

function class_name(class::PavaObj)
  class.name
end

function class_direct_slots(class::PavaObj)
  class.direct_slots
end

function class_direct_superclasses(class::PavaObj)
  class.direct_superclasses
end

function class_of(class::PavaObj)
  class.class_of
end

function class_of(class)
  name = "_" * string(typeof(class))
  find_class_by_name(Symbol(name))
end

function find_class_by_name(class_name::Symbol)
  eval(class_name)
end

# GenericFunction = make_class(:GenericFunction, [], [:methods])
@defclass(GenericFunction, [], [methods])

# Method = make_class(:Method, [], [:specializers, :native_function])
@defclass(Method, [], [specializers, native_function])

function make_generic_function(args...)
  make_obj(GenericFunction, args=args, methods=[])
end

macro defgeneric(form)
  name = form.args[1]
  params = form.args[2:end]
  gen_func = make_generic_function(params)
  :($(esc(name)) = $gen_func)
end

function add_method(generic_function, method)
  push!(generic_function.methods, method)
end

function make_method(generic_function, specializers, native_function)
  method = make_obj(Method; specializers=specializers, native_function=native_function)
  add_method(generic_function, method)
  method
end


function parse_param_type(param::Symbol)
  :Object
end

function parse_param_type(param::Expr)
  param.args[2]
end

function parse_specializers(params)
  map(parse_param_type, params)
end

function remove_specializer(param::Symbol)
  param
end

function remove_specializer(param::Expr)
  param.args[1]
end

macro defmethod(form)
  name = form.args[1].args[1]
  params = form.args[1].args[2:end]
  body = form.args[2]
  specializers = map(find_class_by_name, parse_specializers(params))
  clean_params = map(remove_specializer, params)
  esc(:(make_method($name, $specializers, ($(clean_params...),) -> $body)))
end

function is_applicable(method, args)
  if length(method.specializers) != length(args)
    return false
  end
  for (specializer, arg) in zip(method.specializers, args)
    if !(specializer in compute_cpl(class_of(arg)))
      return false
    end
  end
  return true
end

function compute_distance(specializer, arg)
  cpl = compute_cpl(class_of(arg))
  findfirst(map(x -> x == specializer, cpl))
end

function compare_methods(method1, method2, args)
  d1 = map(t -> compute_distance(t...), zip(method1.specializers, args))
  d2 = map(t -> compute_distance(t...), zip(method2.specializers, args))
  d1 < d2
end

function find_applicable_methods(methods, args)
  applicable_methods = filter(method -> is_applicable(method, args), methods)
  sort!(applicable_methods, lt=(m1, m2) -> compare_methods(m1, m2, args))
  applicable_methods
end

function (gen_func::PavaObj)(args...)
  # This is called when generic function is called
  methods = gen_func.methods
  applicable_methods = find_applicable_methods(methods, args)
  applicable_methods[1].native_function(args...)
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


end
