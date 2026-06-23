structure Ansi :> ANSI =
struct
  datatype fragment = Text of string | Sgr of int list | Cursor of { row : int option, col : int option }

  fun parseNums s =
    if s = "" then []
    else List.map (fn p => valOf (Int.fromString p)) (String.fields (fn c => c = #";") s)

  fun parse s =
    let
      val n = String.size s
      fun loop (i, textAcc, acc) =
        if i >= n then (case textAcc of "" => rev acc | t => rev (Text t :: acc))
        else if String.sub (s, i) = #"\027" andalso i + 1 < n andalso String.sub (s, i + 1) = #"[" then
          let
            fun scan j = if j >= n then (j, "") else
              let val c = String.sub (s, j) in if Char.isAlpha c then (j, String.substring (s, i + 2, j - i - 2)) else scan (j + 1) end
            val (j, body) = scan (i + 2)
            val cmd = if j < n then String.sub (s, j) else #"m"
            val fr = case cmd of
                       #"m" => Sgr (parseNums body)
                       (* CUP: ESC[row;colH (1-based); ESC[H is home *)
                     | #"H" => (case parseNums body of
                                    []        => Cursor { row = NONE,   col = NONE }
                                  | [r]       => Cursor { row = SOME r, col = NONE }
                                  | r :: c :: _ => Cursor { row = SOME r, col = SOME c })
                     | _ => Text (String.substring (s, i, j - i + 1))
            val textFrag = case textAcc of "" => [] | t => [Text t]
          in loop (j + 1, "", fr :: textFrag @ acc) end
        else loop (i + 1, textAcc ^ str (String.sub (s, i)), acc)
    in loop (0, "", []) end

  fun strip s =
    let fun onlyText (Text t, acc) = t ^ acc | onlyText (_, acc) = acc
    in List.foldr onlyText "" (parse s) end
end
