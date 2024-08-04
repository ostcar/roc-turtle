# this module will be replaced when effect interpreters are implemented
hosted Effect
    exposes [
        Effect,
        after,
        map,
        always,
        forever,
        loop,
        forward,
        backward,
        left,
        right,
        goto,
        up,
        down,
    ]
    imports []
    generates Effect with [after, map, always, forever, loop]

# effects that are provided by the host
forward : F64 -> Effect (Result {} {})
backward : F64 -> Effect (Result {} {})
left : F64 -> Effect (Result {} {})
right : F64 -> Effect (Result {} {})
goto : F64, F64 -> Effect (Result {} {})
up : Effect(Result {} {})
down : Effect(Result {} {})
