<div class="modal-body">
    <div class="form-group">
        <label for="adlib_url" class="control-label">{_ Adlib API URL _}</label>
        <input type="text" id="adlib_url" name="adlib_url" value="{{ m.config.mod_ginger_adlib.url.value|escape }}" class="form-control do_autofocus" />
        {% wire id="adlib_url" type="change" action={config_toggle module="mod_ginger_adlib" key="url" on="keyup"} action={update target="adlib_databases" template="admin/adlib_databases.tpl"} %}
    </div>

    <div class="form-group" id="adlib_databases">
        {% include "admin/adlib_databases.tpl" %}
    </div>

    <div class="control-group">
        <label class="control-label" for="poll_frequency">{_ Adlib polling frequency _}</label>
        <div class="controls">
            {% with m.config.mod_ginger_adlib.poll_frequency.value|if_undefined:"86400" as value %}
                 <select class="form-control input-sm" id="poll_frequency" name="delete_interval">
                     <option value="60"{% if value == "60" %} selected{% endif %}>{_ Every minute _}</option>
                     <option value="3600"{% if value == "3600" %} selected{% endif %}>{_ Every hour _}</option>
                     <option value="86400"{% if value == "86400" %} selected{% endif %}>{_ Every day _}</option>
                 </select>
            {% endwith %}

            {% wire id="poll_frequency" type="blur" action={config_toggle module="mod_ginger_adlib" key="poll_frequency" on="keyup"} %}
        </div>
    </div>
</div>

<div class="modal-footer">
    {% button class="btn btn-default" text=_"Close" action={dialog_close} tag="a" %}
</div>
