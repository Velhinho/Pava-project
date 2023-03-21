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
