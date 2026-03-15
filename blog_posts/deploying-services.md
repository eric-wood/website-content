---
title: How I deploy my services
published_at: 3/15/26 8:37
tags: linux, web
---

```js
polkit.addRule(function(action, subject) {
        if (action.id == "org.freedesktop.systemd1.manage-units" &&
                action.lookup("unit") == "website.service" &&
                subject.user == "eric") {
                return polkit.Result.YES;
        }
});
```
