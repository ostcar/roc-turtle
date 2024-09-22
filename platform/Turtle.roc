module [forward, backward, left, right, goto, up, down]

import PlatformTasks

forward : F32 -> Task {} {}
forward = \distance ->
    PlatformTasks.forward distance

backward : F32 -> Task {} {}
backward = \distance ->
    PlatformTasks.backward distance

left : F32 -> Task {} {}
left = \angle ->
    PlatformTasks.left angle

right : F32 -> Task {} {}
right = \angle ->
    PlatformTasks.right angle

goto : F32, F32 -> Task {} {}
goto = \x, y ->
    PlatformTasks.goto x y

up : Task {} {}
up =
    PlatformTasks.up

down : Task {} {}
down =
    PlatformTasks.down
