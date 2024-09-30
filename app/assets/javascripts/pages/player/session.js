+function () {
    'use strict'

    var checkWaitingPlayer = false
    var livestreamWasDown = false
    var waitMessage = false
    var reviewCreated = false
    var needToReinitPlayer = false
    var sessionStarted = false

    Player.Views.Session = Backbone.View.extend({
        el: '.main-content',

        events: {
            'click .ShowAboutText': 'toggleShowAbout',
            'click #request_different_time .DatepickerWtrapp i': 'showDatepicker'
        },

        initialize: function (options) {
            console.log('Player.Views.Session::init')
            console.log(options)
            this.model = new Player.Models.Session(options.session)
            this.listenTo(this.model, 'rating_updated', this.updateRating)
            this.listenTo(this.model, 'livestream_members_count', this.updateViewersCount)
            this.listenTo(this.model, 'total_participants_count_updated', this.updateParticipantsCount)
            this.initWebsocket()
            return this
        },

        render: function () {
            this.initSliders()
            this.player = new Player.Views.SessionPlayer({
                model: this.model
            })
            this.chat = new Player.Views.Chat({
                model: this.model
            })
            this.initRequestDifferentTimeForm()
            this.preparePage()
            window.reinitializePlayer = this.reinitializePlayer.bind(this)
        },

        initWebsocket: function () {
            this.subscribeToPublicSessionsChannel()
            this.subscribeToPrivateUserChannel()
            this.subscribeToLivestreamRoomsChannels()
            this.subscribeToVueEventHub()
        },

        subscribeToVueEventHub: function () {
            var _this = this
            if(window.eventHub) {
                window.eventHub.$on("review-created", () => {
                    reviewCreated = true
                    _this.model.trigger("show-rating-title")
                })
            }
            else {
                setTimeout(() => {
                    _this.subscribeToVueEventHub()
                }, 300)
            }
        },

        reinitializePlayer: function () {
            console.log('!!! Player.Views.Session::reinitializePlayer')
            needToReinitPlayer = false
            this.player = new Player.Views.SessionPlayer({
                model: this.model
            })
        },

        subscribeToPublicSessionsChannel: function () {
            this.publicSessionsChannel = initSessionsChannel(this.model.get('id'))
            this.publicSessionsChannel.bind(sessionsChannelEvents.sessionStarted, (function (_this) {
                return function (data) {
                    var session_id
                    console.log(['session-started', data])
                    session_id = data.session_id
                    $.ajax({
                        type: 'GET',
                        url: Routes.get_join_button_session_path(session_id),
                        dataType: 'json',
                        contentType: 'application/json',
                        success: function (data) {
                            console.log(['session-started::success', data])
                            if (_this.model.id === session_id) {
                                _this.model.trigger('session-started', data)
                            }
                            _this.model.trigger("show-rating-title")
                        }
                    })
                }
            })(this))
            this.publicSessionsChannel.bind(sessionsChannelEvents.sessionStopped, (function (_this) {
                return function (data) {
                    var session_id
                    console.log(['session-stopped', data])
                    session_id = data.session_id
                    if (_this.model.id === session_id) {
                        _this.model.trigger('session-stopped', data)
                    }
                }
            })(this))
            this.publicSessionsChannel.bind(sessionsChannelEvents.sessionCancelled, (function (_this) {
                return function (data) {
                    var session_id
                    console.log(['session-cancelled', data])
                    session_id = parseInt(data.session_id)
                    if (parseInt(_this.model.id) === session_id) {
                        _this.model.set({
                            cancelled: true
                        })
                        _this.model.trigger('session-cancelled', data)
                    }
                }
            })(this))
            this.publicSessionsChannel.bind(sessionsChannelEvents.newVideoPublished, (function (_this) {
                return function (data) {
                    var session_id
                    console.log(['new_video_published', data])
                    session_id = parseInt(data.session_id)
                    if (parseInt(_this.model.id) === session_id) {
                        $(".checkLater").css("display", "none")
                        $(".newVideoTranscoded").css("display", "block")
                        $(".newVideoTranscoded a")[0].href = data.video.relative_path
                    }
                }
            })(this))
        },

        subscribeToPrivateUserChannel: function () {
            if (window.Immerss.currentUserId) {
                // TODO: remove?
                this.privateUserChannel = initUsersChannel()
                this.privateUserChannel.bind(usersChannelEvents.backstageUpdateJoin, function (data) {
                    console.log(['backstage-update-join', data])
                })
            }
        },

        subscribeToLivestreamRoomsChannels: function () {
            if (this.model.get('livestream_channel')) {
                this.privateLivestreamChannel = initPrivateLivestreamRoomsChannel(this.model.get('room_id'))
            }

            this.publicLivestreamChannel = initPublicLivestreamRoomsChannel(this.model.get('room_id'))

            var that, channel
            that = this

            channel = this.privateLivestreamChannel || this.publicLivestreamChannel

            channel.bind(privateLivestreamRoomsChannelEvents.joinAll, function (data) {
                console.log(['join-all', data])
                if (window.location.pathname !== data.relative_path && (data.user_id === 'all' || data.user_id === Immerss.currentUserId)) {
                    $.showFlashMessage(
                        "Livestream has already started. Enjoy! Please click <a href='" + data.relative_path + "'>Join</a> if stream did not start automaticaly.",
                        {type: 'info', timeout: 20000})
                }
                that.model.trigger('join-member', data)
            })

            // Private events
            if (this.privateLivestreamChannel) {
                // Polls

                this.privateLivestreamChannel.bind(privateLivestreamRoomsChannelEvents.enablePoll, function (data) {
                    that.model.polls.trigger('enable-poll', data.poll_id)
                })
                this.privateLivestreamChannel.bind(privateLivestreamRoomsChannelEvents.disablePoll, function (data) {
                    that.model.polls.trigger('disable-poll', data)
                })
                this.privateLivestreamChannel.bind(privateLivestreamRoomsChannelEvents.addPoll, function (data) {
                    that.model.polls.trigger('add-poll')
                })
                this.privateLivestreamChannel.bind(privateLivestreamRoomsChannelEvents.votePoll, function (data) {
                    that.model.polls.trigger('vote-poll', data.poll_data)
                })
                this.privateLivestreamChannel.bind(privateLivestreamRoomsChannelEvents.joinMember, function (data) {
                    if (data.user_id === window.Immerss.currentUserId) {
                        that.model.trigger('join-member', data)
                    }
                })
            }

            // Stream status events
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.livestreamDown, function (data) {
                that.model.trigger('livestream-down', data)
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.livestreamOff, function (data) {
                that.model.trigger('livestream-down', data)
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.livestreamUp, function (data) {
                that.model.trigger('livestream-up', data)
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.livestreamEnded, function (data) {
                that.model.trigger('livestream-ended', data)
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.brb, function () {
                that.model.trigger('brb')
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.brbOff, function () {
                that.model.trigger('brb-off')
            })

            // Stream counters events
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.ratingUpdated, function (data) {
                that.model.trigger('rating_updated', data)
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.livestreamMembersCount, function (data) {
                that.model.trigger('livestream_members_count', data)
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.totalParticipantsCountUpdated, function (data) {
                that.model.trigger('total_participants_count_updated', data)
            })

            // Chat events
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.enableChat, function (data) {
                that.model.trigger('enable-chat', data)
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.disableChat, function (data) {
                that.model.trigger('disable-chat', data)
            })

            // Products events
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.enableList, function (data) {
                that.model.trigger('enable-list', data)
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.disableList, function (data) {
                if (that.model.lists) {
                    that.model.lists.trigger('disable-lists', data)
                }
            })
            this.publicLivestreamChannel.bind(publicLivestreamRoomsChannelEvents.productScanned, function (data) {
                that.model.trigger('product_scanned', data)
            })
        },

        initSliders: function () {
            $('.YouMayAlsoLikeTileSlider').on('initialize.owl.carousel', function () {
                $(this).parents('.TileSliderWrapp.owlSlider').find('.spinnerSlider').fadeOut()
                $(this).addClass('RedyToshow')
                $.each($(this).find('section.tile-cake'), function () {
                    var imgOBJ, imgOBJItem, itemattr
                    imgOBJ = $(this).find('.owl-lazy')
                    imgOBJItem = $(imgOBJ).get(0)
                    itemattr = $(imgOBJItem).attr('data-src')
                    $(imgOBJItem).css({
                        'background-image': "url('" + itemattr + "')",
                        'opacity': 1
                    })
                })
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
            })
        },

        initRequestDifferentTimeForm: function () {
            var $form, $modal
            $modal = this.$('#RequestDifferentTimeModal')
            if (!($modal && $modal.find('#datepicker'))) {
                return
            }
            $form = this.$('#request_different_time')
            $form.validate({
                rules: {
                    'requested_at_date': {
                        required: true
                    },
                    'session[requested_at(4i)]': {
                        required: true
                    },
                    'session[requested_at(5i)]': {
                        required: true
                    },
                    'session[delivery_method]': {
                        required: true
                    },
                    'session[comment]': {
                        required: true,
                        minlength: 3,
                        maxlength: 250
                    }
                },
                ignore: '.ignore',
                errorElement: "span",
                errorPlacement: function (error, element) {
                    error.appendTo(element.parents('.input-block, .select-block').find('.errorContainerWrapp')).addClass('errorContainer')
                },
                highlight: function (element) {
                    $(element).parents('.input-block, .select-block').addClass('error').removeClass('valid')
                },
                unhighlight: function (element) {
                    $(element).parents('.input-block, .select-block').removeClass('error').addClass('valid')
                }
            })
            $modal.find('.styled-datepicker').val(Immerss.requestDifferentTimeDefaultValue)
            $modal.find('#datepicker').datepicker({
                minDate: '+1D',
                maxDate: '+3M',
                numberOfMonths: 1,
                showOn: 'focus',
                dateFormat: 'dd MM yy',
                setDate: Immerss.requestDifferentTimeDefaultValue,
                onSelect: function () {
                    var date
                    date = $modal.find('#datepicker').datepicker('getDate')
                    $('[id*=requested_at_1i]').val(date.getFullYear())
                    $('[id*=requested_at_2i]').val(date.getMonth() + 1)
                    $('[id*=requested_at_3i]').val(date.getDate())
                }
            })
        },

        preparePage: function () {
            var $adBtn
            if (window.location.hash.indexOf('reviews') !== -1) {
                this.$('a[href="#reviews"]').click()
                this.$('#comment_comment').focus()
            }
            $adBtn = $('.kontainer .acceptDeclineBlock a')
            $adBtn.hover((function () {
                $adBtn.not($(this)).addClass('notActive')
            }), function () {
                $adBtn.removeClass('notActive')
            })

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
                })
                $.removeCookie('open_after_signup', {
                    path: '/'
                })

            }, 2000)

        },

        showDatepicker: function () {
            this.$('#RequestDifferentTimeModal #datepicker').datepicker('show')
        },

        updateRating: function (data) {
            this.$('.rating_avg').html(data.rating + '/5')
        },
        updateViewersCount: function (data) {
            this.$('.viewsCount').html("<i class='VideoClientIcon-Views'></i> " + data.count)
        },
        updateParticipantsCount: function (data) {
            this.$('.participantsCount').html("<i class='VideoClientIcon-user-mk2'></i> " + data.count)
        },
    })

    window.SessionShowView = Player.Views.Session

    Player.Views.SessionPlayer = Backbone.View.extend({

        el: '.mainVideoSection',

        events: {
            'ajax:beforeSend a.remind_me': 'disableRemindMe',
            'ajax:complete a.remind_me': 'toggleRemindMe'
        },

        initialize: function (options) {
            this.player = null
            this.render()
            scrollerInit()
            this.timer = new Player.Views.Timer({
                model: this.model
            })
            this.footerView = new Player.Views.SessionPlayerBottom({
                model: this.model
            })
            this.listenTo(this.timer, 'countEnd', this.waitForCreator)
            this.timer.render()
            this.listenTo(this.model, 'session-started', this.streamStarted)
            this.listenTo(this.model, 'session-cancelled', this.showMoreFromPresenter)
            this.listenTo(this.model, 'session-rated', this.showMoreFromPresenter)
            this.listenTo(this.model, 'livestream-ended', this.streamEnded)
            this.listenTo(this.model, 'join-member', this.joinMember)
            this.listenTo(this.model, 'livestream-down', this.streamDown)
            this.listenTo(this.model, 'livestream-up', this.streamUp)
            this.listenTo(this.model, 'brb', this.streamBrb)
            this.listenTo(this.model, 'brb-off', this.streamBrbOff)
            this.listenTo(this.model, 'show-rating-title', this.showRatingTitle)
            this.initEventListeners()
        },

        initEventListeners: function () {
            if (!this.model.isLivestream())
                return false
            // var view = this
            // view.$('#btn-watch-livestream').on('click', function () {
            //     if (view.model.get('stream_url')) {
            //         view.showPlayer()
            //     } else {
            //         view.getStreamUrl()
            //     }
            //     view.$('.MVc-bottomLine').html('<p>Please wait. Livestream starting soon.</p>')
            //     $('body').removeClass('visit_sessionPage_first')
            //     // view.footerView.show()
            // })
        },

        joinBtnOnClick: function () {
            return "try{ lastPlayer.pause(); lastPlayer.muted = true; }catch(e){}; var isRoomExists = true; var message = ''; $.ajax({ url: '" + (Routes.room_existence_lobby_path(this.model.get('room_id'))) + "', async: false }).fail(function(response){ message = response.responseJSON.message; isRoomExists = false; }); if(isRoomExists){ window.open('" + (Routes.lobby_path(this.model.get('room_id'), {
                source_id: null
            })) + "', "+ I18n.t('assets.javascripts.session.join_btn_on_click') +", 'width=' + parseInt(screen.width - screen.width * 0.1) + ', height=' + parseInt(screen.height - screen.height * 0.1) + ', resizable=yes, top='+ parseInt(screen.height * 0.1 / 2) +', left=' + parseInt(screen.width * 0.1 / 2) + ', scrollbars=yes, status=no, menubar=no, toolbar=no, location=no, directories=no'); }else{ $.showFlashMessage(message, {type: 'error'}); }"
        },

        template: function (data, hbs) {
            var template
            template = _.template(HandlebarsTemplates[hbs](data))
            return template.apply(this, arguments)
        },

        render: function () {
            this.$('.mainVideoSection-content_block').removeClass('hide')
            this.$('.mainVideoSection-body .MVc-topLine').hide()
            this.showReview()
            if (this.model.get('brb')) {
                this.streamBrb()
            }
        },

        joinMember: function (data) {
            this.model.set({active: true, running: true, started: true})
            if (data.url) {
                this.model.set({stream_url: data.url})
            }
            if (data.livestream_up) {
                this.model.set({livestream_up: data.livestream_up})
            }
            if (this.model.get('livestream_up')) {
                this.streamUp(data)
            } else {
                this.streamDown(data)
            }
        },

        showRatingDropdown: function () {
            console.log('Player.Views.SessionPlayer::showRatingDropdown')
            if (this.model.canAccessLivestream()) {
                this.model.set({can_rate: true})
                this.showRatingTitle()
                if ($('.ratingWrapp .ratingDropDown').hasClass('hidden')) {
                    // $('.ratingWrapp').removeAttr('title')
                    $('.ratingWrapp .ratingDropDown').removeClass('hidden')
                }
            }
        },

        showRatingTitle: function() {
            if($('.ratingWrapp')) {
                var title = ""
                if(!Immerss.currentUserId) {
                    title = I18n.t('sessions.ratings.not_loggined')
                }
                else if(!this.model.get('review') && !reviewCreated) {
                    title = I18n.t('sessions.ratings.add_review')
                }
                else {
                    title = I18n.t('sessions.ratings.edit_review')
                }

                $('.ratingWrapp').attr("title", title)
            }
        },

        streamStarted: function (data) {
            console.log('Player.Views.SessionPlayer::started')
            this.hideHint()
            this.model.set({
                started: true
            })
            if (this.model.get('owner')) {
                $('ul#session_actions_dropdown li:not(.edit):not(.invite):not(.participants):not(.clone)').remove()
            }
            if (this.model.canAccessLivestream()) {
                this.showRatingDropdown()
                // this.footerView.show()
                if (this.model.onlyLivestreamIsAvailable()) {
                    this.$el.addClass('flashActive')
                    this.$('#flash_container').html(this.template(this.model.toJSON(), 'sessions/show/messages/started'))
                } else {
                    this.$el.removeClass('flashActive')
                    this.$('#flash_container').html('')
                    // this.$('#btn-watch-livestream').show()
                }
            }
            if(this.model.canAccessImmersive()){
                this.$('.MVc-bottomLine .join_line').removeClass('hidden')
                this.$('.join_interactive').attr('disabled', true)
            }
        },

        streamEnded: function (data) {
            var current_time, waiting_count
            console.log('Player.Views.SessionPlayer::stopped')
            console.log(data)
            if(waitMessage) {
                this.hideWait()
            }
            this.model.set({stopped: true, finished: true, ended: true, running: false})
            if (this.model.get('owner')) {
                $('ul#session_actions_dropdown li:not(.participants):not(.clone)').remove()
            }
            if (this.player) {
                waiting_count = 0
                current_time = null
                this.player.addEventListener('waiting', (function (_this) {
                    return function (e) {
                        console.log('waiting event detected!')
                        console.log(e.currentTime)
                        waiting_count++
                        if (current_time === null) {
                            current_time = e.currentTime
                        }
                        if (waiting_count > 1 && current_time === e.currentTime && _this.model.get('livestream_up')) {
                            _this.model.trigger('livestream-down', {})
                        }
                    }
                })(this))
            }
            this.model.trigger('livestream-down', {})
        },

        streamDown: function (data) {
            console.log(['livestream-down', data])
            livestreamWasDown =  true

            if(data.connected === undefined || data.connected) {

                if (this.model.get('brb')) {
                    return
                }

                this.$('.status .offAir').removeClass('hidden')
                this.$('.status .live').addClass('hidden')
                if (this.model.canAccessLivestream() || this.model.get('owner')) {
                    this.model.set({can_rate: true})
                }
                if (this.model.get('livestream_up')) {
                    this.model.set({livestream_up: false})
                }
                if (this.model.get('ended') || this.model.get('stopped')) {
                    setTimeout(() => {
                        console.log("**** start event")
                        this.hidePlayer()
                        this.model.set({stream_url: null})
                        if (!this.$('#review_container').is(':visible')) {
                            this.displayEndedMessage()
                        }
                        if (this.model.checkRateAbility()) {
                            this.showReview()
                        }
                    }, 2000)
                } else if (this.model.canAccessLivestream() && !this.player) {
                    if (this.model.get('started') && this.model.onlyLivestreamIsAvailable() && this.$('#flash_container .mainVideoSection-fleshMessage.started').length === 0) {
                        this.$el.addClass('flashActive');
                        this.$('#flash_container').html(this.template(this.model.toJSON(), 'sessions/show/messages/started'));
                    } else {
                        // this.$('#btn-watch-livestream').show()
                    }
                }
            }
            else if(data.active && data.connected === false && window.player && window.player.currentTime > 0) {
                this.showWait()
            }
        },

        streamUp: function (data) {
            console.log(['livestream-up', data])

            if(!data.active) return

            if(!sessionStarted) {
                if(document.querySelector(".mobileFooterNav div[data-target='chat']"))
                    document.querySelector(".mobileFooterNav div[data-target='chat']").click()
                sessionStarted = true
            }


            this.hideHint()
            if (this.model.get('brb')) {
                return
            }

            if(waitMessage) {
                this.hideWait()
            }

            this.$('.status .offAir').addClass('hidden')
            this.$('.status .live').removeClass('hidden')

            if (this.model.canAccessLivestream() || this.model.get('owner') && this.model.isLivestream()) {
                this.model.set({can_rate: true})
                this.$el.removeClass('flashActive')
                this.$('#flash_container').html('')
            }
            this.showRatingDropdown()
            if (!this.model.get('livestream_up')) {
                this.model.set({livestream_up: true, started: true})
            }
            if (this.player) {
                var el = document.querySelector('.theo-live-control')
                if(el){
                var style = window.getComputedStyle(el, null)
                var display = style.getPropertyValue('display')
                var show = display == 'none' ? false : true
                } else {
                var show = false
                }
                if(!checkWaitingPlayer && document.querySelector('.theoplayer-skin.vjs-waiting') && show){
                    console.log("*** CLICK ON LIVE")
                    document.querySelector('.theo-live-control').click()
                    checkWaitingPlayer = true
                    // var src = window.player.src
                    setTimeout(function() {
                        if(livestreamWasDown && window.player.seeking) {
                            // window.player.src = src
                            window.reinitializePlayer()
                            needToReinitPlayer = true
                            livestreamWasDown = false
                            checkWaitingPlayer = false
                        }
                    }, 2000)
                }
                return
            }
            if (this.model.canAccessLivestream()) {
                if (this.model.onlyLivestreamIsAvailable() || this.model.get('owner')) {
                    if (this.model.get('stream_url')) {
                        this.showPlayer()
                    } else {
                        this.getStreamUrl()
                    }
                } else {
                    // this.$('#btn-watch-livestream').show()
                }
            }
        },

        getStreamUrl: function () {
            console.log('Player.Views.SessionPlayer::getStreamUrl')
            var view = this
            $.ajax({
                type: 'GET',
                url: Routes.get_stream_url_session_path(this.model.id),
                dataType: 'json',
                contentType: 'application/json',
                success: function (data) {
                    view.model.set(data)
                    view.showPlayer()
                    if (!Immerss.currentUserId && view.model.get('stream_url')) {
                        $.cookie("livestream_" + view.model.id, true, {
                            expires: 365,
                            path: '/'
                        })
                    }
                }
            })
        },

        streamBrb: function () {
            console.log('brb')
            this.model.set({brb: true})
            this.displayPausedMessage()
        },
        streamBrbOff: function () {
            console.log('brb-off')
            this.model.set({brb: false})
            this.$el.removeClass('flashActive')
            this.$('#flash_container').html('')
            this.showPlayer()
        },

        getAspectRation: function (y, x) {//формула перевода пропорций в css формат %
            return (y / x) * 100
        },
        newX: function (oldW, oldH, newW) {//новая высота
            //Исходная высота * Нужная ширина / Исходная ширина = Нужная высота
            return ((oldH * newW) / oldW)

        },
        newY: function (oldW, oldH, newH) {//новая ширина
            //Исходная ширина * Нужная высота / Исходная высота = Нужная ширина
            return ((oldW * newH) / oldH)
        },
        setVideoContentWidth: function (newVideoWidth) {
            let rightSidebarWidth = 408,//ширина правого сайдбара всегда 408 кроме респонсива
                playerContainer = document.querySelector("#player-container");//общий контейнер для видео и правой панели
            if (!jQuery('body').hasClass('curtainActive')) {
                newVideoWidth = newVideoWidth + rightSidebarWidth
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
                    height = innerHeightMax
                    width = height/(aspectRatio/100)
                }
                $('.responsive-video').css('padding-top', aspectRatio + '%'); // падинг от соотношения
                this.setVideoContentWidth(width)
            } else { // вертикальный
                width = widthMax; // максимально разворачиваем видео, т.к. для вертикального можно с полосами
                height = innerHeightMax
                $('.responsive-video').css('padding-top', height + 'px'); // падинг от высоты
                this.setVideoContentWidth(width)
            }

            window.setVideoContentWidth = this.setVideoContentWidth

            playerContainer.classList.add('VideoContentSizeChanged')
        },


        showPlayer: function () {
            if (this.player || this.model.get('brb') || !this.model.get('stream_url')) {
                return
            }
            this.$('.status .offAir').addClass('hidden')
            this.$('.status .live').removeClass('hidden')
            if (this.model.canAccessLivestream() || this.model.get('owner') && this.model.isLivestream()) {
                this.hideInfo()
                this.model.set({can_rate: true})
                this.$el.removeClass('flashActive')
                this.$('#flash_container').html('')
                this.$('#jwplayer_data_contaioner').attr('data-url', this.model.get('stream_url'))
                this.player = initTheOplayer(this.$('#jwplayer_data_contaioner').data('url'), '#jwplayer_data_contaioner', {
                    session: this.model.toJSON()
                })
                if (/Android|webOS|iPhone|iPad|iPod|BlackBerry|IEMobile|Opera Mini/i.test(navigator.userAgent)){
                    $('.toggleLeft').dblclick(function(){
                        this.player.currentTime -= 10
                    })
                    $('.toggleRight').dblclick(function(){
                        this.player.currentTime += 10
                    })
                }
                this.bindPlayerEvents()
                this.player.play()
                this.$('.mainVideoSection-content_block').addClass('hide')
                this.$('.mainVideoSection-body .MVc-topLine').show()
                this.$('.countDown').hide()
                this.hideHint()
            }
            let videoSection = document.querySelector("video")

            const that = this
            if(videoSection){
                videoSection.addEventListener("canplay", function (e) {
                    that.rebildVideoAndContetntSection(this)
                    console.log(videoSection)
                    window.addEventListener("resize", function () {
                        that.rebildVideoAndContetntSection(videoSection)
                        console.log(videoSection)
                    })
                }, false)
            }
            document.addEventListener('curtainActiveEvent', function (e) {
                that.rebildVideoAndContetntSection(videoSection)
                window.dispatchEvent(new Event('resize'))
            }, false)
        },
        hidePlayer: function() {
            if (this.player) {
                this.player.destroy()
            }
            this.player = null
            $('.unmuteButton').addClass('hidden')
            this.$('#jwplayer_data_contaioner').html('')
        },
        displayPausedMessage: function() {
            this.hidePlayer()
            this.$el.addClass('flashActive')
            this.$('#flash_container').html(this.template(this.model.toJSON(), 'sessions/show/messages/paused'))
        },
        displayEndedMessage: function() {
            this.hidePlayer()
            this.$el.addClass('flashActive')
            this.$('#flash_container').html(this.template(this.model.toJSON(), 'sessions/show/messages/ended'))
        },
        bindPlayerEvents: function () {
            if (!this.player)
                return false
            $('.unmuteButton').removeClass('hidden')
            var that = this
            $('.unmuteButton').click(function () {
                that.player.muted = !that.player.muted
            })
            var fadeoutTimeout
            var fadeOutText = function() {
                clearTimeout(fadeoutTimeout)
                fadeoutTimeout = setTimeout(function () {
                    $(".unmuteButton span").fadeOut()
                }, 3000)
            }
            fadeOutText()
            this.player.addEventListener("volumechange", function () {
                if (that.player.muted) {
                    $('.unmuteButton span').show()
                    $('.unmuteButton').fadeIn().addClass('visible')
                    fadeOutText()
                } else {
                    $('.unmuteButton').fadeOut().removeClass('visible')
                }
            })
        },

        hideInfo: function () {
            this.$('.MVc-centerLine, .MVc-bottomLine').addClass('hidden')
            this.hideHint()
        },

        hideHint: function () {
            $('body').removeClass('visit_sessionPage_first')
            $('.mainVideoSection').removeClass('SHOW__HelpDropDown')
            $('.HAS__HelpDropDown').removeClass('active')
        },

        showWait: function() {
            $('.mainVideoSection-content_block').removeClass('hide')
            $('.mainVideoSection-body .MVc-topLine').hide()
            $('.pleaseWait-centerLine').removeClass('hide')
            waitMessage = true
        },

        hideWait: function() {
            $('.mainVideoSection-content_block').addClass('hide')
            $('.mainVideoSection-body .MVc-topLine').show()
            $('.pleaseWait-centerLine').addClass('hide')
            waitMessage = false
        },

        showMoreFromPresenter: function () {
            if (this.model.get('owner')) {
                $('ul#session_actions_dropdown li:not(.participants):not(.clone)').remove()
            }
            var that = this
            $.ajax({
                url: Routes.more_from_presenter_sessions_path({
                    session_id: this.model.id
                }),
                type: 'GET',
                dataType: 'json',
                success: function (res, textStatus, jqXHR) {
                    var data = {}
                    data.model = that.model.toJSON()
                    data.replays = res
                    data.any = res.length > 0
                    that.$el.addClass('flashActiveDARK flashActive')
                    that.review.closeReview()
                    that.$el.html(that.template(data, 'sessions/show/messages/more_from_presenter'))
                    that.$('.sliderWrapper').owlCarousel({
                        items: 1,
                        loop: false,
                        callbacks: true,
                        autoWidth: false,
                        nav: true,
                        navText: '',
                        margin: 0,
                        lazyLoad: true,
                        autoplay: false,
                        info: true,
                        responsiveClass: true,
                        responsive: {
                            0: {
                                items: 1,
                                nav: false,
                                loop: false
                            },
                            640: {
                                items: 3
                            },
                            1300: {
                                items: 4
                            },
                            1960: {
                                items: 5
                            }
                        }
                    })
                },
                error: function (res, error) {
                    var data = {}
                    data.model = that.model.toJSON()
                    data.any = false
                    that.review.closeReview()
                    that.$el.html(that.template(data, 'sessions/show/messages/more_from_presenter'))
                }
            })
        },

        waitForCreator: function () {
            console.log('Player.Views.SessionPlayer::waitForCreator')
            this.hideHint()
            if (this.model && this.model.get('actual_start_at') && !this.model.get('started')) {
                if (this.model.get('start_at') > Date.now() / 1000) {
                    var view = this
                    setTimeout((function () {
                        return view.waitForCreator()
                    }), 1000)
                    return
                }
            }
            this.model.set({started: true})
            setTimeout(() => {
                if(!sessionStarted) {
                    if(document.querySelector(".mobileFooterNav div[data-target='chat']")) {
                        document.querySelector(".mobileFooterNav div[data-target='chat']").click()
                        sessionStarted = true
                    }
                }
            },500)
            this.showRatingDropdown()
            if (this.model.isLivestream() && (this.model.get('owner') || this.model.onlyLivestreamIsAvailable() && this.model.canAccessLivestream())) {
                if (this.model.get('stream_url')) {
                    this.showPlayer()
                } else {
                    this.getStreamUrl()
                }
                this.$('.MVc-bottomLine').html('<p>Please wait. Livestream starting soon.</p>')
                $('body').removeClass('visit_sessionPage_first')
                // this.footerView.show()
            } else if (this.model.onlyImmersiveIsAvailable() &&
                this.model.canAccessImmersive() &&
                this.$('.MVc-bottomLine .join_interactive').length > 0
            ) {
                this.$('.MVc-bottomLine p').remove()
                // this.$('.MVc-bottomLine').append(I18n.t('sessions.show.player.immersive.join_as_participant'))
                this.$('.MVc-bottomLine p a').attr('onclick', this.joinBtnOnClick())
                this.$('.MVc-bottomLine p a').css('float', 'none')
                this.$('.MVc-bottomLine #opt_out_dropdown').remove()
                // this.footerView.show()
            }
        },

        showReview: function () {
            this.hideHint()
            this.reviewDropdown || (this.reviewDropdown = new Player.Views.ReviewDropdown({
                model: this.model,
                klass: 'Session'
            }))
            this.review || (this.review = new Player.Views.Review({
                model: this.model,
                rd: this.reviewDropdown
            }))
            this.review.showReview()
        },

        disableRemindMe: function () {
            this.$('a.remind_me').attr('disabled', true)
            this.$('a.remind_me').addClass('disabled')
        },

        toggleRemindMe: function () {
            this.$('a.remind_me').toggleClass('active').removeClass('disabled')
            this.$('a.remind_me').removeAttr('disabled')
        },
    })

    Player.Views.Review = Backbone.View.extend({
        el: '#player-container',

        events: {
            'change .quality_of_content_rate input': 'setContentRating',
            'change .immerss_experience_rate input': 'setImmerssExperience',
            'click .save_rating': 'saveRating'
        },

        initialize: function (options) {
            this.reviewDropdown = options.rd
            this.listenTo(this.model, 'livestream-down', this.showReview)
            return this.render()
        },

        render: function () {
            return this.showReview()
        },

        template: function (data, hbs) {
            var template
            template = _.template(HandlebarsTemplates[hbs](data))
            return template.apply(this, arguments)
        },

        showReview: function () {
            console.log('Player.Views.Review::showReview')
            setTimeout(() => {
                if(this.model.get('finished') || this.model.get('ended') || this.model.get('stopped')) {
                    this.model.trigger("show-rating-title")
                }
                if (this.model && !this.model.get('review') && (this.model.get('finished') || this.model.get('ended') || this.model.get('stopped')) && this.model.checkRateAbility() && !this.model.ratedAndSaved()) {
                    this.$('.mainVideoSection-body .MVc-topLine').hide()
                    $('body').addClass('showReview_active')
                    this.$('.mainVideoSection').removeClass('flashActive').removeClass('flashActiveDARK')
                    document.querySelector('.videoBlock').classList.add('reviewOpen')
                    document.querySelector('.mainVideoSection-body').classList.add('reviewOpen')
                    document.querySelector('#player-container').classList.add('reviewOpen')
                    document.querySelector('.responsive-video').classList.add('reviewOpen')
                    document.querySelector('body').classList.add('reviewOpen')
                    this.$('.countDown').hide()
                    if (this.model.get('finished') || this.model.get('ended')) {
                        this.$('#flash_container').html(this.template(this.model.toJSON(), 'sessions/show/messages/ended'))
                    }
                    if (this.$("#review_container #session_feedback_" + this.model.id).length) {
                        this.$("#review_container #session_feedback_" + this.model.id).show()
                        if(Immerss.currentUserId){
                            window.eventHub.$emit('session-review', this.model.id, 'Session', this.model.get('show_reviews'), this.model.get('organizer_id'))
                            this.$('#flash_container').html('')
                        }
                    } else {
                        this.$('#review_container').html(this.getReviewFormContent())
                        if(Immerss.currentUserId){
                            window.eventHub.$emit('session-review', this.model.id, 'Session', this.model.get('show_reviews'), this.model.get('organizer_id'))
                            this.$('#flash_container').html('')
                        }
                    }
                    this.$('.mainVideoSection-content_block').hide()
                }
            }, 2000)
            return false
        },

        getReviewFormContent: function () {
            var data, template
            data = {
                session: this.model.toJSON(),
                current_user_id: Immerss.currentUserId,
                current_user_name: Immerss.currentUserName,
                service_experience: I18n.t('assets.javascripts.session.service_experience')
            }
            template = _.template(HandlebarsTemplates['sessions/player/new_review_form'](data))
            return template.apply(this, arguments)
        },

        initFeedbackValidator: function () {
            if (this.$('#reviewSession').data('validator')) {
                this.$('#reviewSession').data('validator').resetForm()
            } else {
                this.$('#reviewSession').validate({
                    rules: {
                        'overall_experience_comment': {
                            required: false,
                            minlength: 3,
                            maxlength: 250
                        },
                        'technical_experience_comment': {
                            required: false,
                            minlength: 3,
                            maxlength: 250
                        }
                    },
                    ignore: '.ignore',
                    focusCleanup: true,
                    focusInvalid: false,
                    errorElement: 'div',
                    errorClass: 'errorContainer',
                    errorPlacement: function (error, element) {
                        return error.appendTo(element.parents('.input-block').find('.errorContainerWrapp'))
                    },
                    highlight: function (element) {
                        return $(element).parents('.input-block').addClass('error').removeClass('valid')
                    },
                    unhighlight: function (element) {
                        return $(element).parents('.input-block').removeClass('error').addClass('valid')
                    },
                    showErrors: function (errorMap, errorList) {
                        this.defaultShowErrors()
                        return this.isValid()
                    }
                })
            }
            Forms.Helpers.resizeTextarea(this.$('#reviewSession textarea'))
            Forms.Helpers.setCount(this.$('#reviewSession textarea'))
        },

        sendRateAjax: function (data) {
            if (!Immerss.currentUserId) {
                return
            }
            data.klass = 'Session'
            $.ajax({
                url: Routes.review_rate_path(this.model.id),
                type: 'POST',
                dataType: 'json',
                data: data,
                success: (function (_this) {
                    return function (res, textStatus, jqXHR) {
                        var obj
                        console.log('review_rate:success')
                        _this.model.set((
                            obj = {},
                                obj[data.dimension + "_rate"] = data.score * 1,
                                obj
                        ))
                        if (_this.model.get('owner') && _this.model.get('immerss_experience_rate') || !_this.model.get('owner') && _this.model.get('quality_of_content_rate') && _this.model.get('immerss_experience_rate')) {
                            _this.$('#reviewSession textarea, .save_rating').removeClass('disabled').removeAttr('disabled').removeAttr('title')
                        } else {
                            _this.$('#reviewSession textarea, .save_rating').addClass('disabled').attr('disabled', true)
                        }
                        if (res.dropdown && _this.reviewDropdown) {
                            _this.reviewDropdown.$el.html($(res.dropdown).html())
                            return _this.reviewDropdown.render()
                        }
                    }
                })(this),
                error: (function (_this) {
                    return function (res, error) {
                        var message
                        _this.$('#reviewSession textarea, .save_rating').addClass('disabled').attr('disabled', true)
                        message = res.responseJSON && (res.responseJSON.error || res.responseJSON.message) || 'Something went wrong'
                        return $.showFlashMessage(message, {
                            type: 'error'
                        })
                    }
                })(this)
            })
            return false
        },

        saveReview: function () {
            var comment, data, obj, type
            if (!Immerss.currentUserId) {
                return
            }
            type = this.$('#reviewSession textarea').attr('name')
            comment = this.$('#reviewSession textarea').val()
            data = {
                skip_flash: 1,
                comment: (
                    obj = {},
                        obj["" + type] = comment,
                        obj
                ),
                klass: 'Session'
            }
            $.ajax({
                url: Routes.review_comment_path(this.model.id),
                type: 'POST',
                dataType: 'json',
                data: data,
                success: (function (_this) {
                    return function (res, textStatus, jqXHR) {
                        var obj1
                        _this.model.set((
                            obj1 = {},
                                obj1["" + type] = comment,
                                obj1
                        ))
                        _this.model.markAsRated()
                        if (res.dropdown && _this.reviewDropdown) {
                            _this.reviewDropdown.$el.html($(res.dropdown).html())
                            _this.reviewDropdown.render()
                        }
                        return _this.model.trigger('session-rated')
                    }
                })(this),
                error: (function (_this) {
                    return function (res, error) {
                        var msg
                        msg = res.responseJSON && res.responseJSON.error ? res.responseJSON.error : res.statusText || res.responseText
                        return $.showFlashMessage(msg, {
                            type: 'error'
                        })
                    }
                })(this)
            })
            return false
        },

        closeReview: function (e) {
            document.querySelector('.videoBlock').classList.remove('reviewOpen')
            document.querySelector('.mainVideoSection-body').classList.remove('reviewOpen')
            document.querySelector('#player-container').classList.remove('reviewOpen')
            document.querySelector('body').classList.remove('reviewOpen')
            if (this.model) {
                this.$("#review_container #session_feedback_" + this.model.id).hide()
            } else {
                this.$('#review_container').html('')
            }
            this.showFlash()
            return false
        },

        checkIfGuest: function (e) {
            if (!Immerss.currentUserId) {
                e.stopPropagation()
                e.preventDefault()
                window.eventHub.$emit("open-modal:auth", "login", {action: "close-and-reload"})
                // $('#loginPopup').modal('show')
                return false
            }
        },

        setContentRating: function (e) {
            var $target
            if (Immerss.currentUserId) {
                if (this.model.get('quality_of_content_rate_saved')) {
                    return false
                }
                $target = $(e.currentTarget)
                return this.sendRateAjax({
                    score: $target.val(),
                    dimension: 'quality_of_content'
                })
            } else {
                window.eventHub.$emit("open-modal:auth", "login", {action: "close-and-reload"})
                return // $('#loginPopup').modal('show')
            }
        },

        setImmerssExperience: function (e) {
            var $target
            if (Immerss.currentUserId) {
                if (this.model.get('immerss_experience_rate_saved')) {
                    return false
                }
                $target = $(e.currentTarget)
                return this.sendRateAjax({
                    score: $target.val(),
                    dimension: 'immerss_experience'
                })
            } else {
                window.eventHub.$emit("open-modal:auth", "login", {action: "close-and-reload"})
                return //$('#loginPopup').modal('show')
            }
        },

        saveRating: function () {
            if (Immerss.currentUserId) {
                if (this.model.ratedAndSaved() && this.$('#reviewSession textarea').val().length === 0) {
                    this.model.trigger('session-rated')
                } else {
                    if (this.model.get('owner') && this.model.get('immerss_experience_rate') || !this.model.get('owner') && this.model.get('quality_of_content_rate') && this.model.get('immerss_experience_rate')) {
                        if (this.$('#reviewSession textarea').val().length > 0) {
                            this.saveReview()
                        } else if (this.$('#reviewSession textarea').val().length === 0) {
                            this.model.trigger('session-rated')
                            this.model.markAsRated()
                        }
                    }
                }
            } else {
                window.eventHub.$emit("open-modal:auth", "login", {action: "close-and-reload"})
                // $('#loginPopup').modal('show')
            }
            return false
        },

        showFlash: function () {
            if (this.model.get('owner')) {
                this.$('.mainVideoSection').addClass('flashActive')
                return this.$('.mainVideoSection-fleshMessage').show()
            }
        },

        showMoreFrom: function (d) {
            var data
            data = {
                organizer: {
                    url: this.model.get('organizer_path'),
                    name: this.model.get('organizer_name'),
                    image_url: this.model.get('organizer_image')
                }
            }
            return $.ajax({
                url: Routes.more_from_presenter_sessions_path({
                    session_id: this.model.id
                }),
                type: 'GET',
                dataType: 'json',
                success: (function (_this) {
                    return function (res, textStatus, jqXHR) {
                        data.models = res
                        data.any = res.length > 0
                        _this.$('#review_container').hide()
                        return _this.closeReview()
                    }
                })(this),
                error: (function (_this) {
                    return function (res, error) {
                        data.any = false
                        _this.$('#review_container').hide()
                        return _this.closeReview()
                    }
                })(this)
            })
        },
    })

    Player.Views.Timer = Backbone.View.extend({
        el: '.mainVideoSection .LiveIn',

        initialize: function (options) {
            return this
        },

        render: function () {
            if (this.$el.length === 0) {
                this.remove()
            }
            this.$el.addClass('timer-init')
            this.loopCounter()
        },

        updateTimer: function () {
            this.timerEndAtInSeconds = parseInt(this.$el.data('timer-end-at-in-seconds'))
        },

        renderTimer: function (items) {
            this.$el.show()
            if (items !== 'countEnd') {
                if (items.dayNum) {
                    this.$('.countWrapp .count .days-left').text(items.dayNum)
                    this.$('.countWrapp .countI .days-left').text(items.dayText)
                } else {
                    this.$('.countWrapp .count .days-left').text('00')
                    this.$('.countWrapp .countI .days-left').text('Days')
                }
                if (items.hourNum) {
                    this.$('.countWrapp .count .hours-left').text(items.hourNum)
                    this.$('.countWrapp .countI .hours-left').text(items.hourText)
                } else {
                    this.$('.countWrapp .count .hours-left').text('00')
                    this.$('.countWrapp .countI .hours-left').text('Hrs')
                }
                if (items.minNum) {
                    this.$('.countWrapp .count .minutes-left').text(items.minNum)
                    this.$('.countWrapp .countI .minutes-left').text(items.minText)
                } else {
                    this.$('.countWrapp .count .minutes-left').text('00')
                    this.$('.countWrapp .countI .minutes-left').text('Min')
                }
                if (items.secNum) {
                    this.$('.countWrapp .count .sec-left').text(items.secNum)
                    this.$('.countWrapp .countI .sec-left').text(items.secText)
                } else {
                    this.$('.countWrapp .count .sec-left').text('00')
                    this.$('.countWrapp .countI .sec-left').text('Sec')
                }
            } else {
                this.$('.countWrapp .count > span').text('00')
                this.trigger('countEnd')
            }
        },

        loopCounter: function () {
            var day, hour, items, minute, secondsLeft, secondsRemaining, size
            if (this.model.get('cancelled')) {
                return
            }
            size = 4
            this.updateTimer()
            secondsLeft = this.timerEndAtInSeconds - window.serverDate.nowInSeconds()
            if (secondsLeft >= 0) {
                items = {}
                secondsRemaining = (secondsLeft * 1000) / 1000
                day = parseInt(secondsRemaining / (3600 * 24))
                secondsRemaining -= day * 3600 * 24
                if (day > 0) {
                    items.dayNum = day < 10 ? "0" + day : day
                    items.dayText = day === 1 ? 'Day' : 'Days'
                }
                hour = parseInt(secondsRemaining / 3600)
                secondsRemaining -= hour * 3600
                if (hour > 0 || day > 0) {
                    items.hourNum = hour < 10 ? "0" + hour : hour
                    items.hourText = hour === 1 ? 'Hr' : 'Hrs'
                }
                minute = parseInt(secondsRemaining / 60)
                secondsRemaining -= minute * 60
                if (minute > 0 || hour > 0 || day > 0) {
                    items.minNum = minute < 10 ? "0" + minute : minute
                    items.minText = 'Min'
                }
                secondsRemaining = parseInt(secondsRemaining)
                if (secondsRemaining > 0 || minute > 0 || hour > 0 || day > 0) {
                    items.secNum = secondsRemaining < 10 ? "0" + secondsRemaining : secondsRemaining
                    items.secText = 'Sec'
                }
                this.renderTimer(items)
                return setTimeout((function (_this) {
                    return function () {
                        return _this.loopCounter()
                    }
                })(this), 1000)
            } else if (secondsLeft < 0) {
                this.renderTimer('countEnd')
            }
        },
    })

    Player.Views.Chat = Backbone.View.extend({
        el: '.mainVideoSection-rightSidebar',

        events: {
            'click .toggle_chat': 'toggleChat'
        },

        initialize: function (options) {
            console.log('Player.Views.Chat::init')
            console.log(options)
            this.render()
            this.listenTo(this.model, 'change:started', this.showChat)
            this.listenTo(this.model, 'enable-chat', this.enableChat)
            this.listenTo(this.model, 'disable-chat', this.disableChat)
            this.listenTo(this.model, 'livestream-ended', this.hideChat)
        },

        render: function () {
            console.log('Player.Views.Chat::render')
            this.showChat()
        },

        enableChat: function (data) {
            console.log(['enable-chat', data])
            this.model.set({'allow_chat': true})
            if (this.model.canAccessLivestream()) {
                this.$('.toggle_chat').removeClass('disabled').removeAttr('disabled')
            }
            this.showChat()
        },

        disableChat: function (data) {
            console.log(['disable-chat', data])
            this.model.set({'allow_chat': false})
            this.$('.toggle_chat').text('Disabled')
            this.$('.toggle_chat').removeClass('active').addClass('disabled').attr('disabled', true)
            this.$('.MV_Chat_section').addClass('chat_disabled').addClass('closed').removeClass('opened')
            this.$('section:visible:not(.MV_Chat_section):first').addClass('chatClosed')
        },

        showChat: function () {
            console.log('Player.Views.Chat::showChat')
            if (this.model && !this.model.canAccessLivestream() && !this.model.get('finished')) {
                this.$('.MV_Chat_section').show()
                this.$('.MV_Chat_section').addClass('chat_disabled').removeClass('opened').addClass('closed')
                this.$('.toggle_chat').addClass('disabled').attr('disabled', true)
                this.$('.toggle_chat').text('Disabled')
                this.$('section:visible:not(.MV_Chat_section):first').addClass('chatClosed')
                return
            }
            if (this.model && this.model.canAccessLivestream() && this.model.get('allow_chat') && !this.model.finished() && this.model.get('started')) {
                this.chatFrame = this.$el.find('iframe').get(0)
                this.$('.MV_Chat_section').show()
                this.$('.MV_Chat_section').removeClass('chat_disabled')
                if (Immerss.currentUserId) {
                    this.$('.MV_Chat_section').addClass('opened').removeClass('closed')
                    this.$('.toggle_chat').text('Minimize')
                    this.$('.toggle_chat').addClass('active')
                    this.$('section:visible:not(.MV_Chat_section):first').removeClass('chatClosed')
                } else {
                    this.$('.MV_Chat_section').addClass('closed').removeClass('opened')
                    this.$('.toggle_chat').text('Expand')
                    this.$('.toggle_chat').removeClass('active')
                    this.$('section:visible:not(.MV_Chat_section):first').addClass('chatClosed')
                }
            } else {
                if (!this.model.finished() && this.model.get('started')) {
                    this.$('.MV_Chat_section').show().addClass('active')
                } else {
                    // this.$('.MV_Chat_section').hide().removeClass('active').removeClass('opened').addClass('closed')
                }
                if (!this.model.get('allow_chat')) {
                    this.$('.MV_Chat_section').addClass('chat_disabled')
                    this.$('.toggle_chat').addClass('disabled').attr('disabled', true)
                    this.$('.toggle_chat').text('Disabled')
                } else {
                    this.$('.toggle_chat').text('Expand')
                }
                this.$('.toggle_chat').removeClass('active')
                this.$('.MV_Chat_section').addClass('closed').removeClass('opened')
                this.$('section:visible:not(.MV_Chat_section):first').addClass('chatClosed')
            }
        },

        hideChat: function () {
            console.log('Player.Views.SessionPlayer::hideChat')
            this.$('.liveSection .MV_Chat').show()
            // this.$('.MV_Chat_section').hide().removeClass('active')
        },

        toggleChat: function (e) {
            e.preventDefault()
            if (!this.model.get('allow_chat') || !this.model.canAccessLivestream()) {
                return
            }
            if (this.$('.toggle_chat').hasClass('active')) {
                this.$('.toggle_chat').removeClass('active')
                this.$('.toggle_chat').text('expand')
                this.$('.MV_Chat_section').addClass('closed').removeClass('opened')
                this.$('section:visible:not(.MV_Chat_section):first').addClass('chatClosed')
            } else {
                this.$('.toggle_chat').addClass('active')
                this.$('.toggle_chat').text('Minimize')
                this.$('.MV_Chat_section').addClass('opened').removeClass('closed')
                this.$('section:visible:not(.MV_Chat_section):first').removeClass('chatClosed')
            }
        },
    })

    Player.Views.SessionPlayerBottom = Backbone.View.extend({

        el: '#main_container_content .mainVideoSection-sub',

        events: {
            'click .Votes-b a.vote': 'voteClick',
            'ajax:before .Votes-b a.vote': 'voteBefore',
            'ajax:success .Votes-b a.vote': 'voteSuccess',
            'ajax:error .Votes-b a.vote': 'voteError'
        },

        initialize: function (options) {
            console.log('init SessionPlayerBottom')

            if (!this.model.lists) {
                this.model.lists = new Player.Collections.Lists()
            }
            if (!this.model.polls) {
                this.model.polls = new Player.Collections.Polls()
            }
            this.listenTo(this.model.lists, 'sync', this.renderProducts)
            this.listenTo(this.model.lists, 'error', this.handleErrorProducts)
            this.listenTo(this.model.polls, 'sync', this.renderPolls)
            this.listenTo(this.model.polls, 'error', this.handleErrorPolls)
            this.listenTo(this.model, 'enable-list', this.enableList)
            this.listenTo(this.model, 'product_scanned', this.productScanned)
            this.listenTo(this.model.lists, 'disable-lists', this.disableLists)
            this.listenTo(this.model.polls, 'add-poll', this.addPoll)
            this.listenTo(this.model.polls, 'vote-poll', this.votePoll)
            this.listenTo(this.model.polls, 'enable-poll', this.enablePoll)
            this.listenTo(this.model.polls, 'disable-poll', this.disablePoll)
            this.listenTo(this.model.polls, 'updated', this.renderPolls)
            this.render()
        },

        template: function (data, hbs) {
            var template
            template = _.template(HandlebarsTemplates[hbs](data))
            return template.apply(this, arguments)
        },

        render: function () {
            var data
            data = {
                is_session: true,
                current_user_id: Immerss.currentUserId,
                description: this.checkHtmlToText(this.model.get('description')) ? this.model.get('description') : null,
                custom_description: this.checkHtmlToText(this.model.get('custom_description')) ? this.model.get('custom_description') : null
            }
            this.$el.html(this.template(data, 'sessions/player/bottom_section'))
            this.checkActiveTab()
            this.show()
        },

        show: function () {
            console.log('show products')

            this.getProducts()
            // this.getPolls()
        },

        checkHtmlToText: function (html) {
            return new DOMParser().parseFromString(html, 'text/html').body.innerText != ""
        },

        getProducts: function (force) {
            console.log('getProducts')

            if (force == null) {
                force = false
            }
            if (this.model.lists.length > 0 && !force) {
                this.renderProducts()
            } else {
                this.model.lists.url = Routes.fetch_products_products_path({
                    model_type: this.model.model_name,
                    model_id: this.model.id
                })
                this.model.lists.fetch()
            }
        },

        handleErrorProducts: function () {
            return setTimeout(((function (_this) {
                return function () {
                    return _this.getProducts(true)
                }
            })(this)), 5000)
        },

        getPolls: function (force) {
            if (force == null) {
                force = false
            }
            if (this.model.polls.length > 0 && !force) {
                this.renderPolls()
            } else {
                this.model.polls.url = Routes.fetch_polls_polls_path({
                    session_id: this.model.id
                })
                // this.model.polls.fetch()
            }
        },

        handleErrorPolls: function () {
            return setTimeout(((function (_this) {
                return function () {
                    return _this.getPolls(true)
                }
            })(this)), 5000)
        },

        renderProducts: function () {
            console.log('render products')

            var data
            if (this.model.lists.length === 0) {
                this.$('li.shop-tab, #MS_Shop').removeClass('active')
                this.$('li.shop-tab').hide()
                $('.mobileFooterNav.smallScrolls div[data-target="products"]').hide()
            } else {
                data = {
                    lists: this.model.lists.toJSON(),
                    type: this.model.model_name
                }
                this.$('#MS_Shop').html(this.template(data, 'sessions/player/shop_tab'))
                this.$('li.shop-tab').toggle(this.model.lists.isEnabled())
                $('.mobileFooterNav.smallScrolls div[data-target="products"]').toggle(this.model.lists.isEnabled())
                if (!this.model.lists.isEnabled()) {
                    this.$('li.shop-tab, #MS_Shop').removeClass('active')
                    this.$('ul li:visible:last-child a').click()
                }
                if (this.checkHtmlToText(this.model.get('description')) || this.checkHtmlToText(this.model.get('custom_description'))) {
                    this.$('.mainVideoSection-sub-header ul li.description-tab').show()
                }
            }
            this.checkActiveTab()
        },

        addPoll: function (data) {
            console.log(['add-poll', data])
            this.model.polls.add(data.poll_data)
            this.renderPolls()
        },

        renderPolls: function () {
            console.log('render polls')
            if (this.model.polls.length === 0) {
                this.$('li.polls-tab, #MS_Polls').removeClass('active')
                this.$('li.polls-tab').hide()
            } else {
                this.$('#MS_Polls').html(this.template({
                    polls: this.model.polls.toJSON(),
                    current_user_id: Immerss.currentUserId
                }, 'sessions/player/polls_tab'))
                this.$('li.polls-tab').toggle(this.model.polls.isEnabled())
                if (!this.model.polls.isEnabled()) {
                    this.$('li.polls-tab, #MS_Polls').removeClass('active')
                    this.$('ul li:visible:last-child a').click()
                }
                if (this.checkHtmlToText(this.model.get('description')) || this.checkHtmlToText(this.model.get('custom_description'))) {
                    this.$('.mainVideoSection-sub-header ul li.description-tab').show()
                }
            }
            this.checkActiveTab()
        },

        checkActiveTab: function () {
            var single_tab
            this.$el.parent().removeClass('hidden')
            if (this.model.lists.isEnabled() && this.model.polls.isEnabled()) {
                this.$('li.shop-tab, li.polls-tab').removeClass('single-tab')
            }
            single_tab = this.$('.mainVideoSection-sub-header ul li:visible').length === 1
            if (single_tab && this.$('.mainVideoSection-sub-header ul li:visible').hasClass('description-tab')) {
                $('.mainVideoSection-about').show()
                this.$('.mainVideoSection-sub-header ul li').hide()
            } else if (single_tab && !this.$('.mainVideoSection-sub-header ul li:visible').hasClass('description-tab')) {
                if (this.$('.mainVideoSection-sub-header ul li.active:visible').length === 0) {
                    this.$('.mainVideoSection-sub-header ul li:visible:first a').click()
                }
                this.$('.mainVideoSection-sub-header ul li:visible').toggleClass('single-tab', single_tab)
            } else if (!single_tab && this.$('.mainVideoSection-sub-header ul li:visible').length > 0) {
                $('.mainVideoSection-about').hide()
                if (this.$('.mainVideoSection-sub-header ul li.active:visible').length === 0) {
                    this.$('.mainVideoSection-sub-header ul li:visible:nth-child(2) a').click()
                }
                this.$('.mainVideoSection-sub-header ul li:visible').toggleClass('single-tab', false)
            }
            if (this.$('.mainVideoSection-sub-header ul li.active:visible').length === 0) {
                this.$('.mainVideoSection-sub-header ul li:visible:last-child a').click()
            }

        },

        enablePoll: function (poll_id) {
            console.log(['enable-poll', data])
            _.each(this.model.polls.models, function (item) {
                return item.set({selected: (item.id === poll_id * 1)})
            })
            this.renderPolls()
            $("[data-target='#MS_Polls']").click()
            if ($(".mobile_device").length > 0) {
                $('html, body').animate({
                    scrollTop: $("#MS_Polls").first().offset().top - $('#video_player_container').height() - 150
                }, 500)
                this.flashMessageUnderVideo('Polls')
            }
        },

        disablePoll: function (data) {
            console.log(['disable-poll', data])

            _.each(this.model.polls.models, function (item) {
                return item.set({selected: false})
            })
            this.renderPolls()
        },
        votePoll: function (data) {
            console.log(['vote-poll', data])

            var is_my_vote, is_voted, p, voted_side
            p = this.model.polls.findWhere({id: data.id * 1})
            is_my_vote = data.user_id * 1 === Immerss.currentUserId * 1
            is_voted = is_my_vote || !!$.cookie(data.id.toString())
            voted_side = is_my_vote ? data.voted_side * 1 : $.cookie(data.id.toString()) * 1
            p.set({totalVotes: data.totalVotes})

            if (is_my_vote) {
                p.set({is_voted: is_voted})
            }

            _.each(data.sides, function (side) {
                return _.each(p.attributes.sides, function (s, i) {
                    if (s.id === side.id) {
                        p.attributes.sides[i].totalVotes = side.totalVotes
                        p.attributes.sides[i].percents = side.percents
                        if (is_my_vote) {
                            return p.attributes.sides[i].is_voted = is_voted && voted_side === side.id * 1
                        }
                    }
                })
            })
            this.model.polls.trigger('updated')
        },

        voteClick: function (e) {
            if (!!$.cookie()[$(e.target).parents('.Votes-block').data('poll-id')] || $(e.target).parents('.Votes-b').hasClass('votedIn')) {
                return false
            }
        },

        voteBefore: function (e) {
            $('#containerPolls .LoadingCover').show()
            $.cookie($(e.target).parents('.Votes-block').data('poll-id'), $(e.target).parents('li').attr('id').replace('side_', ''), {
                path: '/'
            })
        },

        voteSuccess: function (e, data) {
            $('#containerPolls .LoadingCover').hide()
        },

        voteError: function (evt, data) {
            var message
            $('#containerPolls .LoadingCover').hide()
            $.removeCookie($(this).parents('.Votes-block').data('poll-id'))
            message = evt.responseJSON && (evt.responseJSON.error || evt.responseJSON.message) || 'Something went wrong'
            return message
        },

        productScanned: function (data) {
            console.log(['product_scanned', data])

            var list, product
            product = data.product
            list = this.model.lists.get(data.list.id)
            if (list) {
                list.products.add(product)
            } else {
                this.model.lists.add(data.list)
            }
            this.renderProducts()
        },

        enableList: function (data) {
            console.log(['enable-list', data])
            var enabled, list_id
            list_id = data.list_id
            if (!this.model.lists.findWhere({id: list_id * 1})) {
                return this.getProducts(true)
            }
            if (this.model.lists) {
                _.each(this.model.lists.models, function (item) {
                    return item.set({selected: false})
                })
                enabled = this.model.lists.findWhere({id: list_id * 1})
                if (enabled) {
                    enabled.set({selected: true})
                }
            }
            this.renderProducts()
            $("[data-target='#MS_Shop']").click()
        },

        disableLists: function (data) {
            console.log(['disable-lists', data])

            if (this.model.lists) {
                _.each(this.model.lists.models, function (item) {
                    return item.set({selected: false})
                })
            }
            this.renderProducts()
        },

        showProductModal: function (e) {
            var product
            e.preventDefault()
            product = this.model.lists.findProduct({
                id: $(e.currentTarget).data('id')
            })
            if (!product) {
                return
            }
            if (!$("#productGallery" + product.id).length) {
                $('body').append(product.getModalHtml())
            }
            $("#productGallery" + product.id).modal('show')
        },

        flashMessageUnderVideo: function (tabName) {
            var v, vH
            vH = $('#video_player_container').height() + -20
            v = '<div class=\'flashMessageUnderVideo\' style=\'top:' + vH + 'px\'>Presenter enable ' + tabName + '<div>'
            if ($('#video_player_container').length >= 1) {
                $('.flashMessageUnderVideo').remove()
            }
            $('.mainVideoSection').prepend(v)
            return setTimeout((function () {
                return $('.flashMessageUnderVideo').remove()
            }), 6000)
        },
    })
}()
