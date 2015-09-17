
<figure>

    <a href="/image/{{ id.medium.filename }}" class="media--image lightbox {{ extraClasses }}" rel="fancybox-group"
    {% if id.title %}
        title="{{ id.title }}"
    {% elif id.summary %}
        title = "{{ id.summary }}"
    {% endif %}
    >

        {% if id.medium.width > 750 %}
            {% image id.id mediaclass="article-depiction-width" class="img-responsive" alt="" crop=id.crop_center %}
        {% elif id.medium.height > 750 %}
             {% image id.id mediaclass="article-depiction-height" class="img-responsive" alt="" crop=id.crop_center %}
        {% else %}
            {% image id.id mediaclass="default" class="img-auto" alt="" crop=id.id.crop_center %}
        {% endif %}

    </a>

    {% if m.rsc[id].title %}
            <figcaption>{{ m.rsc[id].title }}{% if m.rsc[id].o.author %} {_ Door: _} <a href="{{ m.rsc[m.rsc[id].o.author[1]].page_url }}">{{ m.rsc[m.rsc[id].o.author[1]].title }}</a>{% endif %}</figcaption>
    {% elif m.rsc[id].summary %}
            <figcaption>{{ m.rsc[id].summary }}</figcaption>
    {% endif %}

</figure>
