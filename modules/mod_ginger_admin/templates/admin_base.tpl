{% overrules %}

{% block head_extra %}
    {% lib "css/mod_ginger_admin/screen.css" %}
{% endblock %}

{% block bodyclass %}
    {% if("dev"|environment) %}
        development-environment
    {% elseif("test"|environment) %}
        test-environment
    {% elseif("acceptance"|environment) %}
        acceptance-environment
    {% else %}
        production-environment
    {% endif %}
{% endblock %}
