<!DOCTYPE html>
<!--
#################################
      _      _      _     _ _
   __| |_ __(_) ___| |__ (_) |_
  / _` | '__| |/ _ \ '_ \| | __|
 | (_| | |  | |  __/ |_) | | |_
  \__,_|_|  |_|\___|_.__/|_|\__|

############ driebit ############

 geavanceerde internetapplicaties

        Oudezijds Voorburgwal 282
                1012 GL Amsterdam
                   020 - 420 8449
                  info@driebit.nl
                   www.driebit.nl

#################################
//-->
<html lang="{{ q.lang|default:"nl" }}">
    <head>
        <title>
            {% block title %}
                {% if id %}
                    {{ id.seo_title|default:id.title ++ " - " ++ m.config.site.title.value }}
                {% else %}
                    {{ m.config.site.title.value }}
                {% endif %}
            {% endblock %}
        </title>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

        {% if m.config.site.title.value %}
            <meta property="og:site_name" content="{{ m.config.site.title.value }}"/>
        {% endif %}

        <meta property="og:url" content="https://{{ m.site.hostname }}{{ id.default_page_url }}"/>
        <meta property="og:title" content="{{ id.title }}" />
        <meta property="og:description" content="{{ id.id|summary:160 }}"/>
        <meta property="og:image:width" content="450" />
        <meta property="og:image:height" content="450" />
        <meta name="twitter:card" content="summary" />
        <meta name="twitter:title" content="{{ id.title }}" />
        <meta name="twitter:description" content="{{ id.id|summary:160 }}" />
        {% if id.o.depiction.id as image %}
            <meta property="og:image" content="http://{{ m.site.hostname }}{% image_url image mediaclass='opengraph' %}" />
            <meta property="twitter:image" content="http://{{ m.site.hostname }}{% image_url image mediaclass='opengraph' %}" />
        {% elif id.o.hascover.id as image %}
            <meta property="og:image" content="http://{{ m.site.hostname }}{% image_url image mediaclass='opengraph' %}" />
            <meta property="twitter:image" content="http://{{ m.site.hostname }}{% image_url image mediaclass='opengraph' %}" />
        {% else %}
            <meta property="og:image" content="http://{{ m.site.hostname }}/lib/dist/assets/ogdata.jpg" />
            <meta property="twitter:image" content="http://{{ m.site.hostname }}/lib/dist/assets/ogdata.jpg" />
        {% endif %}

        <link rel="apple-touch-icon" sizes="57x57" href="/lib/dist/assets/icons/apple-icon-57x57.png">
        <link rel="apple-touch-icon" sizes="60x60" href="/lib/dist/assets/icons/apple-icon-60x60.png">
        <link rel="apple-touch-icon" sizes="72x72" href="/lib/dist/assets/icons/apple-icon-72x72.png">
        <link rel="apple-touch-icon" sizes="76x76" href="/lib/dist/assets/icons/apple-icon-76x76.png">
        <link rel="apple-touch-icon" sizes="114x114" href="/lib/dist/assets/icons/apple-icon-114x114.png">
        <link rel="apple-touch-icon" sizes="120x120" href="/lib/dist/assets/icons/apple-icon-120x120.png">
        <link rel="apple-touch-icon" sizes="144x144" href="/lib/dist/assets/icons/apple-icon-144x144.png">
        <link rel="apple-touch-icon" sizes="152x152" href="/lib/dist/assets/icons/apple-icon-152x152.png">
        <link rel="apple-touch-icon" sizes="180x180" href="/lib/dist/assets/icons/apple-icon-180x180.png">
        <link rel="icon" type="image/png" sizes="192x192" href="/lib/dist/assets/icons/android-icon-192x192.png">
        <link rel="icon" href="/lib/dist/assets/icons/favicon.ico">
        <meta name="msapplication-TileColor" content="#ffffff">
        <meta name="msapplication-TileImage" content="/lib/dist/assets/icons/ms-icon-144x144.png">
        <meta name="theme-color" content="#ffffff">
        {% include "_html_head_seo.tpl" %}

        {% lib "dist/main.js" %}
        {% lib "dist/style.css" %}

    </head>

    <body>
        <script type="text/javascript">
            var menu = {
                main_menu: [
                    {% for id, submenu in m.rsc.main_menu.menu %}
                    {
                        page_url: "{{ id.page_url }}",
                        title: "{{ id.short_title|default:id.title }}",
                        id: {{ id.id }}
                    },
                    {% endfor %}
                ],
                footer_menu: {
                    subtitle: "{{ m.rsc.footer_menu.subtitle }}",
                    summary: "{{ m.rsc.footer_menu.summary }}",
                    items: [
                        {% for id, submenu in m.rsc.footer_menu.menu %}
                        {
                            page_url: "{{ id.page_url }}",
                            title: "{{ id.short_title|default:id.title }}",
                            id: {{ id.id }}
                        },
                        {% endfor %}
                    ]
                }
            };

            var app = Elm.Main.init({flags: menu});
        </script>
    </body>
</html>
