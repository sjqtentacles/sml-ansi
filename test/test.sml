structure Tests =
struct
  open Harness
  structure A = Ansi
  val colored = "\027[1;32mok\027[0m> "
  fun run () =
  let
    val () = section "parse colored prompt"
    val frags = A.parse colored
    val () = check "has text" (List.exists (fn A.Text t => t = "ok" | _ => false) frags)
    val () = check "has green sgr" (List.exists (fn A.Sgr [1,32] => true | _ => false) frags)
    val () = checkString "strip escapes" ("ok> ", A.strip colored)

    val () = section "cursor positioning (CUP)"
    val cf = A.parse "\027[3;14HX"
    val () = check "emits Cursor {3,14}"
                 (List.exists (fn A.Cursor {row=SOME 3, col=SOME 14} => true | _ => false) cf)
    val () = check "text after cursor"
                 (List.exists (fn A.Text "X" => true | _ => false) cf)
    val () = check "ESC[H is home (no row/col)"
                 (List.exists (fn A.Cursor {row=NONE, col=NONE} => true | _ => false)
                              (A.parse "\027[H"))
    val () = checkString "strip drops cursor seq too" ("X", A.strip "\027[3;14HX")

    val () = section "cursor movement / erase / scroll / save / restore"
    val () = check "ESC[2A -> CursorMove A 2"
                 (List.exists (fn A.CursorMove {dir=(#"A"), n=2} => true | _ => false)
                              (A.parse "\027[2A"))
    val () = check "ESC[C default n=1"
                 (List.exists (fn A.CursorMove {dir=(#"C"), n=1} => true | _ => false)
                              (A.parse "\027[C"))
    val () = check "ESC[2J -> Erase J 2"
                 (List.exists (fn A.Erase {what=(#"J"), n=2} => true | _ => false)
                              (A.parse "\027[2J"))
    val () = check "ESC[K -> Erase K 0"
                 (List.exists (fn A.Erase {what=(#"K"), n=0} => true | _ => false)
                              (A.parse "\027[K"))
    val () = check "ESC[3S -> Scroll up 3"
                 (List.exists (fn A.Scroll {up=true, n=3} => true | _ => false)
                              (A.parse "\027[3S"))
    val () = check "ESC[s -> Save"
                 (List.exists (fn A.Save => true | _ => false) (A.parse "\027[s"))
    val () = check "ESC[u -> Restore"
                 (List.exists (fn A.Restore => true | _ => false) (A.parse "\027[u"))
    val () = check "unknown verb -> Unknown"
                 (List.exists (fn A.Unknown _ => true | _ => false) (A.parse "\027[5Z"))

    val () = section "round-trip render (parse s) = s"
    val () = checkString "sgr round-trip" ("\027[1;32mok\027[0mx", A.render (A.parse "\027[1;32mok\027[0mx"))
    val () = checkString "cursor round-trip" ("\027[3;14HX", A.render (A.parse "\027[3;14HX"))
    val () = checkString "move round-trip" ("\027[2A", A.render (A.parse "\027[2A"))
    val () = checkString "erase round-trip" ("\027[2J", A.render (A.parse "\027[2J"))

    val () = section "SGR builders"
    val () = checkString "reset" ("\027[0m", A.reset)
    val () = checkString "fg basic red" ("\027[31m", A.fg (A.Idx 1))
    val () = checkString "fg bright" ("\027[91m", A.fg (A.Idx 9))
    val () = checkString "fg 256" ("\027[38;5;200m", A.fg (A.Idx 200))
    val () = checkString "fg rgb" ("\027[38;2;255;0;0m", A.fg (A.Rgb (255,0,0)))
    val () = checkString "bg rgb" ("\027[48;2;0;128;255m", A.bg (A.Rgb (0,128,255)))
    val () = checkString "fg default" ("\027[39m", A.fg A.Default)
    val () = checkString "sgr list" ("\027[1;4m", A.sgr [1,4])
  in Harness.run () end
end
