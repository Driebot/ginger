{#
    dynamic: whether the list items should be based on current search results
    sort_by_count: sort the list by doc count instead of alphabetically (default)
#}
{% with
    buckets|default:q.buckets,
    q.values,
    title|default:_"Term",
    property,
    dynamic|default:false,
    sort_by_count|default:false,
    options_template|default:"search/components/filter-terms-options.tpl"
as
    buckets,
    values,
    title,
    property,
    dynamic,
    sort_by_count,
    options_template
%}
    <div class="search__filters__section is-open do_search_cmp_filter_terms" data-property="{{ property }}" data-dynamic="{{ dynamic }}" data-sort-by-count="{{ sort_by_count }}" data-update-event="{{ #search_filter_update}}">
        <h3 class="search__filters__title">{{ title }}</h3>
        <ul id="{{ #search_filter }}"></ul>
    </div>

    {% wire name=#search_filter_update action={update target=#search_filter template=options_template dynamic=dynamic} %}
{% endwith %}