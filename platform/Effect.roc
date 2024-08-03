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
forward : U64 -> Effect (Result {} Str)
backward: U64 -> Effect (Result {} Str)
left: U64 -> Effect (Result {} Str)
right: U64 -> Effect (Result {} Str)
