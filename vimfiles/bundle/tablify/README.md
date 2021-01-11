# Tablify

Tablify is a VIM plugin that turns simple structured data into nice-looking tables.

## Installation
Put `tablify.vim` in your vim's plugin directory and you're ready to go.
For [pathogen](https://github.com/tpope/vim-pathogen) users, just:

    cd ~/.vim/bundle
    git clone git://github.com/Stormherz/tablify.git

And you're ready to go.


## Usage
There is a small list of commands you need to know before starting making tables out of your text. Assuming your `<Leader>` is `\`:
`\tl` or `\tt` - turns selected lines into table (left-aligned text)
`\tc` - turns selected lines into table (centered text)
`\tr` - turns selected lines into table (right-aligned text)
`\tu` - convert selected table back into raw text format in case you want to add some changes in it

`\ta` - select formed table with cursor anywhere inside of it (also selects structured text for future tables)

Operations with formed and selected table:
`\tS` - sort table (column number will be prompted), supports text and numeric sorting
`\tRL` - realign table column to be left-aligned
`\tRR` - realign table column to be right-aligned
`\tRC` - realign table column to be centered

Operations with cursor inside the table:
`\tK` - move current row (where the cursor is) up
`\tJ` - move current row down
`\tL` - move current column (where the cursor is) right
`\tH` - move current column left

Every line of your future table is a text line with cells, separated by `|` symbol (or any other symbol you choose for `b:tablify_raw_delimiter` variable in your `.vimrc` file).

Let's assume we have a few lines of text we would like to see as table:

    Artist | Song | Album | Year
    Tool | Useful idiot | Ænima | 1996
    Pantera | Cemetery Gates | Cowboys from Hell | 1990
    Ozzy Osbourne | Let Me Hear You Scream | Scream | 2010

Now select these lines and press `\tt` to make a table:

    +---------------+------------------------+-------------------+------+
    | Artist        | Song                   | Album             | Year |
    +---------------+------------------------+-------------------+------+
    | Tool          | Useful idiot           | Ænima             | 1996 |
    +---------------+------------------------+-------------------+------+
    | Pantera       | Cemetery Gates         | Cowboys from Hell | 1990 |
    +---------------+------------------------+-------------------+------+
    | Ozzy Osbourne | Let Me Hear You Scream | Scream            | 2010 |
    +---------------+------------------------+-------------------+------+

I bet it was pretty simple. Now you can press `u` to undo making of table or select table and press `\tu` to return to the text you're started from. After that you can try `\tc` and `\tr` to see what it looks like to have aligned text in table.

It is obvious that our table here have some kind of header and it will be great to visually distinguish it from table data. To do so, just separate the header cells with `#` symbol (or any other symbol you choose for `b:tablify_header_delimiter` variable in your `.vimrc` file):

    Artist # Song # Album # Year
    Tool | Useful idiot | Ænima | 1996
    Pantera | Cemetery Gates | Cowboys from Hell | 1990
    Ozzy Osbourne | Let Me Hear You Scream | Scream | 2010


And that's what we get after tablification:

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    | Artist        | Song                   | Album             | Year |
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    | Tool          | Useful idiot           | Ænima             | 1996 |
    +---------------+------------------------+-------------------+------+
    | Pantera       | Cemetery Gates         | Cowboys from Hell | 1990 |
    +---------------+------------------------+-------------------+------+
    | Ozzy Osbourne | Let Me Hear You Scream | Scream            | 2010 |
    +---------------+------------------------+-------------------+------+

There is no problem of making tables out of commonly prefixed text lines, like:

    /**
     * Artist#Song#Album#Year
     * Tool|Useful idiot|Ænima|1996
     * Pantera|Cemetery Gates|Cowboys from Hell|1990
     * Ozzy Osbourne|Let Me Hear You Scream|Scream|2010
     *
     */

Multiline cell content is also supported, just place `\n` where line break should occur, and tablify will do the rest:

    Artist # Song # Album # Year
    Pantera | Cemetery Gates | Cowboys from Hell | 1990
    Tool \n (great perfomance)| Useful idiot | Ænima | 1996
    Ozzy Osbourne | Let Me Hear You \n Scream | Scream | 2010

The sample above transforms to table:

    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    | Artist             | Song            | Album             | Year |
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    | Pantera            | Cemetery Gates  | Cowboys from Hell | 1990 |
    +--------------------+-----------------+-------------------+------+
    | Tool               | Useful idiot    | Ænima             | 1996 |
    | (great perfomance) |                 |                   |      |
    +--------------------+-----------------+-------------------+------+
    | Ozzy Osbourne      | Let Me Hear You | Scream            | 2010 |
    |                    | Scream          |                   |      |
    +--------------------+-----------------+-------------------+------+


## Configuration
Tablify behaviour can be configured on per-buffer basis with the folowing variables:
`g:loaded_tablify` - set to `1` to disable loading of the plugin
`b:tablify_headerDelimiter` - default value is `#`, symbol that separates header cells in text
`b:tablify_delimiter` - default value is `|`, symbol that separated value cells in text

`b:tablify_vertDelimiter` - default value is `|`, vertical delimiter symbol for filling up table rows
`b:tablify_horDelimiter` - default value is `-`, horizontal delimiter symbol for filling up table rows
`b:tablify_horHeaderDelimiter` - default value is `~`, horizontal delimiter symbol for filling up tabls header rows
`b:tablify_divideDelimiter` - default value is `+`, symbol at the row/column intersection

`b:tablify_cellLeftPadding` - default value is `1`, number of spaces used for left cell padding
`b:tablify_cellRightPadding` - default value is `1`, number of spaces used for right cell padding

`b:tablify_restructuredtext` - default value is `0`, but automatically enables in `*.rst` buffers (or you can set it manually). Controls some of the symbols to support reStructuredText table format

## Changelog
* **0.5.1** reStructuredText table format support
* **0.5** Row/column movement
* **0.4.1** Separate column alignments
* **0.4** Multiline cell content
* **0.3** Core functionality refactoring, added table selection and sorting
* **0.2.2** Per-buffer configuration
* **0.2.1** Tablification with common prefix
* **0.2** Bug fixes, additional <Leader>tl mapping
* **0.1** Initial upload
