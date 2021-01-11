This is a mirror of http://www.vim.org/scripts/script.php?script_id=1879

Repository:
  https://bitbucket.org/ns9tks/vim-autocomplpop/

Issues:
  http://bitbucket.org/ns9tks/vim-autocomplpop/issues/

Download latest(development) version
  https://bitbucket.org/ns9tks/vim-autocomplpop/get/tip.zip

==============================================================================
INTRODUCTION                                                *acp-introduction*

With this plugin, your vim comes to automatically opens popup menu for
completions when you enter characters or move the cursor in Insert mode. It
won't prevent you continuing entering characters.


==============================================================================
INSTALLATION                                                *acp-installation*

Put all files into your runtime directory. If you have the zip file, extract
it to your runtime directory.

You should place the files as follows:
>
        <your runtime directory>/plugin/acp.vim
        <your runtime directory>/doc/acp.txt
        ...
<
If you disgust to jumble up this plugin and other plugins in your runtime
directory, put the files into new directory and just add the directory path to
'runtimepath'. It's easy to uninstall the plugin.

And then update your help tags files to enable fuzzyfinder help. See
|add-local-help| for details.


==============================================================================
USAGE                                                              *acp-usage*

Once this plugin is installed, auto-popup is enabled at startup by default.

Which completion method is used depends on the text before the cursor. The
default behavior is as follows:

        kind      filetype    text before the cursor ~
        Keyword   *           two keyword characters
        Filename  *           a filename character + a path separator 
                              + 0 or more filename character
        Omni      ruby        ".", "::" or non-word character + ":"
                              (|+ruby| required.)
        Omni      python      "." (|+python| required.)
        Omni      xml         "<", "</" or ("<" + non-">" characters + " ")
        Omni      html/xhtml  "<", "</" or ("<" + non-">" characters + " ")
        Omni      css         (":", ";", "{", "^", "@", or "!")
                              + 0 or 1 space

Also, you can make user-defined completion and snipMate's trigger completion
(|acp-snipMate|) auto-popup if the options are set.

These behavior are customizable.

                                                                *acp-snipMate*
snipMate's Trigger Completion ~

snipMate's trigger completion enables you to complete a snippet trigger
provided by snipMate plugin
(http://www.vim.org/scripts/script.php?script_id=2540) and expand it.


To enable auto-popup for this completion, add following function to
plugin/snipMate.vim:
>
  fun! GetSnipsInCurrentScope()
    let snips = {}
    for scope in [bufnr('%')] + split(&ft, '\.') + ['_']
      call extend(snips, get(s:snippets, scope, {}), 'keep')
      call extend(snips, get(s:multi_snips, scope, {}), 'keep')
    endfor
    return snips
  endf
<
And set |g:acp_behaviorSnipmateLength| option to 1.

There is the restriction on this auto-popup, that the word before cursor must
consist only of uppercase characters.

                                                               *acp-perl-omni*
Perl Omni-Completion ~

AutoComplPop supports perl-completion.vim
(http://www.vim.org/scripts/script.php?script_id=2852).

To enable auto-popup for this completion, set |g:acp_behaviorPerlOmniLength|
option to 0 or more.


==============================================================================

