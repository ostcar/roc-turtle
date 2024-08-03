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
    ]
    imports []
    generates Effect with [after, map, always, forever, loop]

# effects that are provided by the host
forward : F64 -> Effect (Result {} {})
backward : F64 -> Effect (Result {} {})
left : F64 -> Effect (Result {} {})
right : F64 -> Effect (Result {} {})
