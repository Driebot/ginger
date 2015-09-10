{% with m.acl.user as user_id %}
    {% if user_id or m.config.mod_comment.anonymous.value|default_if_undefined:1 %}

        {% if m.config.comments.moderate.value %}
            <div id='comments-moderation-notice' style='display: none'>
    	        <h2>Your comment</h2>
    	        <p>{_ Your comment has been saved and will be subject to review before it is displayed to other visitors of the website. Thank you for your comment! _}</p>
            </div>
            {% wire id="comments-form" type="submit" postback={newcomment id=id} delegate="mod_comment" action={fade_out target="comments-area"} action={slide_fade_in target="comments-moderation-notice"} %}
        {% else %}
            {% wire id="comments-form" type="submit" postback={newcomment id=id comment_template="comment/comment.tpl" action={update target="comments-header" template="comments/comments-header.tpl" id=id} } delegate="mod_comment" %}
        {% endif %}

        <div id="comments-area">
            <h2>{_ Leave a comment _}</h2>
            {% if m.config.comments.moderate.value %}
                <p>({_ Note: Comments are moderated _})</p>
            {% endif %}
            <form id="comments-form" method="post" action="postback" class="{% block form_class %}{% endblock %} comments__form">
                <fieldset>
	                {% if not user_id %}
                        <div class="form-group row">
	                        <label class="control-label col-md-4" for="name">{_ Name _}</label>
                            <div class="col-md-8">
		                        <input type="text" name="name" id="name" class="form-control" />
		                        {% validate id="name" type={presence} %}
	                        </div>
                        </div>

                        <div class="form-group row">
	                        <label class="control-label col-md-4" for="mail">{_ E-mail _}</label>
                            <div class="col-md-8">
		                        <input type="text" name="mail" id="mail" class="form-control" />
		                        {% validate id="mail" type={presence} type={email} %}
	                        </div>
	                    </div>
	                {% endif %}

                    <div class="form-group">
	                    <label class="control-label" for="message">{_ Message _}</label>

	                    <textarea name="message" id="message" cols="60" rows="8" class="form-control"></textarea>
	                    {% validate id="message" type={presence} %}
                    </div>

                    <div class="form-group">
                        <button class="btn btn-primary pull-right" type="submit">{_ Send _}</button>
	                </div>

	                <div>
	                    <input type="hidden" name="user_agent" value="{{ m.req.user_agent|escape }}" />
                    </div>

                </fieldset>
            </form>
        </div>

    {% else %}
        <p id="comments-logon"><a href="{% url logon back %}">{_ Log on or sign up to comment _}</a>.</p>
    {% endif %}
{% endwith %}
