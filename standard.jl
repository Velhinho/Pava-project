include("classes.jl")
include("methods.jl")
module standard
using Main.Classes
using Main.Methods


@defclass(UninitializedObj, [], [])

#@defgeneric allocate_instance(class)

#@defgeneric initialize(instance, args)



function allocate_instance(class)
  obj = Dict(:name => class.name, :direct_superclasses => class.direct_superclasses, :slots => Dict{Symbol, Any}(), :class_of => class)
  PavaObj(obj)
end

function initialize(instance, initargs)
  if length(initargs) == length(instance.class_of.slots)
    i = 1
    for (k, v) in initargs
      if k == instance.class_of.slots[i]
        instance.slots[k] = v
      else
        break
      end
    i += 1
    end
  end
end

function new(class; initargs...)
  let instance = allocate_instance(class)
    initialize(instance, initargs)
    instance
  end
end
@defclass(ComplexNumber, [], [])
c1 = new(ComplexNumber)
println(c1)
end