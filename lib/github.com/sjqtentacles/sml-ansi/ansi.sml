(* ansi.sml — ANSI/VT escape sequence parser, renderer, and SGR builders. *)

structure Ansi :> ANSI =
struct
  datatype color = Default | Idx of int | Rgb of int * int * int

  datatype fragment =
      Text of string
    | Sgr of int list
    | Cursor of { row : int option, col : int option }
    | CursorMove of { dir : char, n : int }
    | Erase of { what : char, n : int }
    | Scroll of { up : bool, n : int }
    | Save | Restore
    | Unknown of string

  (* parse a ';'-separated numeric parameter list; missing/garbage -> ignored *)
  fun parseNums s =
    if s = "" then []
    else List.mapPartial Int.fromString (String.fields (fn c => c = #";") s)

  fun parse s =
    let
      val n = String.size s
      fun loop (i, textAcc, acc) =
        if i >= n then (case textAcc of "" => rev acc | t => rev (Text t :: acc))
        else if String.sub (s, i) = #"\027" andalso i + 1 < n andalso String.sub (s, i + 1) = #"[" then
          let
            fun scan j =
              if j >= n then (j, "")
              else
                let val c = String.sub (s, j)
                in if Char.isAlpha c then (j, String.substring (s, i + 2, j - i - 2)) else scan (j + 1) end
            val (j, body) = scan (i + 2)
            val cmd = if j < n then String.sub (s, j) else #"m"
            val nums = parseNums body
            val firstOr1 = case nums of (k :: _) => k | [] => 1
            val firstOr0 = case nums of (k :: _) => k | [] => 0
            val raw = String.substring (s, i, Int.min (j + 1, n) - i)
            val fr =
              case cmd of
                  #"m" => Sgr nums
                | #"H" => (case nums of
                              []          => Cursor { row = NONE,   col = NONE }
                            | [r]         => Cursor { row = SOME r, col = NONE }
                            | r :: c :: _ => Cursor { row = SOME r, col = SOME c })
                | #"f" => (case nums of
                              []          => Cursor { row = NONE,   col = NONE }
                            | [r]         => Cursor { row = SOME r, col = NONE }
                            | r :: c :: _ => Cursor { row = SOME r, col = SOME c })
                | #"A" => CursorMove { dir = #"A", n = firstOr1 }
                | #"B" => CursorMove { dir = #"B", n = firstOr1 }
                | #"C" => CursorMove { dir = #"C", n = firstOr1 }
                | #"D" => CursorMove { dir = #"D", n = firstOr1 }
                | #"E" => CursorMove { dir = #"E", n = firstOr1 }
                | #"F" => CursorMove { dir = #"F", n = firstOr1 }
                | #"G" => CursorMove { dir = #"G", n = firstOr1 }
                | #"J" => Erase { what = #"J", n = firstOr0 }
                | #"K" => Erase { what = #"K", n = firstOr0 }
                | #"S" => Scroll { up = true,  n = firstOr1 }
                | #"T" => Scroll { up = false, n = firstOr1 }
                | #"s" => Save
                | #"u" => Restore
                | _ => Unknown raw
            val textFrag = case textAcc of "" => [] | t => [Text t]
          in loop (j + 1, "", fr :: textFrag @ acc) end
        else loop (i + 1, textAcc ^ str (String.sub (s, i)), acc)
    in loop (0, "", []) end

  fun strip s =
    let fun onlyText (Text t, acc) = t ^ acc | onlyText (_, acc) = acc
    in List.foldr onlyText "" (parse s) end

  val esc = "\027["

  fun renderFragment fr =
    case fr of
        Text t => t
      | Sgr nums => esc ^ String.concatWith ";" (List.map Int.toString nums) ^ "m"
      | Cursor { row = NONE, col = NONE } => esc ^ "H"
      | Cursor { row = SOME r, col = NONE } => esc ^ Int.toString r ^ "H"
      | Cursor { row = NONE, col = SOME c } => esc ^ ";" ^ Int.toString c ^ "H"
      | Cursor { row = SOME r, col = SOME c } => esc ^ Int.toString r ^ ";" ^ Int.toString c ^ "H"
      | CursorMove { dir, n } => esc ^ Int.toString n ^ String.str dir
      | Erase { what, n } => esc ^ Int.toString n ^ String.str what
      | Scroll { up, n } => esc ^ Int.toString n ^ (if up then "S" else "T")
      | Save => esc ^ "s"
      | Restore => esc ^ "u"
      | Unknown raw => raw

  fun render frags = String.concat (List.map renderFragment frags)

  (* ---- SGR builders ---- *)
  fun sgr nums = esc ^ String.concatWith ";" (List.map Int.toString nums) ^ "m"

  (* base = 30 (fg) or 40 (bg); colorParams maps a color to its SGR params *)
  fun colorParams (base, color) =
    case color of
        Default => [base + 9]                                  (* 39 / 49 *)
      | Idx k =>
          if k >= 0 andalso k <= 7 then [base + k]             (* standard 30-37 / 40-47 *)
          else if k >= 8 andalso k <= 15 then [base + 60 + (k - 8)] (* bright 90-97 / 100-107 *)
          else [base + 8, 5, k]                                (* 256-color: 38;5;n / 48;5;n *)
      | Rgb (r, g, b) => [base + 8, 2, r, g, b]

  fun fg color = sgr (colorParams (30, color))
  fun bg color = sgr (colorParams (40, color))

  val reset = sgr [0]
end
