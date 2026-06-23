(* ansi.sig — ANSI/VT escape sequence parser. *)

signature ANSI =
sig
  datatype fragment = Text of string | Sgr of int list | Cursor of { row : int option, col : int option }

  val parse : string -> fragment list
  val strip : string -> string
end
