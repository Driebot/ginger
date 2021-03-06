{% if m.config.mod_ginger_rdf.source or "find_rdf"|member:tabs_enabled %}

    <div class="tab-pane" id="{{ tab }}-linked-data">

        <form id="dialog-connect-find-linked-data">

            <input type="hidden" name="subject_id" value="{{ subject_id }}" />
            <input type="hidden" name="predicate" value="{{ predicate|default:'' }}" />

            <div class="form-group">
                <input name="find_text" type="text" value="{{ text|default:'' }}" placeholder="{_ Search linked data _}" class="do_autofocus form-control" />
            </div>

            <div id="dialog-connect-found-linked-data" class="do_feedback"
                data-feedback="trigger: 'dialog-connect-find-linked-data', delegate: 'mod_ginger_rdf', template: '_action_dialog_connect_tab_find_linked_data_results.tpl'">
            </div>

            <div class="modal-footer">
                <a class="btn btn-default" id="{{ #close }}">
                    {% if autoclose %}{_ Cancel _}{% else %}{_ Ok _}{% endif %}
                </a>
                {% wire id=#close action={dialog_close} %}
            </div>

        </form>

    </div>

    {% wire name="dialog_connect_find_linked_data"
        action={postback
            delegate="mod_ginger_rdf"
            postback={admin_connect_select
                id=id
                subject_id=subject_id
                predicate=predicate
                callback=callback
                language=language
                action=action
                actions=actions
            }
        }
    %}
    {% javascript %}
        $('#dialog-connect-find-linked-data').submit(function() { return false; });
        $('#dialog-connect-find-linked-data').change();
        $("#dialog-connect-found-linked-data").on('click', '.thumbnail', function(e) {
            e.preventDefault();
            z_event('dialog_connect_find_linked_data', {
                object_props: $(this).data(),
                object: $(this).data('id'),
                object_title: $(this).data('title')
            });
            $(this).effect("highlight").toggleClass("thumbnail-connected");
            $('#{{ #close }}').removeClass("btn-default").addClass("btn-primary");
        });
    {% endjavascript %}
{% endif %}
