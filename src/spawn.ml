type group = DoesntExist
let group _ = DoesntExist
let task ~group:group f = ()
let kill g = ()
let sleep time f = ()
let on_read ~group:group fd (f : unit -> unit) = ()
