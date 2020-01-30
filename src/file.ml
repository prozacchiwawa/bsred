type mark =
  {
    mutable x: int;
    mutable y: int;
  }

type cursor =
  {
    selection_start: mark;
    position: mark;
    mutable preferred_x: int;
    clipboard: Clipboard.t;
    search_start: mark;
  }

(* Test whether a mark is before another mark. *)
let (<%) m1 m2 = m1.y < m2.y || (m1.y = m2.y && m1.x < m2.x)
let (<=%) m1 m2 = m1.y < m2.y || (m1.y = m2.y && m1.x <= m2.x)

let min_mark a b =
  if a <% b then a else b

let max_mark a b =
  if a <=% b then b else a

let selection_boundaries cursor =
  if cursor.position <% cursor.selection_start then
    cursor.position, cursor.selection_start
  else
    cursor.selection_start, cursor.position

let cursor_is_in_selection x y cursor =
  let left, right = selection_boundaries cursor in
  let xy = { x; y } in
  left <=% xy && xy <% right

let selection_is_empty cursor =
  cursor.position.x = cursor.selection_start.x &&
  cursor.position.y = cursor.selection_start.y

type loading =
  | No
  | File of { loaded: int; size: int; sub_strings_rev: (string * int) list }
  | Process of string

type 'state stylist_status =
  (* Notĥing to do, style is already up-to-date. *)
  | Up_to_date

  (* Going backwards, looking for the beginning of the token which we just modified. *)
  | Search_beginning of {
      next_x: int; (* next position to read (backwards), must start one character before edits *)
      next_y: int;
      end_x: int; (* must update at least until this position *)
      end_y: int;
    }

  (* Going forwards, parsing tokens. *)
  | Parse of {
      start_x: int; (* current token position *)
      start_y: int;
      state: 'state; (* state before next *)
      next_x: int; (* next position to read *)
      next_y: int;
      end_x: int; (* must update at least until this position *)
      end_y: int;
    }

type 'state stylist_module =
  {
    (* Initial state, i.e. the state before reading position [(0, 0)]. *)
    start: 'state;

    (* Test whether two states are similar enough to stop parsing.
       Should most often be [(=)]. *)
    equivalent: 'state -> 'state -> bool;

    (* Update the state of a parser after reading one character.

       Usage: [add_char char continue start state]

       Shall call [continue] when the current token is not finished, i.e. [char] is part of it.
       The state can change though; its new value shall be given to [continue].

       Shall call [start] when the current token finishes, i.e. [char] is part of a new token.
       The style of the token which just finished shall be given to [start], as well as the new state. *)
    add_char: 'a. Character.t -> 'state -> ('state -> 'a) -> (Style.t -> 'state -> 'a) -> 'a;

    (* Get the color of the final token. *)
    end_of_file: 'state -> Style.t;
  }

type packed_stylist_module = Stylist_module: 'a stylist_module -> packed_stylist_module

type 'state stylist =
  {
    stylist_module: 'state stylist_module;

    (* For each position [(x, y)], [state] contains the state
       just before the character at this position is added.

       Note that we do not store the state before newlines characters,
       as we maintain [state] to have the same shape as the file [text]. *)
    mutable state: 'state Text.t;

    (* Stylists run concurrently in their own spawn group.
       Only one of them may run at any given time, until the whole region denoted by [need_to_update_*] fields
       has been updated.
       Status is [None] if style is up to date. *)
    mutable status: 'state stylist_status;

    (* If a stylist is running in the background, [group] contains its group. *)
    mutable group: Spawn.group option;
  }

type packed_stylist = Stylist: 'a stylist -> packed_stylist

module History_context =
struct
  type t =
    | Command
    | External_command
    | Help_page
    | Replacement_text

  let compare = Pervasives.compare
end

type choice_kind =
  | Other
  | Recent
  | Directory
  | Modified
  | Recent_modified

type choice_item = choice_kind * string

type t =
  {
    mutable views: view list;
    mutable text: Character.t Text.t;
    mutable modified: bool;
    mutable name: string;
    mutable filename: string option;
    mutable read_only: bool;

    mutable undo_stack: undo list;
    mutable redo_stack: undo list;

    (* If [loading] is [Some (loaded, size, sub_strings_rev)], only [loaded] bytes out of [size]
       have been loaded, and [text] is read-only. *)
    mutable loading: loading;
    mutable spawn_group: Spawn.group option;

    mutable live_process_ids: int list;
    mutable on_edit: unit -> unit;
    history_context: History_context.t option;

    mutable word_updater_group: Spawn.group option;
    mutable words: Trie.t;
  }

and view =
  {
    kind: view_kind;
    file: t;
    mutable scroll_x: int;
    mutable scroll_y: int;
    mutable width: int; (* set when rendering *)
    mutable height: int; (* set when rendering *)
    mutable marks: mark list;
    mutable cursors: cursor list;
    mutable style: Style.t Text.t;
    mutable stylist: packed_stylist option;
    mutable prompt: prompt option;
    mutable search: search option;
  }

and prompt =
  {
    prompt_text: string;
    validate_prompt: string -> unit;
    prompt_view: view;
  }

and search =
  {
    search_view: view;
    replacement: Character.t Text.t option;
  }

