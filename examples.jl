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
c1 = make_obj(ComplexNumber; real=1, img=2)
print_object(c1, stdout)


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
