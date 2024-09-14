module [forward, backward, left, right, goto, up, down]

import PlatformTasks

forward : F64 -> Task {} {}
forward = \distance ->
    PlatformTasks.forward distance

backward : F64 -> Task {} {}
backward = \distance ->
    PlatformTasks.backward distance

left : F64 -> Task {} {}
left = \angle ->
    PlatformTasks.left angle

right : F64 -> Task {} {}
right = \angle ->
    PlatformTasks.right angle

goto : F64, F64 -> Task {} {}
goto = \x, y ->
    PlatformTasks.goto x y

up : Task {} {}
up =
    PlatformTasks.up

down : Task {} {}
down =
    PlatformTasks.down
