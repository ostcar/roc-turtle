app [main] {
    pf: platform "../../platform/main.roc",
}

import pf.Turtle

main =
    _ = Turtle.forward! 100
    _ = Turtle.left! 90
    _ = Turtle.forward! 100
    _ = Turtle.left! 90
    _ = Turtle.forward! 100
    _ = Turtle.left! 90
    _ = Turtle.forward! 100
    _ = Turtle.left! (90 + 45)
    _ = Turtle.forward! 130
    _ = Turtle.left! 90
    _ = Turtle.forward! 70
    _ = Turtle.left! 90
    _ = Turtle.forward! 70
    _ = Turtle.left! 90
    Turtle.forward! 130
