# Aweigh
Aweigh is a little CLI program that demonstrates how to use [libatrus][] from
Zig.

Aweigh prints out all the links used in a MyST Markdown file.

```
$ cat post.md | aweigh
"this Atlantic article"    -> https://theatlantic.com/politics/exit-stage-right
"can't be used"            -> https://johndoe.com/blog/foo-bar
```

[libatrus]: https://github.com/sinclairtarget/libatrus
