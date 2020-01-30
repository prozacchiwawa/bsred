# 1 "src/redl_lexer.mll"
 
  open Redl_parser

  exception Error of string

  let error x =
    Printf.ksprintf (fun s -> raise (Error s)) x

  type context =
    | Beginning_of_line
    | Not_beginning_of_line

  type state =
    {
      buffer: Buffer.t;
      mutable context: context;

      (* Queue in reverse order: new tokens are added to the front.
         When popping the queue, one must reverse it first. *)
      mutable queue_rev: token list;

      (* Queue in regular order.
         Cannot add tokens to [queue_rev] until [queue] is empty. *)
      mutable queue: token list;

      (* Parentheses and braces increment this level.
         If it is greater than 0, ignore indentation. *)
      mutable parenthesis_level: int;

      (* Stack of indentation levels that we can dedent to.
         Empty if current indentation level is 0.
         Else, the first level is the current level. *)
      mutable indentation: int list;
    }

  let push state token =
    if state.queue <> [] then invalid_arg "Redl_lexer.push";
    state.queue_rev <- token :: state.queue_rev

  let next state =
    match state.queue with
      | head :: tail ->
          state.queue <- tail;
          Some head
      | [] ->
          match List.rev state.queue_rev with
            | head :: tail ->
                state.queue_rev <- [];
                state.queue <- tail;
                Some head
            | [] ->
                None

  let set_indentation state new_indentation =
    let current_indentation =
      match state.indentation with
        | [] ->
            0
        | head :: _ ->
            head
    in
    (* Indent. *)
    if new_indentation > current_indentation then
      (
        state.indentation <- new_indentation :: state.indentation;
        if state.parenthesis_level = 0 then push state LBRACE;
      )

    (* Dedent (may have several levels dedented at once). *)
    else if new_indentation < current_indentation then
      let rec pop_indentation state =
        match state.indentation with
          | [] ->
              if new_indentation <> 0 then
                error "invalid indentation"
          | head :: tail ->
              if head > new_indentation then
                (
                  state.indentation <- tail;
                  if state.parenthesis_level = 0 then push state RBRACE;
                  pop_indentation state;
                )
              else if head < new_indentation then
                error "invalid indentation"
      in
      pop_indentation state

  let keyword = function
    | "command" -> COMMAND
    | x -> IDENTIFIER x

