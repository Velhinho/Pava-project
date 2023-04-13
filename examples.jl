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


@defclass(Foo, [], [], metaclass=CountingClass)
@defclass(Bar, [], [], metaclass=CountingClass)
#c2 = new(Foo) isnt working, gives error BoundsError: attempt to access 0-element Vector{Any} at index [1] at classes.jl:188
new(Foo)
new(Foo)
println(Foo.class_of.slots[1]) #counter


@defclass(Foo, [], [a=1, b=2])
@defclass(Bar, [], [b=3, c=4])
@defclass(FooBar, [Foo, Bar], [a=5, d=6])
@defclass(FooBar2, [Foo, Bar], [a=3], metaclass=AvoidCollisionsClass)
foobar1 = new(FooBar)
println(foobar1.slots)

@defclass(Person, [], [])
@defclass(Student, [Person], [])

@defgeneric hello(person)
@defmethod hello(person::Person) = println("Hello person")
@defmethod hello(person::Student) = begin
  println("Hello student")
  call_next_method()
end

hello(make_obj(Person))
hello(make_obj(Student))


@defclass(Person, [], [[name, reader=get_name, writer=set_name!], [age, reader=get_age]])
@defclass(Student, [Person], [[number, initform=456]])
p = make_obj(Person; name="Joe", age=123)
get_name(p)
get_age(p)
s = new(Student, name="ola")