and undo =
  {
    undo_text: Character.t Text.t;
    undo_modified: bool;
    undo_views: undo_view list;
  }

and undo_view =
  {
    undo_view: view;
    undo_scroll_x: int;
    undo_scroll_y: int;
    undo_marks: undo_mark list;
    undo_style: Style.t Text.t;
    undo_stylist: packed_undo_stylist option;
  }

and undo_mark =
  {
    undo_mark: mark;
    undo_x: int;
    undo_y: int;
  }

and packed_undo_stylist = Undo_stylist: 'a undo_stylist -> packed_undo_stylist

and 'state undo_stylist =
  {
    undo_stylist_module: 'state stylist_module;
    undo_state: 'state Text.t;
    undo_status: 'state stylist_status;
  }

and search_parameters =
  {
    backwards: bool;
    case_sensitive: bool;
  }

and choice =
  {
    choice_prompt_text: string;
    validate_choice: string -> unit;
    choices: choice_item list;
    mutable choice: int; (* among choices that match the filter *)
  }

and help =
  {
    topic: string;
    links: string option Text.t;
  }

and view_kind =
  | File
  | Prompt
  | Search of search_parameters
  | List_choice of choice
  | Help of help

let get_name file =
  file.name

let has_name name file =
  file.name = name

let foreach_view file f =
  List.iter f file.views

let foreach_cursor view f =
  List.iter f view.cursors

let recenter_y view cursor =
  let scroll_for_last_line =
    Text.get_line_count view.file.text - view.height
  in
  view.scroll_y <- max 0 (min scroll_for_last_line (cursor.position.y - view.height / 2))

let recenter_x view cursor =
  view.scroll_x <- max 0 (cursor.position.x - view.width / 2)

let if_only_one_cursor view f =
  match view.cursors with
    | [ cursor ] ->
        f cursor
    | _ ->
        ()

let recenter_x_if_needed view =
  if_only_one_cursor view @@ fun cursor ->
  if cursor.position.x < view.scroll_x || cursor.position.x >= view.scroll_x + view.width - 1 then
    recenter_x view cursor

let recenter_y_if_needed view =
  if_only_one_cursor view @@ fun cursor ->
  if cursor.position.y < view.scroll_y || cursor.position.y >= view.scroll_y + view.height - 1 then
    recenter_y view cursor

let recenter_if_needed view =
  recenter_x_if_needed view;
  recenter_y_if_needed view

let max_update_style_iteration_count = 1000

let update_style_from_status view stylist status =
  let rec search_beginning iteration next_x next_y end_x end_y =
    if iteration >= max_update_style_iteration_count then
      Search_beginning { next_x; next_y; end_x; end_y }

    else
      let stylist_module = stylist.stylist_module in
      let text = view.file.text in

      (* Get previous position. *)
      let previous_position =
        if next_x > 0 then
          Some (next_x - 1, next_y)
        else if next_y > 0 then
          (* Skip newline characters until there is a non-empty line.
             A file with very large amounts of sequential empty lines means that we block for a while,
             but the alternative is to have [stylist.state] contain one more character per line and it
             is annoying to maintain. *)
          (* TODO: we can probably fix easily this actually *)
          let rec find_non_empty_line y =
            if y < 0 then
              None
            else
              let length = Text.get_line_length y text in
              if length = 0 then
                find_non_empty_line (y - 1)
              else
                Some (length - 1, y)
          in
          find_non_empty_line (next_y - 1)
        else
          None
      in

      match previous_position with
        | None ->
            (* If no previous position, just parse from the start. *)
            parse_forwards (iteration + 1) 0 0 stylist_module.start 0 0 end_x end_y

        | Some (previous_x, previous_y) ->
            (* Get character and state at previous position. *)
            let previous_character =
              match Text.get previous_x previous_y text with
                | None ->
                    Log.error "Text.get %d %d text: invalid position" previous_x previous_y;
                    assert false (* previous_position should have been None *)
                | Some character ->
                    character
            in
            let previous_state =
              match Text.get previous_x previous_y stylist.state with
                | None ->
                    Log.error "Text.get %d %d stylist.state: invalid position" previous_x previous_y;
                    assert false (* previous_position should have been None *)
                | Some state ->
                    state
            in

            (* See if previous position is the start of a token. *)
            stylist_module.add_char previous_character previous_state
              (
                fun _ ->
                  (* If not, continue to search for the beginning of a token. *)
                  search_beginning (iteration + 1) previous_x previous_y end_x end_y
              )
              (
                fun _ _ ->
                  (* If it is, start parsing from previous position. *)
                  parse_forwards (iteration + 1) previous_x previous_y previous_state previous_x previous_y end_x end_y
              )

  and parse_forwards iteration start_x start_y state next_x next_y end_x end_y =
    if iteration >= max_update_style_iteration_count then
      Parse { start_x; start_y; state; next_x; next_y; end_x; end_y }

    else
      let stylist_module = stylist.stylist_module in
      let text = view.file.text in

      let set_style style =
        view.style <- Text.map_sub ~x1: start_x ~y1: start_y ~x2: (next_x - 1) ~y2: next_y (fun _ -> style) view.style
      in

      let end_token old_state new_state new_next_x new_next_y =
        let can_stop_here =
          match old_state with
            | None ->
                false
            | Some old_state ->
                stylist_module.equivalent state old_state &&
                { x = end_x; y = end_y } <% { x = next_x; y = next_y }
        in
        if can_stop_here then
          Up_to_date
        else
          parse_forwards (iteration + 1) next_x next_y new_state new_next_x new_next_y end_x end_y
      in

      let feed_stylist_with_character old_state character new_next_x new_next_y =
        stylist_module.add_char character state
          (
            (* Token continues. *)
            fun state ->
              parse_forwards (iteration + 1) start_x start_y state new_next_x new_next_y end_x end_y
          )
          (
            (* Start of a new token. *)
            fun style state ->
              set_style style;
              end_token old_state state new_next_x new_next_y
          )
      in

      let line_count = Text.get_line_count text in
      if next_y >= line_count then
        (* End of file. *)
        (
          set_style (stylist_module.end_of_file state);
          Up_to_date
        )
      else
        let line_length = Text.get_line_length next_y text in
        if next_x >= line_length then
          (* End of line. *)
          feed_stylist_with_character None "\n" 0 (next_y + 1)
        else (
          (* Regular character. *)
          let old_state = Text.get next_x next_y stylist.state in
          stylist.state <- Text.set next_x next_y state stylist.state;
          let character =
            match Text.get next_x next_y text with
              | None ->
                  assert false (* We just checked the position above. *)
              | Some character ->
                  character
          in
          feed_stylist_with_character old_state character (next_x + 1) next_y
        )

  in
  match status with
    | Up_to_date ->
        Up_to_date
    | Search_beginning { next_x; next_y; end_x; end_y } ->
        search_beginning 0 next_x next_y end_x end_y
    | Parse { start_x; start_y; state; next_x; next_y; end_x; end_y } ->
        parse_forwards 0 start_x start_y state next_x next_y end_x end_y