# 94 "src/redl_lexer.ml"
let __ocaml_lex_tables = {
  Lexing.lex_base = 
   "\000\000\252\255\075\000\254\255\255\255\001\000\193\000\028\000\
    \051\001\029\000\030\000\031\000\033\000\062\000\063\000\065\000\
    \066\000\067\000\068\000\069\000\070\000\071\000\072\000\073\000\
    \074\000\075\000\076\000\077\000\078\000\079\000\080\000\081\000\
    \082\000\084\000\085\000\087\000\088\000\089\000\090\000\091\000\
    \092\000\255\255\165\001\241\255\242\255\243\255\244\255\245\255\
    \246\255\247\255\248\255\243\001\000\000\024\002\252\255\005\000\
    \254\255\255\255\188\000\189\000\162\000\046\001\181\000\099\002\
    \118\002\191\000\128\002\056\001\152\002\241\255\242\255\243\255\
    \153\002\255\255\244\255\245\255\246\255\004\002\248\255\249\255\
    \250\255\251\255\252\255\253\255\254\255\014\002\247\255\007\000\
    ";
  Lexing.lex_backtrk = 
   "\255\255\255\255\002\000\255\255\255\255\003\000\003\000\255\255\
    \255\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\006\000\014\000\004\000\255\255\002\000\
    \255\255\255\255\014\000\255\255\255\255\005\000\255\255\005\000\
    \005\000\255\255\005\000\255\255\255\255\255\255\255\255\255\255\
    \014\000\255\255\255\255\255\255\255\255\011\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\000\000\
    ";
  Lexing.lex_default = 
   "\001\000\000\000\255\255\000\000\000\000\007\000\255\255\007\000\
    \255\255\010\000\011\000\012\000\013\000\014\000\015\000\016\000\
    \017\000\018\000\019\000\020\000\021\000\022\000\023\000\024\000\
    \025\000\026\000\027\000\028\000\029\000\030\000\031\000\032\000\
    \033\000\034\000\035\000\036\000\037\000\038\000\039\000\040\000\
    \041\000\000\000\043\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\255\255\255\255\255\255\000\000\255\255\
    \000\000\000\000\059\000\059\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\069\000\000\000\000\000\000\000\
    \074\000\000\000\000\000\000\000\000\000\255\255\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\255\255\000\000\255\255\
    ";
  Lexing.lex_trans = 
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\006\000\004\000\004\000\000\000\006\000\055\000\000\000\
    \087\000\000\000\055\000\000\000\087\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \006\000\000\000\000\000\005\000\000\000\055\000\004\000\087\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \051\000\051\000\051\000\051\000\051\000\051\000\051\000\051\000\
    \051\000\051\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\000\000\000\000\000\000\000\000\002\000\
    \000\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\000\000\000\000\
    \000\000\000\000\002\000\000\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\057\000\057\000\
    \000\000\000\000\008\000\004\000\000\000\067\000\008\000\067\000\
    \000\000\000\000\066\000\066\000\066\000\066\000\066\000\066\000\
    \066\000\066\000\066\000\066\000\000\000\000\000\000\000\000\000\
    \065\000\008\000\065\000\000\000\007\000\064\000\064\000\064\000\
    \064\000\064\000\064\000\064\000\064\000\064\000\064\000\064\000\
    \064\000\064\000\064\000\064\000\064\000\064\000\064\000\064\000\
    \064\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \003\000\003\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\003\000\255\255\255\255\255\255\
    \002\000\255\255\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\008\000\004\000\255\255\255\255\
    \008\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\008\000\255\255\255\255\007\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\000\000\063\000\063\000\
    \063\000\063\000\063\000\063\000\063\000\063\000\063\000\063\000\
    \066\000\066\000\066\000\066\000\066\000\066\000\066\000\066\000\
    \066\000\066\000\000\000\000\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\000\000\000\000\
    \000\000\000\000\002\000\062\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\055\000\057\000\
    \000\000\000\000\055\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\056\000\056\000\000\000\000\000\
    \000\000\003\000\000\000\000\000\000\000\055\000\000\000\054\000\
    \058\000\000\000\000\000\000\000\000\000\050\000\049\000\000\000\
    \000\000\000\000\052\000\000\000\000\000\051\000\051\000\051\000\
    \051\000\051\000\051\000\051\000\051\000\051\000\051\000\046\000\
    \045\000\000\000\044\000\000\000\000\000\000\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \000\000\000\000\000\000\000\000\053\000\000\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \048\000\061\000\047\000\051\000\051\000\051\000\051\000\051\000\
    \051\000\051\000\051\000\051\000\051\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\003\000\085\000\085\000\085\000\085\000\
    \085\000\085\000\085\000\085\000\085\000\085\000\086\000\086\000\
    \086\000\086\000\086\000\086\000\086\000\086\000\086\000\086\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\051\000\000\000\000\000\000\000\000\000\000\000\
    \060\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\000\000\000\000\000\000\000\000\053\000\
    \000\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\063\000\063\000\063\000\063\000\063\000\
    \063\000\063\000\063\000\063\000\063\000\000\000\000\000\000\000\
    \000\000\000\000\073\000\084\000\000\000\056\000\064\000\064\000\
    \064\000\064\000\064\000\064\000\064\000\064\000\064\000\064\000\
    \066\000\066\000\066\000\066\000\066\000\066\000\066\000\066\000\
    \066\000\066\000\071\000\082\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\063\000\000\000\000\000\000\000\000\000\000\000\
    \062\000\077\000\077\000\077\000\077\000\077\000\077\000\077\000\
    \077\000\077\000\077\000\000\000\000\000\064\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\066\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\072\000\083\000\000\000\000\000\
    \000\000\000\000\000\000\078\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\080\000\
    \000\000\000\000\000\000\081\000\000\000\079\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\076\000\000\000\075\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \070\000\255\255";
  Lexing.lex_check = 
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\005\000\255\255\000\000\055\000\255\255\
    \087\000\255\255\055\000\255\255\087\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\255\255\255\255\000\000\255\255\055\000\007\000\087\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \052\000\052\000\052\000\052\000\052\000\052\000\052\000\052\000\
    \052\000\052\000\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\255\255\255\255\255\255\255\255\000\000\
    \255\255\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\255\255\255\255\
    \255\255\255\255\002\000\255\255\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\002\000\002\000\
    \002\000\002\000\002\000\002\000\002\000\002\000\058\000\059\000\
    \255\255\255\255\006\000\006\000\255\255\060\000\006\000\060\000\
    \255\255\255\255\060\000\060\000\060\000\060\000\060\000\060\000\
    \060\000\060\000\060\000\060\000\255\255\255\255\255\255\255\255\
    \062\000\006\000\062\000\255\255\006\000\062\000\062\000\062\000\
    \062\000\062\000\062\000\062\000\062\000\062\000\062\000\065\000\
    \065\000\065\000\065\000\065\000\065\000\065\000\065\000\065\000\
    \065\000\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\005\000\006\000\006\000\006\000\006\000\006\000\006\000\
    \006\000\006\000\006\000\006\000\006\000\006\000\006\000\006\000\
    \006\000\006\000\006\000\006\000\006\000\006\000\006\000\006\000\
    \006\000\006\000\006\000\006\000\007\000\009\000\010\000\011\000\
    \006\000\012\000\006\000\006\000\006\000\006\000\006\000\006\000\
    \006\000\006\000\006\000\006\000\006\000\006\000\006\000\006\000\
    \006\000\006\000\006\000\006\000\006\000\006\000\006\000\006\000\
    \006\000\006\000\006\000\006\000\008\000\008\000\013\000\014\000\
    \008\000\015\000\016\000\017\000\018\000\019\000\020\000\021\000\
    \022\000\023\000\024\000\025\000\026\000\027\000\028\000\029\000\
    \030\000\031\000\032\000\008\000\033\000\034\000\008\000\035\000\
    \036\000\037\000\038\000\039\000\040\000\255\255\061\000\061\000\
    \061\000\061\000\061\000\061\000\061\000\061\000\061\000\061\000\
    \067\000\067\000\067\000\067\000\067\000\067\000\067\000\067\000\
    \067\000\067\000\255\255\255\255\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\255\255\255\255\
    \255\255\255\255\008\000\061\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\008\000\008\000\
    \008\000\008\000\008\000\008\000\008\000\008\000\042\000\042\000\
    \255\255\255\255\042\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\058\000\059\000\255\255\255\255\
    \255\255\006\000\255\255\255\255\255\255\042\000\255\255\042\000\
    \042\000\255\255\255\255\255\255\255\255\042\000\042\000\255\255\
    \255\255\255\255\042\000\255\255\255\255\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\255\255\042\000\255\255\255\255\255\255\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \255\255\255\255\255\255\255\255\042\000\255\255\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\042\000\042\000\042\000\042\000\042\000\042\000\042\000\
    \042\000\051\000\042\000\051\000\051\000\051\000\051\000\051\000\
    \051\000\051\000\051\000\051\000\051\000\255\255\255\255\255\255\
    \255\255\255\255\255\255\008\000\077\000\077\000\077\000\077\000\
    \077\000\077\000\077\000\077\000\077\000\077\000\085\000\085\000\
    \085\000\085\000\085\000\085\000\085\000\085\000\085\000\085\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\051\000\255\255\255\255\255\255\255\255\255\255\
    \051\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\255\255\255\255\255\255\255\255\053\000\
    \255\255\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\053\000\053\000\053\000\053\000\053\000\
    \053\000\053\000\053\000\063\000\063\000\063\000\063\000\063\000\
    \063\000\063\000\063\000\063\000\063\000\255\255\255\255\255\255\
    \255\255\255\255\068\000\072\000\255\255\042\000\064\000\064\000\
    \064\000\064\000\064\000\064\000\064\000\064\000\064\000\064\000\
    \066\000\066\000\066\000\066\000\066\000\066\000\066\000\066\000\
    \066\000\066\000\068\000\072\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\063\000\255\255\255\255\255\255\255\255\255\255\
    \063\000\072\000\072\000\072\000\072\000\072\000\072\000\072\000\
    \072\000\072\000\072\000\255\255\255\255\064\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\066\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\068\000\072\000\255\255\255\255\
    \255\255\255\255\255\255\072\000\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\072\000\
    \255\255\255\255\255\255\072\000\255\255\072\000\255\255\255\255\
    \255\255\255\255\255\255\255\255\072\000\255\255\072\000\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \068\000\072\000";
  Lexing.lex_base_code = 
   "\000\000\000\000\000\000\000\000\000\000\000\000\001\000\000\000\
    \002\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    ";
  Lexing.lex_backtrk_code = 
   "\000\000\000\000\004\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    ";
  Lexing.lex_default_code = 
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    ";
  Lexing.lex_trans_code = 
   "\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\001\000\001\000\001\000\000\000\001\000\001\000\001\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \001\000\001\000\001\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\000\
    \000\000\000\000\000\000";
  Lexing.lex_check_code = 
   "\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\000\000\006\000\008\000\255\255\000\000\006\000\008\000\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \000\000\006\000\008\000\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\255\
    \255\255\255\255\255\255";
  Lexing.lex_code = 
   "\255\001\255\255\000\001\255";
}

