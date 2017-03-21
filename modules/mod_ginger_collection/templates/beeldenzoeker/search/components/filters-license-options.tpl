{% with
    q.buckets,
    q.values
as
    buckets,
    values
%}
    {% for bucket in buckets %}
        {% with
            forloop.counter,
            m.creative_commons[bucket.key].label
        as
            i,
            label
        %}
            <li>
                <input name="filter_license" id="{{ #filter_license_value.i }}" type="checkbox" value="{{ bucket.key}}"{% if values|index_of:(bucket.key) > 0 %} checked="checked"{% endif %}>
                <label for="{{ #filter_license_value.i }}">
                    <i class="icon-cc icon--cc-{{ label|lower }}"></i>
                </label>
            </li>
        {% endwith %}
    {% endfor %}
{% endwith %}
