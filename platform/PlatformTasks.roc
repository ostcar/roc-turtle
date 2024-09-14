hosted PlatformTasks
    exposes [
        forward,
        backward,
        left,
        right,
        goto,
        up,
        down,
    ]
    imports []

forward : F64 -> Task  {} {}
backward : F64 -> Task  {} {}
left : F64 -> Task  {} {}
right : F64 -> Task  {} {}
goto : F64, F64 -> Task  {} {}
up : Task {} {}
down : Task {} {}
