include("classes.jl")
include("methods.jl")
module standard
using Main.Classes
using Main.Methods


@defclass(UninitializedObj, [], [])

@defgeneric allocate_instance(class)

@defgeneric initialize(instance, args)

function new(class; kwargs...)
  let instance = allocate_instance(class)
    initialize(instance, kwargs)
    instance
  end
end

end