let rec update_style view =
  match view.stylist with
    | None ->
        ()
    | Some (Stylist stylist) ->
        stylist.status <- update_style_from_status view stylist stylist.status;
        match stylist.status with
          | Up_to_date ->
              ()
          | _ ->
              match stylist.group with
                | None ->
                    let group = Spawn.group () in
                    stylist.group <- Some group;
                    Spawn.task ~group @@ fun () ->
                    Spawn.kill group;
                    stylist.group <- None;
                    update_style view
                | Some _ ->
                    ()

(* Update the range that a stylist must update, to include the given range. *)
let update_stylist_range ~x1 ~y1 ~x2 ~y2 view =
  match view.stylist with
    | None ->
        ()
    | Some (Stylist stylist) ->
        match stylist.status with
          | Up_to_date ->
              (* Start running stylist in background. *)
              stylist.status <-
                Search_beginning {
                  next_x = x1;
                  next_y = y1;
                  end_x = x2;
                  end_y = y2;
                };
              update_style view

          | Search_beginning { next_x = old_x1; next_y = old_y1; end_x = old_x2; end_y = old_y2 }
          | Parse { start_x = old_x1; start_y = old_y1; end_x = old_x2; end_y = old_y2 } ->
              let xy1 = { x = x1; y = y1 } in
              let xy2 = { x = x2; y = y2 } in
              let old_xy1 = { x = old_x1; y = old_y1 } in
              let old_xy2 = { x = old_x2; y = old_y2 } in
              let new_xy1 = if xy1 <% old_xy1 then xy1 else old_xy1 in
              let new_xy2 = if xy2 <% old_xy2 then old_xy2 else xy2 in
              stylist.status <-
                Search_beginning {
                  next_x = new_xy1.x;
                  next_y = new_xy1.y;
                  end_x = new_xy2.x;
                  end_y = new_xy2.y;
                }

let set_stylist_module view stylist_module =
  (* Kill old stylist. *)
  (
    match view.stylist with
      | None ->
          ()
      | Some (Stylist stylist) ->
          match stylist.group with
            | None ->
                ()
            | Some group ->
                Spawn.kill group;
                stylist.group <- None
  );

  (* Replace by new stylist. *)
  match stylist_module with
    | None ->
        (* TODO: reset style to default? (But incrementally.) *)
        view.stylist <- None
    | Some (Stylist_module stylist_module) ->
        let text = view.file.text in
        let last_line = Text.get_line_count text - 1 in
        let stylist =
          {
            stylist_module;
            state = Text.map (fun _ -> stylist_module.start) text;
            status =
              Parse {
                start_x = 0;
                start_y = 0;
                state = stylist_module.start;
                next_x = 0;
                next_y = 0;
                end_x = Text.get_line_length last_line text;
                end_y = last_line;
              };
            group = None;
          }
        in
        view.stylist <- Some (Stylist stylist);
        update_style view

