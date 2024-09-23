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

forward : F32 -> Task {} {}
backward : F32 -> Task {} {}
left : F32 -> Task {} {}
right : F32 -> Task {} {}
goto : F32, F32 -> Task {} {}
up : Task {} {}
down : Task {} {}
