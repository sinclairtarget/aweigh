# Aweigh
Aweigh is a little CLI program that demonstrates how to use [libatrus][] from
Zig.

Aweigh parses an input MyST file, adds the anchor emoji (⚓) to the beginning
of the link text for all link nodes found in the AST, then renders the AST to
stdout as HTML.

Check out [main.zig](./src/main.zig) for comments explaining all the relevant
pieces.

## Usage
Given this file, named `post.md`:
```md post.md
# Tomatoes Get Political
:::{warning}
According to [this Atlantic article](https://theatlantic.com/foo), bad tomatoes
from France can't be used to feed Italians.
:::

Tomatoes are having [a moment](https://johndoe.com/blog/bar). Trump inveighed
against them at his recent rally in Columbia, MO.
```

You can run Aweigh like this: 

```sh
cat post.md | zig build run 
```

And see the following output:
```html
<h1>Tomatoes Get Political</h1>
<aside class="admonition warning">
  <p class="admonition-title">Warning</p>
  <p>According to <a href="https://theatlantic.com/foo">⚓ this Atlantic article</a>, bad tomatoes
from France can't be used to feed Italians.</p>
</aside>
<p>Tomatoes are having <a href="https://johndoe.com/blog/bar">⚓ a moment</a>. Trump inveighed
against them at his recent rally in Columbia, MO.</p>
```

[libatrus]: https://github.com/sinclairtarget/libatrus
