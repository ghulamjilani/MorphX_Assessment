//animation
$(function(){



    var winHeight;
    var field = $(".field_for_buble");

    winRsize();
    $(window).resize(function() {
        winRsize();
    });
    function winRsize() {
        winHeight = $(window).height();
        field.height(winHeight);
    }

    var items = 100;
    for (var i=0; i<=items; i++) {
        var move = Math.ceil( Math.random()*50 );
        var pos = Math.ceil( Math.random()*50 );
        var scale = Math.ceil( Math.random()*10 );
        var stretch = Math.ceil( Math.random()*5 );
        var shake = Math.ceil( Math.random()*5 );
        field.append('<div class="bubble move'+move+' pos'+pos+'"><div class="scale'+scale+'"><div class="shake'+shake+'"><span class="item stretch'+stretch+'"></span></div></div>');
    }
    // tooltipInit
    $('[rel=tooltip]').tinytooltip({
        message: function(tip) {
            return $(this).attr('data-tip');
        }
    });
});
//animation end