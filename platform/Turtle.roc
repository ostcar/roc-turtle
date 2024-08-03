# example of how to define an effect from the platform
module [forward, backward, left, right]

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
