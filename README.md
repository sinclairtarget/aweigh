# Aweigh
Aweigh is a little CLI program that demonstrates how to use [libatrus][] from
Zig.

Aweigh prints out all the links used in a MyST Markdown file.

Given this file:
```
$ cat post.md
# Tomatoes Get Political
:::{warning}
According to [this Atlantic article][atlantic article], bad tomatoes from
France [can't be used](https://johndoe.com/blog/foo-bar) to feed Italians.
:::

Tomatoes are having a moment. Trump inveighed against them at his recent rally
in Columbia, MO.

[atlantic article]: https://theatlantic.com/politics/exit-stage-right/
```

Aweigh will output the following:
```
$ cat post.md | aweigh
{
    "type": "link",
    "url": "https://theatlantic.com/politics/exit-state-right/",
    "children": [
        {
            "type": "text",
            "value": "this Atlantic article"
        }
    ]
}
{
    "type": "link",
    "url": "https://johndoe.com/blog/foo-bar",
    "children": [
        {
            "type": "text",
            "value": "can't be used"
        }
    ]
}
```

To get just the URLs, you could always pipe the output to [jq][]:
```
$ cat post.md | aweigh | jq -r .url
https://theatlantic.com/politics/exit-stage-right/
https://johndoe.com/blog/foo-bar
```

[libatrus]: https://github.com/sinclairtarget/libatrus
[jq]: https://jqlang.org/