let rec beginning_of_line state lexbuf =
  lexbuf.Lexing.lex_mem <- Array.make 2 (-1) ; (* L=1 [1] <- p ;  *)
  lexbuf.Lexing.lex_mem.(1) <- lexbuf.Lexing.lex_curr_pos ;
  __ocaml_lex_beginning_of_line_rec state lexbuf 0
and __ocaml_lex_beginning_of_line_rec state lexbuf __ocaml_lex_state =
  match Lexing.new_engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 101 "src/redl_lexer.mll"
      (
        Lexing.new_line lexbuf;
      )
# 491 "src/redl_lexer.ml"

  | 1 ->
# 105 "src/redl_lexer.mll"
      (
        set_indentation state 0;
        push state EOF;
      )
# 499 "src/redl_lexer.ml"

  | 2 ->
let
# 111 "src/redl_lexer.mll"
               indentation
# 505 "src/redl_lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_mem.(0)
and
# 111 "src/redl_lexer.mll"
                                           identifier
# 510 "src/redl_lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_mem.(0) lexbuf.Lexing.lex_curr_pos in
# 112 "src/redl_lexer.mll"
      (
        set_indentation state (String.length indentation);
        push state (keyword identifier);
        state.context <- Not_beginning_of_line;
      )
# 518 "src/redl_lexer.ml"

  | 3 ->
