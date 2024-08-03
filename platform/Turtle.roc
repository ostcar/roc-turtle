# example of how to define an effect from the platform
module [forward, backward, left, right]

import Effect
import Task exposing [Task]

forward : U64 -> Task {} Str
forward = \distance ->
    Effect.forward distance
    |> Task.fromEffect


backward : U64 -> Task {} Str
backward = \distance ->
    Effect.backward distance
    |> Task.fromEffect


left : U64 -> Task {} Str
left = \angle ->
    Effect.left angle
    |> Task.fromEffect

right : U64 -> Task {} Str
right = \angle ->
    Effect.right angle
    |> Task.fromEffect