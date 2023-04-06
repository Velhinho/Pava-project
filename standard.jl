include("classes.jl")
include("methods.jl")
module standard
using Main.Classes
using Main.Methods

@defclass(UninitializedObj, [], [])

end