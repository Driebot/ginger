{% with m.rsc[id] as r %}
{% with m.rsc[id].is_editable as is_editable %}

<fieldset class="form-horizontal">
    <div class="form-group row">
        <label class="control-label col-md-3" for="{{ #title }}{{ lang_code_for_id }}">{_ Title _} {{ lang_code_with_brackets }}</label>
        <div class="col-md-9">
            <input type="text" id="{{ #title }}{{ lang_code_for_id }}" name="title{{ lang_code_with_dollar }}"
                   value="{{ is_i18n|if : r.translation[lang_code].title : r.title }}"
                   {% if not is_editable %}disabled="disabled"{% endif %}
                    {% include "_language_attrs.tpl" language=lang_code class="do_autofocus field-title form-control" %}
            />
        </div>
    </div>
</fieldset>

{% endwith %}
{% endwith %}