let spawn_word_updater (file: t) (text: Character.t Text.t) (first: int) (last: int)
    (update_trie: Trie.word -> Trie.t -> Trie.t) =
  let group =
    match file.word_updater_group with
      | None ->
          let group = Spawn.group () in
          file.word_updater_group <- Some group;
          group
      | Some group ->
          group
  in

  (* Call [update_trie] for one word. *)
  let found_word (word_rev: Trie.word) =
    match word_rev with
      | [] ->
          ()
      | _ :: _ ->
          file.words <- update_trie (List.rev word_rev) file.words
  in

  (* Parse lines of [text] from [first] to [last] and call [update_trie] for each word. *)
  let rec parse_lines first last =
    if last >= first then (
      Spawn.task ~group @@ fun () ->
      parse_line first;
      parse_lines (first + 1) last
    )

  (* Parse the words of one line. *)
  and parse_line index =
    let line = Text.get_line index text in
    let rec parse word_rev from =
      (* If line is too long, we can't block for that long, and the line
         is probably not a very good line to parse. So we ignore the
         current word and stop parsing. Words that were already added,
         from the beginning of the line, are not removed. *)
      if from < 1000 then
        match Line.get from line with
          | None ->
              found_word word_rev
          | Some character ->
              if Character.is_big_word_character character then
                parse (character :: word_rev) (from + 1)
              else (
                found_word word_rev;
                parse [] (from + 1)
              )
    in
    parse [] 0
  in

  parse_lines first last

let add_words_of_lines file text first last =
  spawn_word_updater file text first last Trie.add

let remove_words_of_lines file text first last =
  spawn_word_updater file text first last Trie.remove

(* Move marks after text has been inserted.

   Move marks as if [lines] lines were inserted after [x, y]
   and [characters] characters were inserted after those lines.

   For instance, adding 2 lines and 10 characters means that
   line [y] becomes the beginning of [y] up to [x], plus the first new line;
   a new line is added after that; and 10 characters are added at the beginning
   of the line which was at [y + 1] and is now at [y + 2]. *)
let update_marks_after_insert ~x ~y ~characters ~lines marks =
  let xy = { x; y } in
  let move_mark mark =
    if mark <% xy then
      (* Inserting after mark: do not move mark. *)
      ()
    else (
      (* Inserting before or at mark: move mark. *)
      if mark.y = y then
        (* Inserting on the same line as the mark; x coordinate changes.

           Example 1: inserting XXX at | (i.e. [lines] is 0 and [characters] is 3):

               -------|-------M--------

           Becomes:

               -------|XXX-------M--------

           Example 2: inserting XXX\nYYYY\nZ at | (i.e. [lines] is 2 and [characters] is 1):

               -------|-------M--------

           Becomes:

               -------|XXX\n
               YYYY\n
               Z-------M--------

           Only the length of Z (i.e. [characters]) line matters for the x coordinate,
           not the length of XXX and YYYY. *)
        (
          if lines = 0 then
            mark.x <- mark.x + characters
          else
            mark.x <- mark.x - x + characters;
          mark.y <- mark.y + lines;
        )
      else
        (* Inserting on a previous line; x coordinate does not change. *)
        mark.y <- mark.y + lines
    )
  in
  List.iter move_mark marks

(* Move marks after text has been deleted.

   Move marks as if [lines] lines were deleted after [(x, y)],
   including the end of [y], and [characters] characters were deleted
   after those lines.

   For instance, deleting 2 lines and 10 characters means that
   the end of line [y] is deleted, that line [y + 1] is deleted,
   and that the first 10 characters of line [y + 2] are deleted. *)
let update_marks_after_delete ~x ~y ~characters ~lines marks =
  (* Beginning of the deleted region. *)
  let xy = { x; y } in

  (* End of the deleted region. *)
  let xy2 =
    if lines = 0 then
      { x = x + characters; y }
    else
      { x = characters; y = y + lines }
  in

  let move_mark mark =
    (* For a given mark, either the mark is:
       - before the removed region, in which case the mark does not move;
       - inside the removed region, in which case the mark moves to the beginning of this removed region;
       - after the removed region, in which case the mark moves like when inserting but in reverse. *)
    if mark <% xy then
      (* Deleting after mark: do not move mark. *)
      ()
    else if xy <=% mark && mark <=% xy2 then
      (* Mark is inside deleted region: move mark to the beginning of the deleted region. *)
      (
        mark.x <- x;
        mark.y <- y;
      )
    else (
      (* Mark is after deleted region: move it. *)
      if mark.y = xy2.y then
        (* Deleting on the same line as the mark; x coordinate changes.

           Exemple 1: deleting XXX from a single line (i.e. [lines] is 0 and [characters] is 3):

               -------XXX-----M------

           Becomes:

               ------------M------

           Example 2: deleting XXX\nYYYY\nZ (i.e. [lines] is 2 and [characters] is 1):

               -------XXX\n
               YYYY\n
               Z-----M------

           Becomes:

               ------------M------

           Once again, only the length of the last line matters. *)
        (
          mark.x <- mark.x - characters + (if lines = 0 then 0 else x);
          mark.y <- mark.y - lines;
        )
      else
        (* Deleting lines which are strictly before the mark; x coordinate does not change. *)
        mark.y <- mark.y - lines
    )
  in
  List.iter move_mark marks

