## Translation
Native language translation is using the Gettext framework. If you wish to help
with translating Zterm into your native language, there is a translation `.pot`
template in the `po` subdirectory. It is suggested that you use the excellent
[Poedit](https://poedit.net/) program to turn this template into a `.po` file
ready to be compiled along with the program. Save this `.po` file into the same
directory. Extra credit: add your language to the list of locales on line 5 of
`build.zig`.
