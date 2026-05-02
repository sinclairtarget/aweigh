# Aweigh
Aweigh is a little CLI program that shows how to use [libatrus][] from
Zig.

Aweigh parses an input MyST file, adds the anchor emoji (⚓) to the beginning
of the link text for any link node found in the AST, then renders the AST to
stdout as JSON.

This demonstrates how to parse, transform, and render a MyST document with
libatrus.

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
cat post.md | aweigh
```

And see the following output:
```json
{
  "type": "root",
  "children": [
    {
      "type": "block",
      "children": [
        {
          "type": "heading",
          "depth": 1,
          "children": [
            {
              "type": "text",
              "value": "Notes on Michel"
            }
          ]
        },
        {
          "type": "paragraph",
          "children": [
            {
              "type": "text",
              "value": "On "
            },
            {
              "type": "link",
              "url": "https://sinclairtarget.com",
              "children": [
                {
                  "type": "text",
                  "value": "⚓ "
                },
                {
                  "type": "text",
                  "value": "my personal website"
                }
              ]
            },
            {
              "type": "text",
              "value": ", you can find more\ninformation about Michel."
            }
          ]
        },
        {
          "type": "paragraph",
          "children": [
            {
              "type": "text",
              "value": "You should also check out the "
            },
            {
              "type": "link",
              "url": "https://github.com/sinclairtarget/libatrus",
              "children": [
                {
                  "type": "text",
                  "value": "⚓ "
                },
                {
                  "type": "text",
                  "value": "libatrus"
                }
              ]
            },
            {
              "type": "text",
              "value": " repository."
            }
          ]
        }
      ]
    }
  ]
}
```

[libatrus]: https://github.com/sinclairtarget/libatrus