let update_views_after_insert ~old_text ?(keep_marks = false) ~x ~y ~characters ~lines file =
  let views = file.views in

  (* Recompute the trie for lines which have been modified and added. *)
  let new_text = file.text in
  remove_words_of_lines file old_text y y;
  add_words_of_lines file new_text y (y + lines);

  (* Prepare a chunk of default style to insert. *)
  let style_sub =
    match views with
      | [] ->
          Text.empty
      | view :: _ ->
          (* TODO: simplify this using [new_text], probably similar to "TODO: why this special case??" *)
          let sub_region = Text.sub_region ~x ~y ~characters ~lines view.file.text in
          Text.map (fun _ -> Style.default) sub_region
  in

  (* Compute the position of the last character which was inserted. *)
  let x2 =
    if lines = 0 then
      x + characters - 1
    else
      characters - 1
  in
  let y2 = y + lines in

  (* Update all views. *)
  let update_view view =
    if not keep_marks then update_marks_after_insert ~x ~y ~characters ~lines view.marks;
    view.style <- Text.insert_text ~x ~y ~sub: style_sub view.style;
    (
      match view.stylist with
        | None ->
            ()
        | Some (Stylist stylist) ->
            let stylist_state_sub =
              match views with
                | [] ->
                    (* TODO: why this special case?? *)
                    Text.empty
                | view :: _ ->
                    let start = stylist.stylist_module.start in
                    Text.map (fun _ -> start) style_sub
            in
            stylist.state <- Text.insert_text ~x ~y ~sub: stylist_state_sub stylist.state
    );
    update_stylist_range ~x1: x ~y1: y ~x2 ~y2 view;
  in
  List.iter update_view views

let update_views_after_delete ~old_text ~x ~y ~characters ~lines file =
  (* Recompute the trie for lines which have been modified and removed. *)
  let new_text = file.text in
  remove_words_of_lines file old_text y (y + lines);
  add_words_of_lines file new_text y y;

  (* Update all views. *)
  let update_view view =
    update_marks_after_delete ~x ~y ~characters ~lines view.marks;
    view.style <- Text.delete_region ~x ~y ~characters ~lines view.style;
    (
      match view.stylist with
        | None ->
            ()
        | Some (Stylist stylist) ->
            stylist.state <- Text.delete_region ~x ~y ~characters ~lines stylist.state
    );
    (* TODO: we could optimize by reducing the "need to update" region by the region which was deleted
       if those two regions intersects. *)
    update_stylist_range ~x1: x ~y1: y ~x2: x ~y2: y view;
  in
  List.iter update_view file.views

let create_cursor x y =
  {
    selection_start = { x; y };
    position = { x; y };
    preferred_x = x;
    clipboard = { text = Text.empty };
    search_start = { x; y };
  }

(* Created by Command because of circular dependency issues: Redl depends on Redl_typing which
   depends on State which depends on File. We could circumvent this by using Redl_stylist directly
   instead of Redl.Stylist, but it may be a good idea to have stylists be declared somewhere else anyway? *)
let choose_stylist_automatically = ref (fun _ -> Log.error "set_stylist is not initialized"; assert false)

let create_view kind file =
  let cursor = create_cursor 0 0 in
  let view =
    {
      kind;
      file;
      scroll_x = 0;
      scroll_y = 0;
      width = 80;
      height = 40;
      marks = [ cursor.selection_start; cursor.position ];
      cursors = [ cursor ];
      style = Text.map (fun _ -> Style.default) file.text;
      stylist = None;
      prompt = None;
      search = None;
    }
  in
  file.views <- view :: file.views;
  !choose_stylist_automatically view;
  view

(* You may want to use [State.create_file] instead. *)
let create ?(read_only = false) ?history name text =
  {
    views = [];
    text;
    modified = false;
    name;
    filename = None;
    read_only;
    loading = No;
    undo_stack = [];
    redo_stack = [];
    spawn_group = None;
    live_process_ids = [];
    on_edit = (fun () -> ());
    history_context = history;
    word_updater_group = None;
    words = Trie.empty;
  }

(* Note: this does not kill stylists. *)
let kill_spawn_group file =
  match file.spawn_group with
    | None ->
        ()
    | Some group ->
        Spawn.kill group;
        file.spawn_group <- None

let set_filename file filename =
  file.filename <- filename;
  foreach_view file !choose_stylist_automatically

let is_read_only file =
  file.read_only ||
  match file.loading with
    | No ->
        false
    | File _ | Process _ ->
        true

(* Iterate on cursors and their clipboards.
   If there is only one cursor, use global clipboard instead of cursor clipboard. *)
let foreach_cursor_clipboard (global_clipboard: Clipboard.t) view f =
  match view.cursors with
    | [ cursor ] ->
        f global_clipboard cursor
    | cursors ->
        List.iter (fun cursor -> f cursor.clipboard cursor) cursors

let make_undo_view view =
  let make_undo_mark mark =
    {
      undo_mark = mark;
      undo_x = mark.x;
      undo_y = mark.y;
    }
  in
  {
    undo_view = view;
    undo_scroll_x = view.scroll_x;
    undo_scroll_y = view.scroll_y;
    undo_marks = List.map make_undo_mark view.marks;
    undo_style = view.style;
    undo_stylist = (
      match view.stylist with
        | None ->
            None
        | Some (Stylist stylist) ->
            Some (
              Undo_stylist {
                undo_stylist_module = stylist.stylist_module;
                undo_state = stylist.state;
                undo_status = stylist.status;
              }
            )
    );
  }

let make_undo file =
  {
    undo_text = file.text;
    undo_modified = file.modified;
    undo_views = List.map make_undo_view file.views;
  }

