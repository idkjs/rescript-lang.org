// This file was automatically converted to ReScript from 'AnsiPre.re'
// Check the output and make sure to delete the original file
open Ansi

type colorTarget =
  | Fg
  | Bg

let mapColor = (~target: colorTarget, c: Color.t): string =>
  switch (target, c) {
  | (Fg, Black) => "text-gray-100"
  | (Fg, Red) => "text-fire-70"
  | (Fg, Green) => "text-turtle-dark"
  | (Fg, Yellow) => "text-orange-dark"
  | (Fg, Blue) => "text-water-dark"
  | (Fg, Magenta) => "text-berry"
  | (Fg, Cyan) => "text-water-dark"
  | (Fg, White) => "text-gray-10"
  | (Bg, Black) => "bg-gray-100"
  | (Bg, Red) => "bg-fire"
  | (Bg, Green) => "bg-turtle-dark"
  | (Bg, Yellow) => "bg-orange-dark"
  | (Bg, Blue) => "bg-water-dark"
  | (Bg, Magenta) => "bg-berry"
  | (Bg, Cyan) => "bg-water-dark"
  | (Bg, White) => "bg-gray-10"
  }

let renderSgrString = (~key: string, sgrStr: SgrString.t): React.element => {
  let {SgrString.content: content, params} = sgrStr

  let className = Belt.Array.reduce(params, "", (acc, p) =>
    switch p {
    | Sgr.Bold => acc ++ " bold"
    | Fg(c) => acc ++ (" " ++ mapColor(~target=Fg, c))
    | Bg(c) => acc ++ (" " ++ mapColor(~target=Bg, c))
    | _ => acc
    }
  )

  <span key className> {React.string(content)} </span>
}

@react.component
let make = (~className=?, ~children: string) => {
  let spans =
    Ansi.parse(children)
    ->SgrString.fromTokens
    ->Belt.Array.mapWithIndex((i, str) => {
      let key = Belt.Int.toString(i)
      renderSgrString(~key, str)
    })

  // Note: pre is essential here, otherwise whitespace and newlines are not respected
  <pre ?className> {React.array(spans)} </pre>
}
