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
  in Harness.run () end
end
