mod_ginger_spa
==============

Default template and dispatch rules for a single page app.

_Only routes for which a Ginger resource with the same path exists will be served by the `page.tpl` template.
Other routes should be manually added to the sites dispatch rules._


Template rendering
------------------

The `controller_ginger_spa_template` renders templates and returns the result as plain text.

Pass the template name in the path, example:

    https://example.com/render-template/public/test.tpl

This renders the template `"public/test.tpl"`.

Pass arguments via the query string:

    https://example.com/render-template/public/test.tpl?id=1

Or in a POST body as `application/x-www-form-urlencoded` or `multipart/form-data`.

Use the argument `catinclude=1` to render the template using a *catinclude*.
Any `id` argument is always added as `id` to the template arguments (after mapping using `m_rsc:rid/2`), in
this way the `id` is always available and usable for the optional catinclude.

Security
........

As in Zotonic 0.x template models are not access checked there is a security using the name of the template.

Templates starting with `public/...` can be rendered by anonymous users.

Templates starting with `member/...` can be rendered by authenticated users.

Administrators are allowed to render all templates.


