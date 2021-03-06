 <form class="ginger-search {{ extraClasses }}" id="ginger-search-form-{{ identifier }}" role="search" action="{% if context %}/{{ context }}_search{% else %}{% url search %}{% endif %}" method="get">
    <div class="ginger-search_form-group">
        <input type="hidden" name="qsort" value="{{ q.qsort|escape }}" />
        <input type="hidden" name="qcat" value="{{ q.qcat|escape }}" />
        <input type="hidden" name="qcg" value="{{ cg_name }}" />
        <input type="text" 
            class="ginger-search_form-control do_ginger_search"
            name="qs" 
            value="{{q.qs|escape}}" 
            placeholder="{_ Search _}" 
            autocomplete="off"
            data-param-wire="show-suggestions-{{ identifier }}" 
            data-param-results="ginger-search-suggestions-{{ identifier }}" 
            data-param-container="ginger-search-form-{{ identifier }}"  />
    </div>
    <button type="submit" class="ginger-search_submit-btn" title="zoek"></button>

    {% wire name="show-suggestions-"++identifier
        action={update target="ginger-search-suggestions-"++identifier template="_search_suggestions.tpl" cat_exclude=cat_exclude context=context}
    %}
    <div class="ginger-search_suggestions" id="ginger-search-suggestions-{{ identifier }}">--</div>
</form>