let set_text file text =
  if is_read_only file then
    invalid_arg "set_text: file is read-only"
  else (
    file.text <- text;
    file.modified <- true;
  )

let set_cursors view cursors =
  let marks =
    cursors
    |> List.map (fun cursor -> [ cursor.selection_start; cursor.position ])
    |> List.flatten
  in
  view.cursors <- cursors;
  view.marks <- marks

let delete_selection view cursor =
  (* Compute region. *)
  let left, right = selection_boundaries cursor in
  let { x; y } = left in
  let lines, characters =
    if right.y = y then
      (* No line split in selection. *)
      0, right.x - x
    else
      right.y - y, right.x
  in

  (* Delete selection. *)
  let file = view.file in
  let old_text = file.text in
  set_text file (Text.delete_region ~x ~y ~characters ~lines old_text);
  update_views_after_delete ~old_text ~x ~y ~characters ~lines file

let insert_character (character: Character.t) view cursor =
  let file = view.file in
  let old_text = file.text in
  set_text file (Text.insert cursor.position.x cursor.position.y character old_text);
  update_views_after_insert ~old_text ~x: cursor.position.x ~y: cursor.position.y ~characters: 1 ~lines: 0 file

let insert_new_line view cursor =
  let file = view.file in
  let old_text = file.text in
  set_text file (Text.insert_new_line cursor.position.x cursor.position.y old_text);
  update_views_after_insert ~old_text ~x: cursor.position.x ~y: cursor.position.y ~characters: 0 ~lines: 1 file

let delete_character view cursor =
  let { x; y } = cursor.position in
  let file = view.file in
  let old_text = file.text in
  let length = Text.get_line_length y old_text in
  let characters, lines = if x < length then 1, 0 else 0, 1 in
  set_text file (Text.delete_region ~x ~y ~characters ~lines old_text);
  update_views_after_delete ~old_text ~x ~y ~characters ~lines file

let delete_character_backwards view cursor =
  let { x; y } = cursor.position in
  let file = view.file in
  let old_text = file.text in
  if x > 0 then
    let x = x - 1 in
    let characters = 1 in
    let lines = 0 in
    set_text file (Text.delete_region ~x ~y ~characters ~lines old_text);
    update_views_after_delete ~old_text ~x ~y ~characters ~lines file
  else if y > 0 then
    let y = y - 1 in
    let x = Text.get_line_length y old_text in
    let characters = 0 in
    let lines = 1 in
    set_text file (Text.delete_region ~x ~y ~characters ~lines old_text);
    update_views_after_delete ~old_text ~x ~y ~characters ~lines file

let reset_preferred_x file =
  foreach_view file @@ fun view ->
  foreach_cursor view @@ fun cursor ->
  cursor.preferred_x <- cursor.position.x

let edit save_undo file f =
  if is_read_only file then
    Log.info "Buffer is read-only."
  else (
    if save_undo then
      let undo = make_undo file in
      f ();
      file.undo_stack <- undo :: file.undo_stack;
      file.redo_stack <- []
    else
      f ();
    reset_preferred_x file;

    (
      foreach_view file @@ fun view ->
      match view.kind with
        | List_choice choice ->
            choice.choice <- -1
        | _ ->
            ()
    );
    file.on_edit ()
  )

let replace_selection_by_character character view =
  (* TODO: false if consecutive *)
  edit true view.file @@ fun () ->
  foreach_cursor view @@ fun cursor ->
  delete_selection view cursor;
  insert_character character view cursor

let replace_selection_by_new_line view =
  edit true view.file @@ fun () ->
  foreach_cursor view @@ fun cursor ->
  delete_selection view cursor;
  insert_new_line view cursor

let delete_selection_or_character view =
  (* TODO: false if consecutive *)
  edit true view.file @@ fun () ->
  foreach_cursor view @@ fun cursor ->
  if selection_is_empty cursor then
    delete_character view cursor
  else
    delete_selection view cursor

let delete_selection_or_character_backwards view =
  (* TODO: false if consecutive *)
  edit true view.file @@ fun () ->
  foreach_cursor view @@ fun cursor ->
  if selection_is_empty cursor then
    delete_character_backwards view cursor
  else
    delete_selection view cursor

let delete_from_cursors view get_other_position =
  edit true view.file @@ fun () ->
  foreach_cursor view @@ fun cursor ->
  let file = view.file in
  let old_text = file.text in

  (* Get start and end positions in the right order. *)
  let x, y, x2, y2 =
    let position = cursor.position in
    let other_x, other_y = get_other_position old_text cursor in
    let other_position = { x = other_x; y = other_y } in
    if position <=% other_position then
      position.x, position.y, other_x, other_y
    else
      other_x, other_y, position.x, position.y
  in

  (* Compute the number of characters and lines to delete from (x, y), knowing that y <= y2. *)
  let characters, lines =
    if y = y2 then
      x2 - x, 0
    else
      x2, y2 - y
  in

  set_text file (Text.delete_region ~x ~y ~characters ~lines old_text);
  update_views_after_delete ~old_text ~x ~y ~characters ~lines file

let get_selected_text text cursor =
  let left, right = selection_boundaries cursor in
  (* The cursor itself is not included in the selection, hence the value of x2.
     A negative value here is not an issue for Text.sub. *)
  Text.sub ~x1: left.x ~y1: left.y ~x2: (right.x - 1) ~y2: right.y text