let
# 119 "src/redl_lexer.mll"
         char
# 524 "src/redl_lexer.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 120 "src/redl_lexer.mll"
      ( error "unexpected characters: %c%s" char (parse_more lexbuf) )
# 528 "src/redl_lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_beginning_of_line_rec state lexbuf __ocaml_lex_state

and parse_more lexbuf =
    __ocaml_lex_parse_more_rec lexbuf 9
and __ocaml_lex_parse_more_rec lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
let
# 126 "src/redl_lexer.mll"
                               x
# 541 "src/redl_lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 127 "src/redl_lexer.mll"
      ( x )
# 545 "src/redl_lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_parse_more_rec lexbuf __ocaml_lex_state

and not_beginning_of_line state lexbuf =
    __ocaml_lex_not_beginning_of_line_rec state lexbuf 42
and __ocaml_lex_not_beginning_of_line_rec state lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 133 "src/redl_lexer.mll"
      (
        Lexing.new_line lexbuf;
        if state.parenthesis_level = 0 then (
          state.context <- Beginning_of_line;
          push state SEMI;
        );
      )
# 563 "src/redl_lexer.ml"

  | 1 ->
# 141 "src/redl_lexer.mll"
      (
        push state SEMI;
        set_indentation state 0;
        state.context <- Beginning_of_line;
        push state EOF;
      )
