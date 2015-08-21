{% with
    items,
    cols,
    extraClasses,
    list_id
as
    items,
    cols,
    extraClasses,
    list_id
%}

    <ul id="{{ list_id }}" class="list {{ extraClasses }}">

        {% for item in items %}
            {% catinclude "list/list-item.tpl" item cols=cols %}
        {% endfor %}

    </ul>

{% endwith %}