{% extends "_email_base.tpl" %}

{# {% block body_width %}{% endblock %} #}

{% block header %}
    <tr>
        <td>
            <table>
                <tr>
                    <td><img src="/lib/images/logo.png"></td>
                    <td width="20"></td>
                    <td>{{ m.config.site.title.value }}</td>
                </tr>
            </table>
        </td>
    </tr>
{% endblock %}

{% block footer %}
    <tr>
        <td style="background-color: #2f3337;"></td>
    </tr>
{% endblock %}
