app [main] {
    pf: platform "../../platform/main.roc",
}

import pf.Task
import pf.Turtle

main = Turtle.forward(100)