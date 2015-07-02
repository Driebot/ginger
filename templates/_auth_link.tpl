{# Render link that opens a modal login/signup dialog. #}

{% if not m.acl.user %}

    {% with
        class|default:"main-nav__login-register-button",
        icon|default:"glyphicon glyphicon-log-in",
        icon_before,
        label|default:_"logon/signup"
    as
        class,
        icon,
        icon_position,
        label
    %}

    {% lib
        "css/logon.css"
    %}

    {% if icon_before %}
        <a class="{{ class }}" id="{{ #signup }}" href="#"><span class="{{ icon }}"></span> {{ label }}</a>
    {% else %}
        <a class="{{ class }}" id="{{ #signup }}" href="#">{{ label }}<span class="{{ icon }}"></span></a>
    {% endif %}

    {% wire
        id=#signup
        action={
            dialog_open
            title=title|default:_"Log in or sign up"
            template=dialog_template|default:"_action_dialog_authenticate.tpl"
            tab=tab|default:"logon"
            redirect=m.req.path
        }
    %}

    {% endwith %}
{% endif %}
