app [main] {
    pf: platform "../../platform/main.roc",
}

import pf.Task
import pf.Turtle

main = 
    Turtle.forward 100
    |> Task.await \_ ->
        Turtle.left 90
        |> Task.await \_ ->
            Turtle.forward 100
            |> Task.await \_ ->
                Turtle.right 90
                |> Task.await \_ ->
                    Turtle.forward 100