platform ""
    requires {} { main : Task {} {} }
    exposes [Task]
    packages {}
    imports [Task.{ Task }]
    provides [mainForHost]

mainForHost : Task {} {}
mainForHost =
    main
