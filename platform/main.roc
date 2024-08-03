platform ""
    requires {} { main : Task {} Str }
    exposes [Task]
    packages {}
    imports [Task.{ Task }]
    provides [mainForHost]

mainForHost : Task {} Str
mainForHost =
    main
