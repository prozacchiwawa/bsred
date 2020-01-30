open Key

let test_edit = Main.edit "hi.txt" "(* Hi there *)\nlet x = 3"
let keys = [
  Down ;
  Down ;
  End ;
  Return ;
  Letter_l ;
  Letter_e ;
  Letter_t ;
  Space ;
  Letter_y ;
  Space ;
  Equal ;
  Space ;
  Digit_5 ;
  Return ;
  Ctrl_s
  ]

let frame = Render.new_frame 10 10
let _ =
  List.iter
    (fun key ->
       State.on_key_press test_edit key;
       State.render test_edit frame;
       let events = Render.render frame in
       events |> Array.iter
         (function
           | Render.SetChar (x,y,c) ->
             let chars = Array.init (String.length c.cellChar) (fun i -> String.get c.cellChar i) in
             let charIdxs = Array.map (fun c -> string_of_int (Char.code c)) chars in
             let showing = String.concat " " (Array.to_list charIdxs) in
             print_endline ((string_of_int x) ^ " " ^ (string_of_int y) ^ " " ^ (Term.show_color c.cellStyle.fg) ^ " " ^ (Term.show_color c.cellStyle.bg) ^ " " ^ showing)
           | Render.TextMsg m -> print_endline ("msg " ^ m.value)
         )
    ) keys
let _ = List.iter (fun (f : File.t) -> print_endline (Text.to_string f.text)) test_edit.files
