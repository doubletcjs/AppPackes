## 1.4.1

Highlight words without highlighting subwords.
Thanks to [Enloc](https://github.com/enloc-port)

## 1.4.0

`style` and `onTap` for `HighlightedWord` and `TextHighlight` are now optional.
Improved `matchCase`, now a substring can be highlighted.
Fixed RangeError when there is a number at the end of `text` and the word before is highlighted.

## 1.3.0

Added `binding` parameter to `TextHighlight`, now you can define what occurrence you want to highlight with `HighlightBinding` enum.

## 1.2.1

`matchCase` fixed

## 1.2.0

Fixed first word not matching
Renamed `enabledCaseSensitive` to `matchCase` to be clearer about what it does
`matchCase: false` will keep the original word

## 1.1.0

Fixed error when you add a word in the dictionary that is not in the sentence.
Added `BoxDecoration` (called `decoration`) and `EdgeInsetsGeometry` (called `padding`) to `HighlightedWord` object, now you can customize your words better.

## 1.0.0

Package reworked
Added null safety support
RangeError for a `HighlightedWord` ending with a blank space fixed
Working with numbers
`HighlightedWord` working with more than one word

## 0.7.2

Health suggestions.

## 0.7.1

Some corrections in the example.

## 0.7.0

Now you can choose to differentiate words with upper and lower case.

## 0.6.0

Fixed the problem of the last word is not always highlighted.

## 0.5.0

RangeError Solved.
Thanks to [Artem](https://github.com/ashkryab)

## 0.4.0

If the highlighted word has special characters then it is only highlighted if it has only one character.

## 0.3.0

Now the highlights work in words followed by special characters, numbers or complementary words.

## 0.2.0

The meaning attribute was removed from the HighlightedWord class; the onTap is working normally.

## 0.0.1+2

Minor maintenance fixes

## 0.0.1+1

Example correction

## 0.0.1

With this package you can highlight words and create specific actions for each highlighted word, you can customize the style of each word separately or create a unique style for all of them, you can also customize the style of the rest of the text.