let copy (global_clipboard: Clipboard.t) view =
  foreach_cursor_clipboard global_clipboard view @@ fun clipboard cursor ->
  clipboard.text <- get_selected_text view.file.text cursor

let cut (global_clipboard: Clipboard.t) view =
  edit true view.file @@ fun () ->
  foreach_cursor_clipboard global_clipboard view @@ fun clipboard cursor ->
  clipboard.text <- get_selected_text view.file.text cursor;
  delete_selection view cursor

let replace file ~x ~y ~lines ~characters sub =
  edit true file @@ fun () ->

  (* Delete. *)
  let old_text = file.text in
  set_text file (Text.delete_region ~x ~y ~characters ~lines old_text);
  update_views_after_delete ~old_text ~x ~y ~characters ~lines file;

  (* Insert. *)
  let old_text = file.text in
  set_text file (Text.insert_text ~x ~y ~sub old_text);
  let lines = Text.get_line_count sub - 1 in
  let characters = Text.get_line_length lines sub in
  update_views_after_insert ~old_text ~x ~y ~characters ~lines file

let replace_selection_with_text_for_cursor view cursor sub =
  (* Replace selection with text. *)
  delete_selection view cursor;
  let x = cursor.position.x in
  let y = cursor.position.y in
  let file = view.file in
  let old_text = file.text in
  set_text file (Text.insert_text ~x ~y ~sub old_text);

  (* Update marks. *)
  let lines = Text.get_line_count sub - 1 in
  let characters = Text.get_line_length lines sub in
  update_views_after_insert ~old_text ~x ~y ~characters ~lines file

let replace_selection_with_text view sub =
  edit true view.file @@ fun () ->
  foreach_cursor view @@ fun cursor ->
  replace_selection_with_text_for_cursor view cursor sub

let paste (global_clipboard: Clipboard.t) view =
  edit true view.file @@ fun () ->
  foreach_cursor_clipboard global_clipboard view @@ fun clipboard cursor ->
  let sub = clipboard.text in
  replace_selection_with_text_for_cursor view cursor sub

let restore_view undo =
  let restore_mark undo =
    undo.undo_mark.x <- undo.undo_x;
    undo.undo_mark.y <- undo.undo_y;
  in
  undo.undo_view.scroll_x <- undo.undo_scroll_x;
  undo.undo_view.scroll_y <- undo.undo_scroll_y;
  List.iter restore_mark undo.undo_marks;
  undo.undo_view.style <- undo.undo_style;
  undo.undo_view.stylist <- (
    match undo.undo_stylist with
      | None ->
          None
      | Some (Undo_stylist undo_stylist) ->
          Some
            (
              Stylist {
                stylist_module = undo_stylist.undo_stylist_module;
                state = undo_stylist.undo_state;
                status = undo_stylist.undo_status;
                group = None;
              }
            )
  );
  update_style undo.undo_view

let restore_undo_point file undo =
  file.text <- undo.undo_text;
  file.modified <- undo.undo_modified;
  List.iter restore_view undo.undo_views

let undo file =
  edit false file @@ fun () ->
  match file.undo_stack with
    | [] ->
        Log.info "Nothing to undo."
    | undo :: remaining_stack ->
        file.undo_stack <- remaining_stack;
        file.redo_stack <- make_undo file :: file.redo_stack;
        restore_undo_point file undo

let redo file =
  edit false file @@ fun () ->
  match file.redo_stack with
    | [] ->
        Log.info "Nothing to redo."
    | undo :: remaining_stack ->
        file.undo_stack <- make_undo file :: file.undo_stack;
        file.redo_stack <- remaining_stack;
        restore_undo_point file undo

let copy_view view =
  let copy = create_view view.kind view.file in
  let undo = make_undo_view view in
  restore_view { undo with undo_view = copy };

  (* The undo / redo mechanism does not copy cursors and their marks; it reuses existing ones.
     So we need to copy them now. *)
  let marks = ref [] in
  let copy_mark (mark: mark): mark =
    let copy = { x = mark.x; y = mark.y } in
    marks := copy :: !marks;
    copy
  in
  let copy_cursor (cursor: cursor): cursor =
    {
      selection_start = copy_mark cursor.selection_start;
      position = copy_mark cursor.position;
      preferred_x = cursor.preferred_x;
      clipboard = cursor.clipboard;
      search_start = copy_mark cursor.search_start;
    }
  in
  copy.cursors <- List.map copy_cursor view.cursors;
  copy.marks <- !marks;

  copy

let get_cursor_subtext cursor text =
  let from, until = selection_boundaries cursor in
  Text.sub ~x1: from.x ~y1: from.y ~x2: (until.x - 1) ~y2: until.y text

let rec find_character_forwards text x y f =
  if y >= Text.get_line_count text then
    None
  else
    match Text.get x y text with
      | None ->
          if f "\n" then
            Some (x, y)
          else
            find_character_forwards text 0 (y + 1) f
      | Some character ->
          if f character then
            Some (x, y)
          else
            find_character_forwards text (x + 1) y f

