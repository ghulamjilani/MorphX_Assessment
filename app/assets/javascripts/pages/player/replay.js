//= require chaplin
//= require dom_purify
//= require anchorme
//= require views/widgets/webrtcservice/emojies
//= require views/widgets/_playlist_dependencies/replay_chat_view
//= require_self
+function (window) {
    'use strict';
    var replayClient = _.extend({}, Backbone.Events);

    Player.Views.Replay = Backbone.View.extend({
        el: '.main-content',

        initialize: function (options) {
            return this.render();
        },

        events: {
            'click #request_different_time .DatepickerWtrapp i': 'showDatepicker'
        },

        render: function () {
            this.initSliders();
            this.initPlayer();
            this.preparePage();
        },

        preparePage: function () {
            var redirect_after_signup = $.cookie('open_after_signup')
            window.redirect_after_signup = redirect_after_signup
            if(redirect_after_signup && redirect_after_signup !== "buy") {
                setTimeout(() => {
                    $(".sub_btn")[0].click()

                    setTimeout(() => {
                        $(".Buy_btn").each((i,e) => {
                            if(e.href.includes(redirect_after_signup)) {
                                e.click()
                            }
                        })
                    }, 600)
                }, 1000)
            }
            if(redirect_after_signup && redirect_after_signup === "buy") {
                var interval = setInterval(() => {
                    if($("#payment-modal").length == 0 &&
                        $(".mainVideoSection-content_block .btn-white").length > 0 &&
                        $(".mainVideoSection-content_block .btn-white")[0].text !== "Processing...")
                       {
                           $(".mainVideoSection-content_block .btn-white")[0].click()
                       }
                    if($("#payment-modal").length >= 1) {
                        clearInterval(interval)
                    }

                }, 2000)
            }

            setTimeout(() => {
                $.removeCookie('redirect_back_to_after_signup', {
                    path: '/'
                });
                $.removeCookie('open_after_signup', {
                    path: '/'
                });

            }, 2000)
        },

        initSliders: function () {
            $('.YouMayAlsoLikeTileSlider').on('initialize.owl.carousel', function () {
                $(this).parents('.TileSliderWrapp.owlSlider').find('.spinnerSlider').fadeOut();
                $(this).addClass('RedyToshow');
                $.each($(this).find('section.tile-cake'), function () {
                    var imgOBJ, imgOBJItem, itemattr;
                    imgOBJ = $(this).find('.owl-lazy');
                    imgOBJItem = $(imgOBJ).get(0);
                    itemattr = $(imgOBJItem).attr('data-src');
                    return $(imgOBJItem).css({
                        'background-image': "url('" + itemattr + "')",
                        'opacity': 1
                    });
                });
            }).owlCarousel('destroy').owlCarousel({
                items: 1,
                loop: false,
                callbacks: true,
                autoWidth: false,
                nav: true,
                navText: '',
                margin: 0,
                lazyLoad: true,
                autoplay: false,
                responsiveClass: true,
                startPosition: 0,
                responsive: {
                    0: {
                        items: 1,
                        nav: false,
                        stagePadding: 40
                    },
                    640: {
                        items: 2,
                        nav: false,
                        stagePadding: 40
                    },
                    991: {
                        items: 3
                    },
                    1940: {
                        items: 4
                    },
                    2240: {
                        items: 5
                    }
                }
            });
        },

        initPlayer: function () {
            this.player = new Player.Views.ReplayPlayer({
                channel: this.channel
            });
        }
    });

    window.ReplayView = Player.Views.Replay;

    Player.Views.ReplayPlayer = Backbone.View.extend({
        el: '#player-container',

        update_timer: true,

        initialize: function (options) {
            this.model = new Player.Models.Replay(Immerss.replay);
            this.chatView || (this.chatView = new Player.Views.ReplayChat({
                model: this.model,
                klass: 'Video'
            }));
            this.render();
            return this;
        },

        template: function (data, hbs) {
            var template;
            if (hbs == null) {
                hbs = 'sessions/player';
            }
            template = _.template(HandlebarsTemplates[hbs](data));
            return template.apply(this, arguments);
        },

        render: function () {
            var base;
            this.renderVideoPlayer();
            (base = this.model).footerView || (base.footerView = new Player.Views.VideoPlayerBottom({
                model: this.model
            }));
            this.reviewDropdown = new Player.Views.ReviewDropdown({
                model: this.model,
                klass: 'Video'
            });
            scrollerInit();
        },

        getTemplateData: function () {
            var data;
            data = {
                current_user_id: Immerss.currentUserId,
                video: this.model.toJSON()
            };
            return data;
        },

        getAspectRation: function (y, x) {//формула перевода пропорций в css формат %
            console.log('getAspectRation ', (y / x) * 100);
            console.log('getAspectRation -x ', x);
            console.log('getAspectRation -y ', y);
            return (y / x) * 100;
        },
        newX: function (oldW, oldH, newW) {//новая высота
            //Исходная высота * Нужная ширина / Исходная ширина = Нужная высота
            return ((oldH * newW) / oldW);

        },
        newY: function (oldW, oldH, newH) {//новая ширина
            //Исходная ширина * Нужная высота / Исходная высота = Нужная ширина
            return ((oldW * newH) / oldH)
        },
        setVideoContentWidth: function (newVideoWidth) {
            let rightSidebarWidth = 408,//ширина правого сайдбара всегда 408 кроме респонсива
                playerContainer = document.querySelector("#player-container");//общий контейнер для видео и правой панели
            if (!jQuery('body').hasClass('curtainActive')) {
                newVideoWidth = newVideoWidth + rightSidebarWidth;
            }
            if ((newVideoWidth) <= 1700) {
                playerContainer.style.width = newVideoWidth + 'px'; //новая ширина контейнера равна новой ширине видео + правая панель
            } else {
                playerContainer.style.width = '1700px'
            }

        },
        rebildVideoAndContetntSection: function (videoConteiner) {
            window.videoConteiner = videoConteiner
            let width = videoConteiner.videoWidth,//ширина видео исходника
                height = videoConteiner.videoHeight,//высота видео исходника
                innerHeight = window.innerHeight,//высота контента в окне браузера
                innerHeightMax = innerHeight - 250,//максимальная высота доступная для видео секции
                widthMax = 1300,//максимальная i доступная для видео секции
                playerContainer = document.querySelector("#player-container"),
                heightMax = 600,//минимальноя высота видео
                aspectRatio = this.getAspectRation(height, width);//вычесление пропорции видео
            if (jQuery('body').hasClass('curtainActive')) {
                widthMax = 1500;//минимальноя ширина видео
                innerHeightMax = innerHeight - 140
            }

            if(width > height + 20) { // горизонтальный
                width = widthMax; // по дефолту максимальная ширина (если видео меньше чем нужно)
                height = width * aspectRatio/100; // высота из расчёта соотношения сторон
                if(height > innerHeightMax) { // если высота больше максимальной - меняем ширину что бы небыло полос по бокам
                    height = innerHeightMax;
                    width = height/(aspectRatio/100);
                }
                $('.responsive-video').css('padding-top', aspectRatio + '%'); // падинг от соотношения
                this.setVideoContentWidth(width);
            } else { // вертикальный
                width = widthMax; // максимально разворачиваем видео, т.к. для вертикального можно с полосами
                height = innerHeightMax;
                $('.responsive-video').css('padding-top', height + 'px'); // падинг от высоты
                this.setVideoContentWidth(width);
            }

            window.setVideoContentWidth = this.setVideoContentWidth

            playerContainer.classList.add('VideoContentSizeChanged');
        },

        renderVideoPlayer: function () {
            var data, now, player, seekingCallback, timeupdateCallback, url, volumechangeCallback;
            now = (new Date()) * 1 / 1000;
            data = this.getTemplateData();
            url = this.$('#jwplayer_data_contaioner').data('url');
            if (url) {
                if (this.$('#jwplayer_data_contaioner').html().length === 0) {
                    player = initTheOplayer(this.$('#jwplayer_data_contaioner').data('url'), '#jwplayer_data_contaioner', data);
                    $('.unmuteButton').removeClass('hidden');
                    let videoSection = document.querySelector("video");
                    const that = this;
                    videoSection.addEventListener("canplay", function (e) {
                        that.rebildVideoAndContetntSection(this);
                        console.log(videoSection);
                        window.addEventListener("resize", function () {
                            that.rebildVideoAndContetntSection(videoSection);
                            console.log(videoSection)
                        });
                    }, false);
                    document.addEventListener('curtainActiveEvent', function (e) {
                        that.rebildVideoAndContetntSection(videoSection);
                        window.dispatchEvent(new Event('resize'));
                    }, false);
                    if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)){
                        $('.toggleLeft').dblclick(function(){
                            player.currentTime -= 10;
                        })
                        $('.toggleRight').dblclick(function(){
                            player.currentTime += 10;
                        })
                    }
                }
                if (this.model.could_be_purchased) {
                    player.addEventListener('ended', function () {
                        return $('.responsive-video').find('a.buy_replay').show();
                    });
                    player.addEventListener('play', function () {
                        return $('.responsive-video').find('a.buy_replay').hide();
                    });
                }
                seekingCallback = function () {
                    if (player.ads.playing) {
                        return;
                    }
                    return replayClient.trigger('player.seeking', {
                        eventData: {
                            currentTime: player.currentTime.toFixed(2)
                        }
                    });
                };
                timeupdateCallback = function () {
                    if (player.ads.playing) {
                        return;
                    }
                    return replayClient.trigger('player.timeUpdated', {
                        eventData: {
                            currentTime: player.currentTime.toFixed(2)
                        }
                    });
                };
                $('.unmuteButton').click(function () {
                    player.muted = !player.muted;
                })
                var fadeoutTimeout;
                var fadeOutText = function () {
                    clearTimeout(fadeoutTimeout);
                    fadeoutTimeout = setTimeout(function () {
                        $(".unmuteButton span").fadeOut();
                    }, 3000);
                }
                fadeOutText();
                volumechangeCallback = function () {
                    if (player.muted) {
                        $('.unmuteButton span').show();
                        $('.unmuteButton').fadeIn().addClass('visible');
                        fadeOutText();
                    } else {
                        $('.unmuteButton').fadeOut().removeClass('visible');
                    }
                };
                seekingCallback = _.throttle(seekingCallback, 1000);
                timeupdateCallback = _.throttle(timeupdateCallback, 1000);
                if (player) {
                    player.addEventListener('volumechange', volumechangeCallback);
                    player.addEventListener('timeupdate', timeupdateCallback);
                    player.addEventListener('seeking', seekingCallback);
                }
            }
        }
    });

    Player.Views.ReplayChat = Backbone.View.extend({

        el: '.mainVideoSection-rightSidebar',

        events: {
            'click .toggle_chat': 'toggleChat'
        },

        initialize: function (options) {
            this.setupReplayClient();
            this.render();
            return this;
        },

        setupReplayClient: function (options) {
            var Layout;
            console.log('setupReplayClient');
            if (Immerss.replay.playlist_attrs.is_chat_available) {
                this.$('.MV_Chat_section').show().addClass('active');
                this.$('.MV_Chat_section').addClass('closed').removeClass('opened');
                this.$('.toggle_chat').removeClass('active');
                this.$('.toggle_chat').text('Expand');
                this.$('section:visible:not(.MV_Chat_section):first').removeClass('chatClosed');
                this.$('.MV_Chat_section .MV_Chat_iframe').removeClass('hidden');
                Layout = chaplin.Layout.extend({
                    regions: {
                        'chatPlaceholder': '.mainVideoSection-rightSidebar .chat-container'
                    }
                });
                new Layout();
                return true
            } else {
                return $('.MV_Chat_section').hide();
            }
        },

        toggleChat: function (e) {
            e.preventDefault();
            if (this.$('.toggle_chat').hasClass('active')) {
                this.$('.toggle_chat').removeClass('active');
                this.$('.toggle_chat').text('Expand');
                this.$('.MV_Chat_section').addClass('closed').removeClass('opened');
                return this.$('section:visible:not(.MV_Chat_section):first').addClass('chatClosed');
            } else {
                this.$('.toggle_chat').addClass('active');
                this.$('.toggle_chat').text('Minimize');
                this.$('.MV_Chat_section').addClass('opened').removeClass('closed');
                return this.$('section:visible:not(.MV_Chat_section):first').removeClass('chatClosed');
            }
        }
    });
}(window);
