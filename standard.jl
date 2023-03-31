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

function check_initform(args)
  for i in args
    if isa(i, Expr)
      if in(:initform, i.args)
        return i.args[2]
      end
    end
  end
  return missing
end

function initialize(instance, initargs)
  Args = []
  for slot in (instance.class_of.slots)
    if isa(slot, Expr)
      k = slot.args[1]
      value = check_initform(slot.args)
    else
      k = slot
      value = missing
    end
    push!(Args, k)
    instance.slots[k] = value  
  end
  println(Args)
  for (k, v) in initargs
    if k in Args 
      instance.slots[k] = v
    else
      println("Argument: ", k, " isn't defined in the class: ", instance.class_of.name)
    end
  end
end

function new(class; initargs...)
  let instance = allocate_instance(class)
    initialize(instance, initargs)
    instance
  end
end

@defclass(Person, [],
[[name, reader=get_name, writer=set_name!],
[age, reader=get_age, writer=set_age!, initform=0],
[friend, reader=get_friend, writer=set_friend!]],
metaclass=UndoableClass)

@defclass(ComplexNumber, [], [real, img])

p1 = new(Person)
# println(getproperty(p1, :age))

c1 = new(ComplexNumber, real=1, img=2)
print(p1.slots)
print(c1.slots)
# println(getproperty(c1, :real))



end