let rec find_character_backwards text x y f =
  if y < 0 then
    None
  else if x < 0 then
    find_character_backwards text (Text.get_line_length (y - 1) text) (y - 1) f
  else
    match Text.get x y text with
      | None ->
          if f "\n" then
            Some (x, y)
          else
            find_character_backwards text (x - 1) y f
      | Some character ->
          if f character then
            Some (x, y)
          else
            find_character_backwards text (x - 1) y f

let rec find_line_forwards text y f =
  if y >= Text.get_line_count text then
    None
  else
    if f (Text.get_line y text) then
      Some y
    else
      find_line_forwards text (y + 1) f

let rec find_line_backwards text y f =
  if y < 0 then
    None
  else
    if f (Text.get_line y text) then
      Some y
    else
      find_line_backwards text (y - 1) f

let move_right text x y =
  if x >= Text.get_line_length y text then
    if y >= Text.get_line_count text - 1 then
      x, y
    else
      0, y + 1
  else
    x + 1, y

let move_left text x y =
  if x <= 0 then
    if y <= 0 then
      0, 0
    else
      Text.get_line_length (y - 1) text, y - 1
  else
    x - 1, y

let move_down text x y =
  if y >= Text.get_line_count text - 1 then
    min x (Text.get_line_length y text), y
  else
    min x (Text.get_line_length (y + 1) text), y + 1

let move_up text x y =
  if y <= 0 then
    min x (Text.get_line_length y text), y
  else
    min x (Text.get_line_length (y - 1) text), y - 1

let move_end_of_line text _ y =
  Text.get_line_length y text, y

let move_beginning_of_line text _ y =
  0, y

let move_end_of_file text _ _ =
  let y = Text.get_line_count text - 1 in
  Text.get_line_length y text, y

let move_beginning_of_file text _ _ =
  0, 0

let move_right_word ?(big = false) text x y =
  match
    find_character_forwards text x y
      (if big then Character.is_big_word_character else Character.is_word_character)
  with
    | None ->
        move_end_of_file text x y
    | Some (x, y) ->
        match
          find_character_forwards text x y
            (if big then Character.is_not_big_word_character else Character.is_not_word_character)
        with
          | None ->
              move_end_of_file text x y
          | Some (x, y) ->
              x, y

let move_left_word ?(big = false) text x y =
  (* Move left once to avoid staying at the same place if we are already at the beginning of a word. *)
  let x, y = move_left text x y in
  match
    find_character_backwards text x y
      (if big then Character.is_big_word_character else Character.is_word_character)
  with
    | None ->
        0, 0
    | Some (x, y) ->
        match
          find_character_backwards text x y
            (if big then Character.is_not_big_word_character else Character.is_not_word_character)
        with
          | None ->
              0, 0
          | Some (x, y) ->
              (* We are at just before the word, go right once to be at the beginning of the word. *)
              move_right text x y

let move_down_paragraph text x y =
  match find_line_forwards text y Line.is_not_empty with
    | None ->
        move_end_of_file text x y
    | Some y ->
        match find_line_forwards text y Line.is_empty with
          | None ->
              move_end_of_file text x y
          | Some y ->
              0, y

let move_up_paragraph text x y =
  match find_line_backwards text y Line.is_not_empty with
    | None ->
        0, 0
    | Some y ->
        match find_line_backwards text y Line.is_empty with
          | None ->
              0, 0
          | Some y ->
              0, y

type autocompletion =
  {
    (* Line where autocompletion can be done. *)
    y: int;
    (* Start of the prefix to autocomplete. *)
    start_x: int;
    (* End of the prefix to autocomplete. Not included. *)
    end_x: int;
    (* Prefix to autocomplete. *)
    prefix: Trie.word;
    (* Available suffixes for this prefix. *)
    suffixes: Trie.t;
    (* Best prefix + suffix for fast autocompletion. *)
    best_word: string;
  }

type autocompletion_result =
  | No_cursor_to_autocomplete
  | Too_many_cursors_to_autocomplete
  | Nothing_to_autocomplete
  | Word_is_on_multiple_lines
  | May_autocomplete of autocompletion

let get_autocompletion view =
  match view.cursors with
    | [] ->
        No_cursor_to_autocomplete
    | _ :: _ :: _ ->
        Too_many_cursors_to_autocomplete
    | [ cursor ] ->
        let file = view.file in
        let text = file.text in
        let end_x = cursor.position.x in
        let end_y = cursor.position.y in

        (* Check that there is something to autocomplete here. *)
        let previous_character_is_big_word =
          match Text.get (end_x - 1) end_y text with
            | None ->
                false
            | Some character ->
                Character.is_big_word_character character
        in
        if not previous_character_is_big_word then
          Nothing_to_autocomplete
        else

          (* Look for the beginning of the word to autocomplete. *)
          let start_x, start_y = move_left_word ~big: true text end_x end_y in
          if end_y <> start_y then
            Word_is_on_multiple_lines
          else

            (* Get the word to autocomplete. *)
            let line = Text.get_line end_y text in
            let prefix = Line.to_list ~ofs: start_x ~len: (end_x - start_x) line in
            let suffixes = Trie.get prefix file.words in
            let best_word = String.concat "" prefix ^ String.concat "" (Trie.best_for_autocompletion suffixes) in
            May_autocomplete {
              y = start_y;
              start_x;
              end_x;
              prefix;
              suffixes;
              best_word;
            }
