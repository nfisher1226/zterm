id: 6z82jefdlliphjpcl5s138s5ej5tr3rs80c3d4hnzl33gfvx
name: zt
main: src/main.zig
dev_dependencies:
  - src: git https://github.com/ziglibs/known-folders commit-9db1b99219c767d5e24994b1525273fe4031e464
  - src: git https://github.com/Hejsil/zig-clap branch-master
  - src: git https://github.com/LewisGaul/zig-nestedtext.git branch-zig-master
    name: nestedtext
    main: src/nestedtext.zig
  - src: git https://codeberg.org/jeang3nie/zig-vte branch-odin
    name: vte
    main: lib.zig
