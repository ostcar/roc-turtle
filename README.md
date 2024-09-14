# Roc Turtle

Roc Turtle is a platform for the [Roc programming
language](https://www.roc-lang.org/) to write programms simular to [Python
Turtle](https://docs.python.org/3/library/turtle.html)


Here is an example application:

```roc
app [main] {
    pf: platform "https://github.com/ostcar/roc-turtle/releases/download/v0.0.2/q0zfdAsWWc0qkAOl-F20LIz0gs6yiN6aIDttQJHW_fQ.tar.br"
}

import pf.Turtle

main =
    _ = Turtle.up!
    _ = Turtle.goto! 0 0
    _ = Turtle.down!
    _ = Turtle.goto! 238.834 32.1052
    _ = Turtle.goto! 372.438 190.101
    _ = Turtle.goto! 459.665 166.324
    _ = Turtle.goto! 505 220
    _ = Turtle.goto! 450 220
    _ = Turtle.goto! 440.315 263.689
    _ = Turtle.goto! 264.673 393.424
    _ = Turtle.goto! 274.527 452.132
    _ = Turtle.goto! 176.55 530
    _ = Turtle.goto! 236.751 227.086
    _ = Turtle.goto! 0 0
    _ = Turtle.up!
    Turtle.goto! 100 200
```

At the moment, the following commands are supported:
* `forward F64`: moves the cursor forwards
* `backward F64`: moves the cursor backwards
* `left F64`: spins the cursor to the left. The argument is in degree.
* `right F64`: spins the cursor to the right. The argument is in degree.
* `goto F64 F64`: Moves the cursor to the position. At the moment, the point (0,
  0) is at the top left corner. In the future, it might be in the center like in
  python.
* `up`: Put "the pen" up. Meaning, that the following moves will not draw.
* `down`: Puts "the pen" down. Meaning, that the following moves will draw.

Here is another example. Can you fix it?

```roc
app [main] {
    pf: platform "https://github.com/ostcar/roc-turtle/releases/download/v0.0.2/q0zfdAsWWc0qkAOl-F20LIz0gs6yiN6aIDttQJHW_fQ.tar.br",
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
    _ = Turtle.left! (90+45)
    _ = Turtle.forward! 130
    _ = Turtle.left! 90
    _ = Turtle.forward! 70
    _ = Turtle.left! 90
    _ = Turtle.forward! 70
    _ = Turtle.left! 90
    Turtle.forward! 130
```