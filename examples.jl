@defclass(Device, [], [])
@defclass(Shape, [], [])

@defgeneric draw(shape, device)

@defclass(Line, [Shape], [])
@defclass(Circle, [Shape], [])

@defclass(Screen, [Device], [])
@defclass(Printer, [Device], [])

@defmethod draw(shape::Line, device::Screen) = println("line screen")
@defmethod draw(shape::Circle, device::Screen) = println("circle screen")
@defmethod draw(shape::Circle, device::Printer) = println("circle printer")
@defmethod draw(shape::Line, device::Printer) = println("line printer")
@defmethod draw(shape::Circle, device::_String) = println("circle string")
@defmethod draw(shape::_Int64, device::_String) = println("int64 string")

for m in find_applicable_methods(draw.methods, [make_obj(Line), make_obj(Screen)])
  m.native_function(missing, missing)
end

draw(make_obj(Circle), "Hello")
draw(123, "Hello")

@defclass(ComplexNumber, [], [real, img])
c1 = new(ComplexNumber, real = 1, img = 2)
println(getproperty(c1, :real))
c1 = make_obj(ComplexNumber; real=1, img=2)
print_object(c1, stdout)

#= this is wrong - setproperty is putting the property inside the object
println(getproperty(c1, :real))
#1
println(c1.real)
#1
println(setproperty!(c1, :imag, -1))
#-1
c1.imag += 3
println(c1.imag)
#2
=#

@defclass(Person, [],
[[name, reader=get_name, writer=set_name!],
[age, reader=get_age, writer=set_age!, initform=0],
[friend, reader=get_friend, writer=set_friend!]],
metaclass=UndoableClass)

p1 = new(Person)
println(getproperty(p1, :age))
print(p1.slots)

@defclass(Foo, [], [a=1, b=2])
@defclass(Bar, [], [b=3, c=4])
@defclass(FooBar, [Foo, Bar], [a=5, d=6])
foobar1 = new(FooBar)
println(foobar1.slots)