# 573 "src/redl_lexer.ml"

  | 2 ->
# 150 "src/redl_lexer.mll"
      ()
# 578 "src/redl_lexer.ml"

  | 3 ->
# 154 "src/redl_lexer.mll"
      ( string state lexbuf )
# 583 "src/redl_lexer.ml"

  | 4 ->
let
# 157 "src/redl_lexer.mll"
                  x
# 589 "src/redl_lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 158 "src/redl_lexer.mll"
      ( push state (keyword x) )
# 593 "src/redl_lexer.ml"

  | 5 ->
let
# 159 "src/redl_lexer.mll"
                                                                                  x
# 599 "src/redl_lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 160 "src/redl_lexer.mll"
      (
        let value =
          try
            float_of_string x
          with _ ->
            error "invalid float literal: %S" x
        in
        push state (FLOAT value)
      )
# 611 "src/redl_lexer.ml"

  | 6 ->
let
# 169 "src/redl_lexer.mll"
                                     x
# 617 "src/redl_lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos lexbuf.Lexing.lex_curr_pos in
# 170 "src/redl_lexer.mll"
      (
        let value =
          try
            int_of_string x
          with _ ->
            error "invalid integer literal: %S" x
        in
        push state (INT value)
      )
# 629 "src/redl_lexer.ml"

  | 7 ->
# 180 "src/redl_lexer.mll"
      (
        state.parenthesis_level <- state.parenthesis_level + 1;
        push state LPAR;
      )
# 637 "src/redl_lexer.ml"

  | 8 ->
# 185 "src/redl_lexer.mll"
      (
        state.parenthesis_level <- state.parenthesis_level - 1;
        push state RPAR;
      )
# 645 "src/redl_lexer.ml"

  | 9 ->
# 190 "src/redl_lexer.mll"
      (
        state.parenthesis_level <- state.parenthesis_level + 1;
        push state LBRACE;
      )
# 653 "src/redl_lexer.ml"

  | 10 ->
# 195 "src/redl_lexer.mll"
      (
        state.parenthesis_level <- state.parenthesis_level - 1;
        push state RBRACE;
      )
# 661 "src/redl_lexer.ml"

  | 11 ->
# 200 "src/redl_lexer.mll"
      ( push state COLON )
# 666 "src/redl_lexer.ml"

  | 12 ->
# 202 "src/redl_lexer.mll"
      ( push state SEMI )
# 671 "src/redl_lexer.ml"

  | 13 ->
# 204 "src/redl_lexer.mll"
      ( push state EQUAL )
# 676 "src/redl_lexer.ml"

  | 14 ->
let
# 207 "src/redl_lexer.mll"
         char
# 682 "src/redl_lexer.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 208 "src/redl_lexer.mll"
      ( error "unexpected characters: %c%s" char (parse_more lexbuf) )
# 686 "src/redl_lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_not_beginning_of_line_rec state lexbuf __ocaml_lex_state

and string state lexbuf =
    __ocaml_lex_string_rec state lexbuf 68
and __ocaml_lex_string_rec state lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 212 "src/redl_lexer.mll"
    (
      Lexing.new_line lexbuf;
      Buffer.add_char state.buffer '\n';
      string state lexbuf
    )
# 702 "src/redl_lexer.ml"

  | 1 ->
# 218 "src/redl_lexer.mll"
    ( Lexing.new_line lexbuf; blank_then_string state lexbuf )
# 707 "src/redl_lexer.ml"

  | 2 ->
# 220 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer '\\'; string state lexbuf )
# 712 "src/redl_lexer.ml"

  | 3 ->
# 222 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer '"'; string state lexbuf )
# 717 "src/redl_lexer.ml"

  | 4 ->
# 224 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer '\r'; string state lexbuf )
# 722 "src/redl_lexer.ml"

  | 5 ->
# 226 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer '\n'; string state lexbuf )
# 727 "src/redl_lexer.ml"

  | 6 ->
