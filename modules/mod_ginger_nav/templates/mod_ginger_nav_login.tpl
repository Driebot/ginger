  




<!-- {% with m.rsc[id].uri as page %}
{% if m.acl.user %}       

    <a href="#" class="mod_ginger_nav__top-button nav__user" data-toggle="popover" title="{_ Share _}" data-content="

    <ul class='nav__user__buttons'>
        <li>
            <a href='#' id='{{ #ginger_logoff }}' class='mod_ginger_nav__top-button mod_ginger_nav__main-nav__log-out'>
                <span class='glyphicon glyphicon-log-out'>&nbsp;</span>
            </a>
        </li>
        <li><a href='#'>&nbsp;</a></li>
    </ul>


    ">
        {% with m.rsc[m.acl.user] as user %}
            {% if m.rsc[id.o.author.id].depiction %}
                {% image m.rsc[m.acl.user].depiction class="avatar" mediaclass="avatar" alt=" " %}
            {% endif %}
        {% endwith %}
    </a>
    

{% else %}





{% endif %}

{% endwith %}

 -->








<!-- {% with m.rsc[id].uri as page %}
{% if m.acl.user %}          
    
        <a href="#" id="{{ #ginger_logoff }}" class="mod_ginger_nav__top-button mod_ginger_nav__main-nav__log-out">
            <span class="glyphicon glyphicon-log-out">&nbsp;</span>
        </a>

        <a href="{{ m.rsc[m.acl.user].page_url }}" class="mod_ginger_nav__top-button mod_ginger_nav__main-nav__user-button">
            <span class="glyphicon glyphicon-user">&nbsp;</span>
            <span>&nbsp;</span>
        </a>    

    {%
        wire id=#ginger_logoff
        postback={ginger_logoff page=page id=id}
        delegate="ginger_logon"
    %}
{% else %}

    <a href="#" id="{{ #ginger_logon }}" class="mod_ginger_nav__top-button mod_ginger_nav__main-nav__user-button">
        <span class="glyphicon glyphicon-user">&nbsp;</span>
        <span>{_ logon/register _}</span>
    </a>

    {%
        wire id=#ginger_logon 
        action={dialog_open template="_action_dialog_authenticate.tpl" 
                        title=_"logon or register"
                        template="_action_dialog_authenticate.tpl"
                        action={redirect id=id}
                        id=id
                        tab="logon"}
    %}
{% endif %}
{% endwith %} -->