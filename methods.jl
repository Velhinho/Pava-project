include("classes.jl")
module Methods
using Main.Classes

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

function find_best_method(methods, args)
  # FIXME
  # Find best method based on the method specializers
  methods[1].native_function
end

function (gen_func::PavaObj)(args...)
  # This is called when generic function is called
  methods = gen_func.methods
  best_method = find_best_method(methods, args)
  best_method(args)
end

end