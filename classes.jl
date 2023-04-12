module Classes
export PavaObj, Class, Object, make_obj, make_class, @defclass, class_of, find_class_by_name

struct PavaObj
  obj
end

Class = PavaObj(Dict(:name => :Class, :direct_superclasses => [], :slots => [], :class_of => missing))
Class.obj[:class_of] = Class

Top = PavaObj(Dict(:name => :Top, :direct_superclasses => [], :slots => [], :class_of => Class))
Object = PavaObj(Dict(:name => :Object, :direct_superclasses => [Top], :slots => [], :class_of => Class))
Class.obj[:direct_superclasses] = [Object]

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

function get_slot_name(slot::Symbol)
  slot
end

function get_slot_name(slot::Expr)
  slot.args[1]
end

function get_reader(slot::Symbol, class)
  []
end

function get_reader(slot::Expr, class)
  slot_name = get_slot_name(slot)
  option = []
  for expr in slot.args[2:end]
    if expr.args[1] == :reader
      func_name = expr.args[2]
      body = quote
        @defgeneric $(esc(func_name))(o::$(esc(class)))
        @defmethod $(esc(func_name))(o::$(esc(class))) = o. $slot_name
      end
      option = [body]
    end
  end
  return option
end

function get_readers(direct_slots, class)
  append!([], map(slot -> get_reader(slot, class), direct_slots.args)...)
end

function get_writer(slot::Symbol, class)
  []
end

function get_writer(slot::Expr, class)
  slot_name = get_slot_name(slot)
  option = []
  for expr in slot.args[2:end]
    if expr.args[1] == :writer
      func_name = expr.args[2]
      body = quote
        @defgeneric $(esc(func_name))(o::$(esc(class)), v)
        @defmethod $(esc(func_name))(o::$(esc(class)), v) = o. $slot_name = v
      end
      option = [body]
    end
  end
  return option
end

function get_writers(direct_slots, class)
  append!([], map(slot -> get_writer(slot, class), direct_slots.args)...)
end

macro defclass(name, superclasses, direct_slots, metaclass=:(Class))
  readers = get_readers(direct_slots, name)
  writers = get_writers(direct_slots, name)
  superclasses = superclasses == :([]) ? :([Object]) : superclasses
  quoted_name = QuoteNode(name)
  quoted_slots = QuoteNode(map(get_slot_name, direct_slots.args))
  quote
    $(esc(name)) = make_class($quoted_name, $superclasses, $quoted_slots, $metaclass)
    $(readers...)
    $(writers...)
  end
end

@defclass(BuiltInClass, [Top], [], Class)
@defclass(_String, [], [], BuiltInClass)
@defclass(_Int64, [], [], BuiltInClass)

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

function class_of(class::Int64)
  _Int64
end

function class_of(class::String)
  _String
end

function class_of(class)
  Top
end

function metaclass_of(class)
  class_of(class_of(class))
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
  :($(esc(name)) = make_generic_function($params))
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
  :Top
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
  specializers = parse_specializers(params)
  clean_params = map(remove_specializer, params)
  :(make_method($(esc(name)), [$(specializers...)], (call_next_method, $(clean_params...)) -> $body))
end

function is_applicable(method, args)
  if length(method.specializers) != length(args)
    return false
  end
  for (specializer, arg) in zip(method.specializers, args)
    meta = metaclass_of(arg)
    class = class_of(arg)
    cpl =  meta == Class ? standard_compute_cpl(class) : compute_cpl(class)
    if !(specializer in cpl)
      return false
    end
  end
  return true
end

function compute_distance(specializer, arg)
  cpl = metaclass_of(arg) == Class ? standard_compute_cpl(class_of(arg)) : compute_cpl(class_of(arg))
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

function make_call_next_method(applicable_methods)
  begin
    i += 1
    applicable_methods[i].native_function(call_next_method, args...)
    call_next_method()
  end
end

function (gen_func::PavaObj)(args...)
  # This is called when generic function is called
  methods = gen_func.methods
  applicable_methods = find_applicable_methods(methods, args)
  i = 0
  call_next_method = () -> begin
    i += 1
    applicable_methods[i].native_function(call_next_method, args...)
  end
  call_next_method()
end

function standard_compute_cpl(class)
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

@defgeneric compute_cpl(class)
@defmethod compute_cpl(class::BuiltInClass) = [class, Object, Top]

@defgeneric print_object(obj, io)
@defmethod print_object(obj::Object, io) =
  print(io, "<$(class_name(class_of(obj))) $(string(objectid(obj), base=62))>")

Base.show(io::IO, obj::PavaObj) = print_object(obj, io)

end