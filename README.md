# sml-ansi

[![CI](https://github.com/sjqtentacles/sml-ansi/actions/workflows/ci.yml/badge.svg)](https://github.com/sjqtentacles/sml-ansi/actions/workflows/ci.yml)

ANSI/VT escape sequence parser for Standard ML. Parses terminal output into
structured fragments — useful for log colorisation, terminal emulators, and
stripping control codes before text processing.

## Fragment types

```sml
datatype fragment
  = Text   of string            (* literal printable text *)
  | Sgr    of int list          (* SGR colour/style codes: ESC[1;31m → [1, 31] *)
  | Cursor of { row : int option, col : int option }  (* ESC[n;mH / ESC[nA-D *)
```

## API sketch

```sml
(* Parse an ANSI-coloured string into fragments *)
val frags = Ansi.parse "\027[1;31mHello\027[0m world"
(* [Sgr [1, 31], Text "Hello", Sgr [0], Text " world"] *)

(* Strip all escape sequences, leaving only text *)
val plain = Ansi.strip "\027[1;31mHello\027[0m world"
(* "Hello world" *)
```

## Handled escape sequences

| Sequence | Type | Example |
|---|---|---|
| `ESC[...m` | `Sgr` codes | `ESC[1;31m` → bold red |
| `ESC[n;mH` | `Cursor` position | `ESC[5;10H` |
| `ESC[nA`–`ESC[nD` | `Cursor` movement | up/down/forward/back |
| Everything else | `Text` | passed through verbatim |

## Known limitations

- Only **CSI** sequences (`ESC[`) are parsed; OSC (`ESC]`), DCS, SS2/SS3 and
  other escape sequences are treated as `Text`.
- `Cursor` captures position and simple movement; resize, scroll, and save/restore
  position sequences are not structured (returned as `Text`).
- The parser is linear and does not maintain terminal state; reconstructing a full
  virtual terminal screen is outside the scope of this library.

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
  ansi.sml     parse / strip implementation
  ansi.mlb
test/
  test.sml     fragment and strip tests
```

## License

MIT. See [LICENSE](LICENSE).
