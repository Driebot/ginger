
$.widget( "ui.carousel", {

    _create: function() {

         var me = this,
             widgetElement = $(me.element),
             id = widgetElement.attr('id'),
             slick = null,
             options = $(widgetElement).data('options');

        if (this.options){
            $(widgetElement).slick(this.options);
        } else {
            $(widgetElement).slick();
        }
    }

});

