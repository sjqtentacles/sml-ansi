(* ansi.sig — ANSI/VT escape sequence parser and builders. *)

signature ANSI =
sig
  datatype color = Default | Idx of int | Rgb of int * int * int

  datatype fragment =
      Text of string
    | Sgr of int list
    | Cursor of { row : int option, col : int option }  (* CUP 'H' *)
    | CursorMove of { dir : char, n : int }              (* A/B/C/D/E/F/G *)
    | Erase of { what : char, n : int }                  (* J / K *)
    | Scroll of { up : bool, n : int }                   (* S / T *)
    | Save | Restore                                      (* s / u *)
    | Unknown of string

  val parse  : string -> fragment list
  val strip  : string -> string
  val render : fragment list -> string

  (* SGR builders *)
  val sgr   : int list -> string
  val fg    : color -> string
  val bg    : color -> string
  val reset : string
end
