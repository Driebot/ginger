<div class="container-fluid">
    <div class="row">
        <footer class="col-xs-12 col-sm-12 col-md-12 col-lg-12">
            <small>Powered by <a href="http://zotonic.com"><span class="zotonic-logo"><em>Zotonic</em></span></a></small>
        </footer>
    </div>
</div>

{# Chose for a js adding of class since we prefer not to overwrite the admin_base.tpl #}
{% javascript %}
    document.body.classList.add("{% if("dev"|environment) %}env--dev{% elseif("test"|environment) %}env--test{% elseif("acceptance"|environment) %}env--acc{% else %}env--prod{% endif %}");
{% endjavascript %}
