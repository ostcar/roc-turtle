# example of how to define an effect from the platform
module [forward, backward, left, right, goto, up, down]

import Effect
import Task exposing [Task]

forward : F64 -> Task {} {}
forward = \distance ->
    Effect.forward distance
    |> Task.fromEffect

backward : F64 -> Task {} {}
backward = \distance ->
    Effect.backward distance
    |> Task.fromEffect

left : F64 -> Task {} {}
left = \angle ->
    Effect.left angle
    |> Task.fromEffect

right : F64 -> Task {} {}
right = \angle ->
    Effect.right angle
    |> Task.fromEffect

goto : F64, F64 -> Task {} {}
goto = \x, y ->
    Effect.goto x y
    |> Task.fromEffect

up : Task {} {}
up = 
    Effect.up
    |> Task.fromEffect

down : Task {} {}
down = 
    Effect.down
    |> Task.fromEffect