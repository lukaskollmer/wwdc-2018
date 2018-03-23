# wwdc-2018

> A Visual Introduction to Regular Expressions

## Chapters (wip)
- ToC (+ meta documentation)
- Introduction (some simple examples, introduce most special characters, link to chapter)
- Capture Groups
- Character Sets
- Exercises
- Solutions


## Ideas for exercises
- Check whether a string starts with an uppercase letter
- valid swift variable declaration (var|let) followed by valid name, followed by ':' followed by valid typename
- check whether some typename follows a recommended pattern (uppercase start, doesn't start with a number)
- Match a hexadecimal number (character groups)
- Check whether an address string is in an expected format
- extract key-value pairs from a string
- validate an email address

## TODO?
- include full ToC at the top of each page?

## Integrating the visualizer into the playground?
- have unused inline nsbutton objects that can be shown by clicking the preview square icon thing and then clicking the button updates the visualizer? (update: doesn't seem to work :/)
- give each section/example a unique number, then have a text field/selection thing in the visualizer where you enter that number to load the example
- completely ditch Xcode's rendered preview, require the live view be run at full width and show our own rendering of the content. that'd also allow inline buttons that control the visualizer and we wouldn't need to reload the visualizer for every new page
- a regex match function that returns a text view w/ highlighted matches that could be shown as a inline view and update when the regex changes? - FUCK YEAH

## Technologies used in this playground
- AppKit
- AutoLayout
- NSRegularExpression (+ NSTextCheckingResult)
- NSLayoutManager
- PlaygroundSupport live view
- NSUserDefaults
- NSPopover
- NSViewController
- Swift Playgrounds Inline View previews

## License
MIT @ [Lukas Kollmer](https://lukaskollmer.me)
