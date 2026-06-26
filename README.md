# sml-ansi

[![CI](https://github.com/sjqtentacles/sml-ansi/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-ansi/actions/workflows/ci.yml)

ANSI/VT escape sequence parser for Standard ML. Parses terminal output into
structured fragments — useful for log colorisation, terminal emulators, and
stripping control codes before text processing.

## Fragment types

```sml
datatype color = Default | Idx of int | Rgb of int * int * int

datatype fragment
  = Text   of string            (* literal printable text *)
  | Sgr    of int list          (* SGR colour/style codes: ESC[1;31m → [1, 31] *)
  | Cursor of { row : int option, col : int option }  (* CUP: ESC[n;mH / ESC[H *)
  | CursorMove of { dir : char, n : int }   (* ESC[nA..nG: up/down/fwd/back/... *)
  | Erase  of { what : char, n : int }      (* ESC[nJ (screen) / ESC[nK (line) *)
  | Scroll of { up : bool, n : int }        (* ESC[nS / ESC[nT *)
  | Save | Restore                          (* ESC[s / ESC[u *)
  | Unknown of string                       (* unrecognised CSI, kept verbatim *)
```

## API sketch

```sml
(* Parse an ANSI-coloured string into fragments *)
val frags = Ansi.parse "\027[1;31mHello\027[0m world"
(* [Sgr [1, 31], Text "Hello", Sgr [0], Text " world"] *)

(* Strip all escape sequences, leaving only text *)
val plain = Ansi.strip "\027[1;31mHello\027[0m world"   (* "Hello world" *)

(* Re-serialize fragments back to escape sequences (round-trips parse) *)
val s = Ansi.render frags

(* Build SGR sequences without memorising codes *)
Ansi.reset                       (* "\027[0m" *)
Ansi.fg (Ansi.Idx 1)             (* "\027[31m"  — basic red *)
Ansi.fg (Ansi.Idx 200)           (* "\027[38;5;200m" — 256-colour *)
Ansi.fg (Ansi.Rgb (255,0,0))     (* "\027[38;2;255;0;0m" — truecolor *)
Ansi.bg (Ansi.Rgb (0,128,255))   (* "\027[48;2;0;128;255m" *)
Ansi.sgr [1,4]                   (* "\027[1;4m" — bold + underline *)
```

## Handled escape sequences

| Sequence | Type | Example |
|---|---|---|
| `ESC[...m` | `Sgr` codes | `ESC[1;31m` → bold red |
| `ESC[n;mH` / `ESC[n;mf` | `Cursor` position | `ESC[5;10H` |
| `ESC[nA`–`ESC[nG` | `CursorMove` | up/down/forward/back/next/prev/column |
| `ESC[nJ` / `ESC[nK` | `Erase` | erase screen / erase line |
| `ESC[nS` / `ESC[nT` | `Scroll` | scroll up / down |
| `ESC[s` / `ESC[u` | `Save` / `Restore` | cursor position |
| Other `ESC[...X` | `Unknown` | preserved verbatim (round-trips) |
| Everything else | `Text` | passed through verbatim |

## Scope and limitations

- Only **CSI** sequences (`ESC[`) are parsed; OSC (`ESC]`), DCS, SS2/SS3 and
  other escape sequences are treated as `Text`.
- `render` re-emits movement/erase/scroll counts explicitly (e.g. `ESC[A`
  round-trips as `ESC[1A`); `Unknown` fragments round-trip byte-for-byte.
- The parser is linear and does not maintain terminal state; reconstructing a
  full virtual terminal screen is the job of a consumer (see `sml-vt`).

## Installing with smlpkg

```sh
smlpkg add github.com/sjqtentacles/sml-ansi
smlpkg sync
```

Reference from your `.mlb`:

```
lib/github.com/sjqtentacles/sml-ansi/ansi.mlb
```

## Building and testing

```sh
make test        # MLton
make test-poly   # Poly/ML
make all-tests   # both
make clean
```

## Project layout

```
sml.pkg
Makefile
lib/github.com/sjqtentacles/sml-ansi/
  ansi.sig     ANSI signature
  ansi.sml     parse / strip / render / SGR builders
  ansi.mlb
test/
  test.sml     fragment and strip tests
```

## License

MIT. See [LICENSE](LICENSE).
