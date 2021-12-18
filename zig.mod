id: 6z82jefdlliphjpcl5s138s5ej5tr3rs80c3d4hnzl33gfvx
name: zterm
main: src/main.zig
dev_dependencies:
  - src: git https://github.com/ziglibs/known-folders
  - src: git https://github.com/Hejsil/zig-clap branch-zig-master
  - src: git https://github.com/LewisGaul/zig-nestedtext.git branch-zig-master
    name: nestedtext
    main: src/nestedtext.zig
  - src: git https://codeberg.org/jeang3nie/zig-vte branch-loki
    name: vte
    main: lib.zig