# 228 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer '\t'; string state lexbuf )
# 732 "src/redl_lexer.ml"

  | 7 ->
# 230 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer '\b'; string state lexbuf )
# 737 "src/redl_lexer.ml"

  | 8 ->
let
# 231 "src/redl_lexer.mll"
                                           x
# 743 "src/redl_lexer.ml"
= Lexing.sub_lexeme lexbuf (lexbuf.Lexing.lex_start_pos + 1) (lexbuf.Lexing.lex_start_pos + 4) in
# 232 "src/redl_lexer.mll"
    (
      let char =
        try
          Char.chr (int_of_string x)
        with Invalid_argument _ ->
          error "invalid character: \\%s" x
      in
      Buffer.add_char state.buffer char; string state lexbuf )
# 754 "src/redl_lexer.ml"

  | 9 ->
# 241 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer '{'; string state lexbuf )
# 759 "src/redl_lexer.ml"

  | 10 ->
# 243 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer '}'; string state lexbuf )
# 764 "src/redl_lexer.ml"

  | 11 ->
let
# 244 "src/redl_lexer.mll"
              s
# 770 "src/redl_lexer.ml"
= Lexing.sub_lexeme lexbuf lexbuf.Lexing.lex_start_pos (lexbuf.Lexing.lex_start_pos + 2) in
# 245 "src/redl_lexer.mll"
    ( error "invalid character: %s" s )
# 774 "src/redl_lexer.ml"

  | 12 ->
# 247 "src/redl_lexer.mll"
    (
      let s = Buffer.contents state.buffer in
      Buffer.clear state.buffer;
      push state (STRING s)
    )
# 783 "src/redl_lexer.ml"

  | 13 ->
# 253 "src/redl_lexer.mll"
    ( error "string not terminated" )
# 788 "src/redl_lexer.ml"

  | 14 ->
let
# 254 "src/redl_lexer.mll"
         c
# 794 "src/redl_lexer.ml"
= Lexing.sub_lexeme_char lexbuf lexbuf.Lexing.lex_start_pos in
# 255 "src/redl_lexer.mll"
    ( Buffer.add_char state.buffer c; string state lexbuf )
# 798 "src/redl_lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_string_rec state lexbuf __ocaml_lex_state

and blank_then_string state lexbuf =
    __ocaml_lex_blank_then_string_rec state lexbuf 87
and __ocaml_lex_blank_then_string_rec state lexbuf __ocaml_lex_state =
  match Lexing.engine __ocaml_lex_tables __ocaml_lex_state lexbuf with
      | 0 ->
# 260 "src/redl_lexer.mll"
    ( string state lexbuf )
# 810 "src/redl_lexer.ml"

  | __ocaml_lex_state -> lexbuf.Lexing.refill_buff lexbuf; 
      __ocaml_lex_blank_then_string_rec state lexbuf __ocaml_lex_state

;;

# 262 "src/redl_lexer.mll"
 

  let start () =
    {
      buffer = Buffer.create 256;
      context = Beginning_of_line;
      queue = [];
      queue_rev = [];
      parenthesis_level = 0;
      indentation = [];
    }

  let show = function
    | INT _ -> "INT"
    | FLOAT _ -> "FLOAT"
    | IDENTIFIER _ -> "IDENTIFIER"
    | STRING _ -> "STRING"
    | LPAR -> "LPAR"
    | RPAR -> "RPAR"
    | LBRACE -> "LBRACE"
    | RBRACE -> "RBRACE"
    | COLON -> "COLON"
    | SEMI -> "SEMI"
    | EQUAL -> "EQUAL"
    | COMMAND -> "COMMAND"
    | EOF -> "EOF"

  let rec token state lexbuf =
    match next state with
      | Some token ->
          (* print_endline (show token); *)
          token
      | None ->
          match state.context with
            | Beginning_of_line ->
                beginning_of_line state lexbuf;
                token state lexbuf
            | Not_beginning_of_line ->
                not_beginning_of_line state lexbuf;
                token state lexbuf


# 860 "src/redl_lexer.ml"
