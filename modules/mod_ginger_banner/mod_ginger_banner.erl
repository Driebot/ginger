-module(mod_ginger_banner).
-author("Driebit <info@driebit.nl>").

-mod_title("Ginger banner module").
-mod_description("Shows a banner on all pages that can be configured through site config or a resource.").
-mod_prio(500).

-mod_schema(1).

-include_lib("zotonic.hrl").

-export([
    manage_schema/2
]).

manage_schema(_Version, _Context) ->
    #datamodel{
        resources = [
            {message_banner, text, [
                {title, "Banner"},
                {is_published, false}
            ]}
        ]
    }.
